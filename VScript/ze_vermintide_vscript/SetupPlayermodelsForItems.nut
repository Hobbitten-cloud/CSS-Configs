// Sets the model to the targetname player
function ApplyHumanItemSkin() 
{
    foreach (key, model in HumanModels) 
    {
        local p = Entities.FindByName(null, key);
        if (p != null && p.IsValid() && p.GetTeam() == 3 && p.IsAlive()) 
        {
            p.SetModel(model);
        }
    }
}

function ApplyZombieItemSkin() 
{
    foreach (key, model in ZombieModels) 
    {
        local p = Entities.FindByName(null, key);
        if (p != null && p.IsValid() && p.GetTeam() == 2 && p.IsAlive()) 
        {
            p.SetModel(model);
        }
    }
}


// Setup item skins here
// Values on left is targetnames aka the KEY
::HumanModels <- {
    kruber_merc          = "models/player/markus_kruber.mdl"
    bardin_ranger        = "models/player/bardin.mdl"
    kerillian_waystalker = "models/player/kerillian.mdl"
    saltzpyre_whc        = "models/player/saltz1.mdl"
    sienna_bw            = "models/player/sienna.mdl"
};

/*
::ZombieModels <- {
    kruber_merc          = "models/player/markus_kruber.mdl"
    bardin_ranger        = "models/player/bardin.mdl"
    kerillian_waystalker = "models/player/kerillian.mdl"
    saltzpyre_whc        = "models/player/saltz1.mdl"
    sienna_bw            = "models/player/sienna.mdl"
};
*/

foreach (key, model in HumanModels)
{
    PrecacheModel(model);
}

/*
foreach (key, model in ZombieModels)
{
    PrecacheModel(model);
}
*/