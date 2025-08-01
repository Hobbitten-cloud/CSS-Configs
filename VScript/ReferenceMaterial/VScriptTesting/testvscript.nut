function TestVscript()
{
    local test = true;
    local value = 0;
    while(test == true)
    {
        printl("hello");
        value++;
        if (value == 10)
        {
            test = false;
            printl("loop ended");
        }
    }
}

function BurnChicken()
{
    /*
        void EntFire(string target, string action, string value = null, float delay = 0, handle activator = null)
    */
    EntFire("player","AddOutPut","max_health 1000",0,null);
    EntFire("player","SetHealth","300",0,null);

    // Debug message
    printl("Health Applied once");

    local count = 10;
    local loopend = false;
    while(loopend == false)
    {
        // Debug message
        printl("Loop entered");

        EntFire("player","SetHealth","200",0,null);
        EntFire("player","SetHealth","100",0,null);
        count += 10;
        if(count == 100)
        {
            loopend = true;
            EntFire("player","SetHealth","1000",0,null);

            // Debug message
            printl("Loop ended");
        }
    }
}

function ApplyFloatingEffect()
{
    local amplitude = 200; // Strength of the force
    local frequency = 2;   // Speed of the oscillation
    local time = 0;

    // Assign targetname "floaty" to the activator
    EntFire("!activator", "AddOutput", "targetname floaty", 0, null);

    // Find the entity using targetname instead of a direct player reference
    local floatingPlayer = Entities.FindByName(null, "floaty");

    if (floatingPlayer != null)
    {
        local forceDirection = Vector(0, 0, sin(time * frequency) * amplitude);
        floatingPlayer.ApplyAbsVelocityImpulse(forceDirection);
    }
}
