if(!("STAGE" in getroottable())) // turn variable that stores level to permanent
{
    ::STAGE <- 1
}

switch( STAGE )
{
    case 1: // it's like OnCaseXX
    {
        EntFire("door_1", "Disable", "", 0 null) // call input on entity
        ClientPrint(null, 3, "Level 1") // print message to chat
        break
    }

    case 2:
    {
        EntFire("door_2", "Disable", "", 0 null)
        ClientPrint(null, 3, "Level 2")
        break
    }

    case 3:
    {
        EntFire("door_3", "Disable", "", 0 null)
        ClientPrint(null, 3, "Level 3")
        break
    }
}

// call this with CallScriptFunction input in hammer when humans win
function RoundWin()
{
    STAGE++
    if(STAGE > 3) STAGE = 1
}