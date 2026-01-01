// Global values
::TEAM_ZOMBIE <- 2;

// Is a script function on each trigger
function OnZombieTriggerTouch()
{
    if (activator == null) return;

    // Only react to player zombies
    if (activator.IsPlayer() && activator.GetTeam() == TEAM_ZOMBIE)
    {
        printl("[ZS] Zombie touched: " + trigger.GetName() + " -> Killing all humans.");
        KillAllHumans();
    }
}

// Kills all players that are NOT on the zombie team
function KillAllHumans()
{
    local p = null;
    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (!p.IsPlayer()) continue;
        
        if (p.GetTeam() == 3)
        {
            EntFireByHandle(p, "SetHealth", "0", 0, null, null);
        }
    }
}
