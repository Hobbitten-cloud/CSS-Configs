// Define global variables
local player = null;
local prop = null;
local checkInterval = 0.1; // Check every 0.1 seconds
::FL_ONGROUND <- 1; // Constant for ground check
local anim = null;

// Function to check if player is on the ground
function OnGround()
{
    if ((player.GetFlags() & FL_ONGROUND) == 0)
    {
        return true;
    }
    return false;
}

function CheckAirStatus()
{
    player = activator;
    prop = self;
    anim = "init";
    Tick();
}

function Tick()
{
    if (player == null || prop == null)
    {
        return;
    }

    if (OnGround()) // If the player is in the air
    {
        if (anim != "jump")
        {
            EntFireByHandle(prop, "SetAnimation", "Jump", 0, null, null); // Change to your desired jump animation
        }
        anim = "jump";
    }
    else
    {
        if (anim != "run")
        {
            EntFireByHandle(prop, "SetAnimation", "run", 0, null, null); // Change to your desired jump animation
        }
        anim = "run";
    }

    EntFireByHandle(self, "RunScriptCode", "Tick()", checkInterval, null, null);
}