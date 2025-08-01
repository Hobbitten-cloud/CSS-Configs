if ("__boss_script_loaded" in getroottable()) {
    printl("BOSS SCRIPT: Already loaded — skipping registration.");
    return;
}
getroottable()["__boss_script_loaded"] <- true;
printl("BOSS SCRIPT: Loaded and initializing...");

// === CONFIG ===
::bossHP <- 1000;
::maxPlayerHP <- 300;
::turnPhase <- "PLAYER";
::playerHP <- {};
::roleOrder <- ["mage", "healer", "knight"];
::rolePlayers <- {}; // role -> entindex
::currentRoleIndex <- 0;
::bossPhase <- 1;
::bossDefeated <- false;
::reminderActive <- false;
::turnActionTaken <- false;
::turnReady <- false;

// === UTILS ===
function max(a, b) { return a > b ? a : b; }
function min(a, b) { return a < b ? a : b; }

// === INIT ===
function InitBossFight(hp) {
    bossHP = hp.tointeger();
    bossDefeated = false;
    reminderActive = false;
    turnPhase = "PLAYER";
    currentRoleIndex = -1;
    bossPhase = 1;

    playerHP.clear();
    rolePlayers.clear();

    local foundRoles = 0;
    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null) {
        local name = player.GetName();
        local id = player.entindex();
        playerHP[id] <- 100;

        if (roleOrder.find(name) != null) {
            rolePlayers[name] <- id;
            foundRoles++;
        }
    }

    EntFire("turn_display", "Enable");
    EntFire("player_hp_display", "Enable");
    EntFire("boss_hp_display", "Enable");
    EntFire("display_hp_timer", "Enable");

    BroadcastMessage("=== BOSS FIGHT INITIATED === (HP: " + bossHP + ")");

    DisplayHP();
    if (foundRoles == 0) {
        BroadcastMessage("No roles found! All players will be eliminated.");
        KillAllPlayers();
        return;
    }

    StartPlayerTurn();
}

function KillAllPlayers() {
    local p = null;
    while ((p = Entities.FindByClassname(p, "player")) != null) {
        if (p.IsAlive()) {
            p.TakeDamage(9999, 0, null);
        }
    }

    EntFire("boss_hp_display", "Disable");
    EntFire("player_hp_display", "Disable");
    EntFire("turn_display", "Disable");
    EntFire("display_hp_timer", "Disable");
}

// === DISPLAY ===
function DisplayHP() {
    if (bossDefeated) return;

    // Display Boss HP to everyone
    local p = null;
    while ((p = Entities.FindByClassname(p, "player")) != null) {
        EntFire("boss_hp_display", "AddOutput", "message Boss HP: " + bossHP, 0.00, p);
        EntFire("boss_hp_display", "Display", "", 0.01, p);
    }

    // Display individual HP only to players with roles
    foreach (role in roleOrder) {
        if (!(role in rolePlayers)) continue;
        local p = EntIndexToHScript(rolePlayers[role]);
        if (!p) continue;

        local hp = p.GetHealth();
        EntFire("player_hp_display", "AddOutput", "message Your HP: " + hp, 0.00, p);
        EntFire("player_hp_display", "Display", "", 0.02, p);
    }
}

function DisplayTurnInfo() {
    foreach (role in roleOrder) {
        if (!(role in rolePlayers)) continue;
        local p = EntIndexToHScript(rolePlayers[role]);
        if (!p) continue;

        local msg = (roleOrder[currentRoleIndex] == role) ? "Your turn!" : "Waiting...";
        EntFire("turn_display", "AddOutput", "message " + msg, 0.00, p);
        EntFire("turn_display", "Display", "", 0.01, p);
    }
}

// === MESSAGING ===
function BroadcastMessage(msg) {
    local p = null;
    while ((p = Entities.FindByClassname(p, "player")) != null) {
        ClientPrint(p, 3, msg);
    }
}

function RemindCurrentTurn() {
    if (turnPhase != "PLAYER" || !reminderActive || bossDefeated) return;

    local role = roleOrder[currentRoleIndex];
    if (!(role in rolePlayers)) return;

    local p = EntIndexToHScript(rolePlayers[role]);
    if (!p) return;

    ClientPrint(p, 3, "It is your turn! Use !attack, !defend, or !heal.");
    EntFire("vs_boss_logic", "RunScriptCode", "RemindCurrentTurn()", 15);
}

// === PLAYER TURN ===
function StartPlayerTurn() {
    turnPhase = "PLAYER";
    turnActionTaken = false;
    turnReady = false;

    // Find the first valid player with a role
    for (local i = 0; i < roleOrder.len(); i++) 
    {
        if (roleOrder[i] in rolePlayers) 
        {
            currentRoleIndex = i;
            reminderActive = true;
            BroadcastMessage("Your turn begins!");
            DisplayTurnInfo();
            DisplayHP();
            RemindCurrentTurn();
            EntFire("vs_boss_logic", "RunScriptCode", "turnReady = true;", 1.0);
            return;
        }
    }

    // No players with valid roles
    KillAllPlayers();
}

