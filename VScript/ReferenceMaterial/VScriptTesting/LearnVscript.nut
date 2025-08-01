/*
    In this Vscript there is a bunch of functions that attempts to learn basics of Vscripts.
    Global values can be used in every function listed below as they exist in the Vscript file.
*/

// Global variable 
local player = null;
local disaster = 1; // Makes sure the mapsettings only is loaded once per round

// Loads settings for the server
function MapSettings()
{
    if (disaster == 1)
    {
        // void DoEntFire(string target, string action, string value, float delay, handle activator, handle caller)
        DoEntFire("console", "Command", "say \"*** Map by: Hobbitten ***\"", 5, null, null);
        DoEntFire("console", "Command", "mp_accelerate 12", 0, null, null);
        DoEntFire("console", "Command", "mp_airaccelerate 150", 0, null, null);
        DoEntFire("console", "Command", "zr_infect_spawntime_min 15", 0, null, null);
        DoEntFire("console", "Command", "zr_infect_spawntime_max 15", 0, null, null);
        DoEntFire("console", "Command", "mp_roundtime 30", 0, null, null);
        DoEntFire("console", "Command", "say \"*** Vscript settings loaded ***\"", 6, null, null);

        disaster++ // Genius trust me
        printl("Map Settings loaded");
    }
}

// Allows this specific code line be used later in a map
function MapCreatorAnnounce()
{
    DoEntFire("console", "Command", "say \"*** Map by: Hobbitten ***\"", 0, null, null);
}

// Assign targetname when a player touches trigger_once
function OnStartTouchDamaged(trigger, activator)
{
    if (activator.IsPlayer())
    {
        activator.KeyValueFromString("targetname", "player_damaged");
        printl("Damage targetname given");
    }
}

// Damage players with targetname every second
function ApplyDamage()
{
    while ((player = Entities.FindByName(player, "player_damaged")) != null && player.IsAlive())
    {
        /*
	        void TakeDamage(float flDamage, Constants.FDmgType nDamageType, handle hAttacker)
        */
        player.TakeDamage(10, 16384, self);
        printl("test damage trigger")
    }
    EntFireByHandle(self, "RunScriptCode", "ApplyDamage()", 1.0, null, null);
}

// Assign targetname when a player touches trigger_once
function OnStartTouchHealing(trigger, activator)
{
    if (activator.IsPlayer())
    {
        activator.KeyValueFromString("targetname", "player_healed");
        printl("Healing targetname given");
    }
}

// Heals players
function Healing()
{
    local loopEnd = false;

    while ((player = Entities.FindByName(player, "player_healed")) != null && player.IsAlive() && loopEnd == false)
    {
        local health = player.GetHealth()
        if (health < player.GetMaxHealth())
        {
            player.SetHealth(10 + health)
        }

        if (health == player.GetMaxHealth)
        {
            loopEnd = true;
        }
    }
    EntFireByHandle(self, "RunScriptCode", "Healing()", 1.0, null, null);
}






// Resets the players targetname on roundstart
while ((player = Entities.FindByClassname(player, "player")) != null)
{
    player.KeyValueFromString("targetname", "default");
    printl("targetname cleared");
}

// Initiliaze healing script timer
EntFireByHandle(self, "RunScriptCode", "Healing()", 1.0, null, null);

// Initiliaze Apply damage script timer
EntFireByHandle(self, "RunScriptCode", "ApplyDamage()", 1.0, null, null);