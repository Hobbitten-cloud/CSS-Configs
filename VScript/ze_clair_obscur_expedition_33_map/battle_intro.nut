// === CONFIGURATION ===
local introDelay = 2.0;
local orbitRadius = 1600.0;
local height = 100.0;
local totalDuration = 14.0;
local frameInterval = 0.01;
local zoomEnd = 1.0;
local pitchBias = 25.0;
local verticalOscillation = 100.0;
local startSpeedBoost = 0.15;
local spinDegrees = 1000.0;
local spinClockwise = true;

// === INTERNAL STATE ===
::introStarted <- false;
::center <- null;
::camera <- null;
::fadeOutStarted <- false;
::startTime <- 0.0;

printl("[IntroCam] Script loaded.");

// === UTILS ===
function EaseInOut(t) {
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
}

function clamp(val, min, max) {
    return val < min ? min : val > max ? max : val;
}

// === ENTRY POINT (called by logic_script) ===
function StartBattleIntro() {
    if (::introStarted) return;
    ::introStarted = true;

    printl("[IntroCam] Starting battle intro...");

    ::center = Entities.FindByName(null, "intro_camera_anchor");
    if (center == null) {
        printl("[IntroCam] ERROR: No 'intro_camera_anchor' found!");
        return;
    }

    // Create the shared camera
    ::camera = Entities.CreateByClassname("point_viewcontrol");
    ::camera.__KeyValueFromString("targetname", "battle_intro_camera");
    ::camera.__KeyValueFromString("wait", "-1");
    ::camera.__KeyValueFromString("moveto", "0");

    // Lock all players and attach camera
    local p = null;
    while ((p = Entities.FindByClassname(p, "player")) != null) 
    {
        EntFireByHandle(p, "AddOutput", "movetype 0", 0.0, null, null);
        EntFireByHandle(p, "AddOutput", "solid 0", 0.0, null, null);
        EntFireByHandle(p, "DisableMotion", "", 0.0, null, null);
        DoEntFire("battle_intro_camera", "Enable", "", 0.0, p, p);
    }

    // Fade + music
    EntFire("fade_black", "Fade", "", 0.1);
    EntFire("intro_music", "PlaySound", "", introDelay);

    // Start timer
    ::startTime = Time() + introDelay;
    DoEntFire("vs_intro_logic", "RunScriptCode", "ThinkBattleIntro()", introDelay, null, null);
}

// === CAMERA LOGIC ===
function ThinkBattleIntro() {
    local now = Time();
    local elapsed = now - ::startTime;

    if (!::fadeOutStarted && elapsed >= totalDuration - 2.0) {
        EntFire("fade_clear", "Fade", "", 0.0);
        ::fadeOutStarted = true;
        printl("[IntroCam] Fade-out started.");
    }

    if (elapsed >= totalDuration) {
        local p = null;
        while ((p = Entities.FindByClassname(p, "player")) != null) 
        {
            EntFireByHandle(p, "AddOutput", "movetype 2", 0.0, null, null);
            EntFireByHandle(p, "AddOutput", "solid 2", 0.0, null, null);
        }

        DoEntFire("battle_intro_camera", "Disable", "", 0.0, null, null);
        DoEntFire("battle_intro_camera", "Kill", "", 0.1, null, null);
        ::camera = null;

        printl("[IntroCam] Camera sequence complete.");
        EntFire("boss_start", "Trigger", "", 0.0);
        return;
    }

    // Eased movement
    local t = elapsed / totalDuration;
    local adjustedT = clamp(t + (1 - t) * startSpeedBoost, 0, 1);
    local easedT = EaseInOut(adjustedT);
    local angle = (spinClockwise ? 1 : -1) * easedT * spinDegrees;
    local radians = angle * PI / 180.0;
    local curRadius = orbitRadius * (1 - easedT * (1 - zoomEnd));

    // Position + look
    local centerPos = center.GetOrigin();
    local camX = centerPos.x + curRadius * cos(radians);
    local camY = centerPos.y + curRadius * sin(radians);
    local camZ = centerPos.z + height + verticalOscillation * sin(easedT * PI);
    ::camera.SetOrigin(Vector(camX, camY, camZ));

    local dir = centerPos - Vector(camX, camY, camZ);
    local yaw = atan2(dir.y, dir.x) * 180.0 / PI;
    local pitch = -atan2(dir.z, sqrt(dir.x * dir.x + dir.y * dir.y)) * 180.0 / PI;
    yaw = (yaw + 360) % 360;
    pitch = clamp(pitch + pitchBias, -89, 89);
    ::camera.__KeyValueFromString("angles", pitch + " " + yaw + " 0");

    // Schedule next frame
    DoEntFire("vs_intro_logic", "RunScriptCode", "ThinkBattleIntro()", frameInterval, null, null);
}

// === SAFETY: call on round start to ensure stuck cameras are cleared ===
function ResetIntroCamera() {
    printl("[IntroCam] Resetting camera...");

    local cam = null;
    while ((cam = Entities.FindByClassname(cam, "point_viewcontrol")) != null) {
        DoEntFire("!self", "Disable", "", 0.0, null, cam);
        DoEntFire("!self", "Kill", "", 0.1, null, cam);
    }

    ::introStarted = false;
    ::camera = null;
}