function AdvanceTurn() {
    reminderActive = false;

    while (true) {
        currentRoleIndex++;
        if (currentRoleIndex >= roleOrder.len()) {
            StartBossTurn();
            return;
        }

        local role = roleOrder[currentRoleIndex];
        if (role in rolePlayers) {
            DisplayTurnInfo();
            reminderActive = true;
            RemindCurrentTurn();
            EntFire("vs_boss_logic", "RunScriptCode", "turnReady = true;", 1.0);
            return;
        }
    }
}

// === PLAYER ACTION ===
function PlayerAction(entidx, action) {
    if (turnPhase != "PLAYER" || bossDefeated || turnActionTaken || !turnReady) return;

    local role = roleOrder[currentRoleIndex];
    if (!(role in rolePlayers) || rolePlayers[role] != entidx) {
        ClientPrint(EntIndexToHScript(entidx), 3, "It's not your turn.");
        return;
    }

    local p = EntIndexToHScript(entidx);
    if (!p) return;

    local msg = "";
    local success = false;

    switch (action) {
        case "attack":
            local dmg = RandomInt(100, 500);
            bossHP -= dmg;
            msg = p.GetName() + " attacks for " + dmg + "!";
            success = true;
            break;

        case "defend":
            local curHP = p.GetHealth();
            if (curHP >= maxPlayerHP) {
                ClientPrint(p, 3, "You're already at full HP.");
                return;
            }
            local newHP = min(curHP + 20, maxPlayerHP);
            p.SetHealth(newHP);
            playerHP[entidx] = newHP;
            msg = p.GetName() + " defends (+" + (newHP - curHP) + " HP).";
            success = true;
            break;

        case "heal":
            local curHP2 = p.GetHealth();
            if (curHP2 >= maxPlayerHP) {
                ClientPrint(p, 3, "You're already at full HP.");
                return;
            }
            local newHP2 = min(curHP2 + 40, maxPlayerHP);
            p.SetHealth(newHP2);
            playerHP[entidx] = newHP2;
            msg = p.GetName() + " heals (+" + (newHP2 - curHP2) + " HP).";
            success = true;
            break;

        default:
            ClientPrint(p, 3, "Invalid action.");
            return;
    }

    if (success) {
        turnActionTaken = true;
        BroadcastMessage(msg);
        DisplayHP();
        AdvanceTurn();
    }
}

// === BOSS TURN ===
function StartBossTurn() {
    turnPhase = "BOSS";
    BroadcastMessage("Boss is preparing to attack...");
    DoBossAction();
}

function DoBossAction() {
    if (bossHP <= 0) {
        BroadcastMessage(">>> BOSS DEFEATED <<<");
        return;
    }

    local targets = [];
    foreach (role in roleOrder) {
        if (role in rolePlayers) targets.append(rolePlayers[role]);
    }

    local target = targets[RandomInt(0, targets.len() - 1)];
    local t = EntIndexToHScript(target); if (!t) return;

    local dmg = RandomInt(60, 120);
    local newHP = max(t.GetHealth() - dmg, 0);
    t.SetHealth(newHP);
    playerHP[target] = newHP;

    if (newHP <= 0) {
        BroadcastMessage("Boss strikes " + t.GetName() + " for " + dmg + "! They have fallen.");
    } else {
        BroadcastMessage("Boss strikes " + t.GetName() + " for " + dmg + "! HP left: " + newHP);
    }

    DisplayHP();
    CheckBossPhase();
    StartPlayerTurn();
}

// === PHASE CHECK ===
function CheckBossPhase() {
    if (bossHP <= 0) {
        bossDefeated = true;
        reminderActive = false;
        BroadcastMessage(">>> BOSS DEFEATED <<<");

        EntFire("boss_hp_display", "Disable");
        EntFire("player_hp_display", "Disable");
        EntFire("turn_display", "Disable");
        EntFire("display_hp_timer", "Disable");
        return;
    }

    if (bossHP < 500 && bossPhase == 1) {
        bossPhase = 2;
        BroadcastMessage("!! BOSS ENRAGES (PHASE 2) !!");
    }
}

// === CHAT COMMANDS ===
function OnGameEvent_player_say(params) {
    if (bossDefeated || turnPhase != "PLAYER") return;

    local player = GetPlayerFromUserID(params["userid"]);
    if (!player || !player.IsValid() || !player.IsAlive()) return;

    local entidx = player.entindex();
    local txt = params["text"].tolower();

    if (txt == "!attack") PlayerAction(entidx, "attack");
    else if (txt == "!defend") PlayerAction(entidx, "defend");
    else if (txt == "!heal") PlayerAction(entidx, "heal");
}

__CollectGameEventCallbacks(this);