   //              VSCRIPTS EDITED BY HEAVY                        \\
  //IDK HOW TO WRITE VSCRIPTS BUT 95% OF THE CODE IS REWRITED BY ME \\
 //     TY LUFFAREN FOR SOME GREAT IDEAS WHAT MAKES MY CODE FASTER   \\
//====================================================================\\

//START FADE

ScreenFade(null, 0, 0, 0, 255, 3, 3, 1);

//FALL DOWN TRIGGER FOR KILLING PLAYER

function fall(){
    if(activator.IsAlive())
        EntFireByHandle(activator, "SetHealth", "-1", 0.00, null, null);
}

//ROUND WIN/LOSE & BUILDER BALL

boulder_helper<-Entities.FindByName(null,"boulder_helper");
cocksucker<-false;
win_x<--15000.0;
function win(){
    if(cocksucker)return;
    if(boulder_helper.GetOrigin().x<win_x){
        EntFire("nuke","Enable","",0,null);
        EntFire("level_counter","Add","1",0,null);
        cocksucker=true;
        for (local player; player = Entities.FindByClassname(player, "player");){
            if(player.IsAlive() && player.GetTeam()==2){
                EntFireByHandle(player, "SetHealth", "-1", 0.00, null, null);
                EntFire("sys_particle_script","Kill","",4,null);
            }
        }
        
    }
}

lose_z<--14500.0;
function fail()
{
    if(boulder_helper.GetOrigin().z<lose_z){
        EntFireByHandle(boulder_helper, "ClearParent", "", 0, null, null);
        EntFire("boulder","Break","",0.02,null);
        EntFireByHandle(boulder_helper, "RunScriptCode", "FadeOut(1)", 0.04, null, null); //EMITATE FADEANDKILL FROM CS:GO
        for (local player; player = Entities.FindByClassname(player, "player");){
            if(player.IsAlive() && player.GetTeam()==3){
                EntFireByHandle(player, "SetHealth", "-1", 0.00, null, null);
                EntFire("sys_particle_script","Kill","",4,null);
            }
        }
    }
}

ct_count<-0.00;
ct_count_tick<-0.00;
function map_tick(){
    for (local player; player = Entities.FindByClassname(player, "player");){
        if(player.GetTeam()==3){
            ct_count_tick=ct_count_tick+1.00;
        }  
    } 
    win();
    fail();
    if(ct_count!=ct_count_tick)ct_count=ct_count_tick+0.00;
    ct_count_tick=0.00;
    EntFireByHandle(self, "CallScriptFunction", "map_tick", 1.00, null, null);
}

boulder_time<-0.00;
boulder_force<-500.00; //initial scale for thruster based on one human
boulder_thruster<-Entities.FindByName(null,"boulder_thruster");
shot_count<-0.00;
shot_inverse<-0.00;
angle_buffer<-Vector(0.00,0.00,0.00);
time_buffer<-0.1;
function boulder(){
    if(!activator.IsAlive())return;
    shot_count = shot_count + 1.00;
        local ang_buf = (boulder_helper.GetOrigin() - activator.GetOrigin());
        ang_buf.Norm();
        angle_buffer += ang_buf;
    if(boulder_time==0||boulder_time<Time()){
        boulder_time=Time()+time_buffer;
        shot_inverse = 1/shot_count;
        boulder_thruster.SetForwardVector(angle_buffer);
        boulder_thruster.KeyValueFromString("force",((boulder_force*shot_count/ct_count)).tostring());
        EntFireByHandle(boulder_thruster, "Activate", "", 0, null, null);
        shot_count=0;
        angle_buffer=Vector(0,0,0);
    }
}

//RANDOM PLAYER SFX

::sfx_neco_count<-95;
::sfx_chaos_count<-94;
function PrecacheSoundRange(prefix, count, type="") {
    for (local i = 0; i < count; i++) {
        PrecacheSound(prefix + i.tostring() + type);
    }
}
PrecacheSoundRange("sfx/neco-arc/neco-arc_", sfx_neco_count, ".wav");
PrecacheSoundRange("sfx/chaos/chaos_", sfx_chaos_count, ".wav");

::soundlevel <- (40 + (20 * log10(5000 / 36.0))).tointeger();
::sfx_play <- function(params) {
    local player = GetPlayerFromUserID(params);
    player.ValidateScriptScope();
    if(player.GetScriptScope().cooldown>Time())return;
        player.GetScriptScope().cooldown<-Time()+spam_cd;
    if (player.GetTeam() == 3){
        EmitSoundEx({sound_name="sfx/neco-arc/neco-arc_"+RandomInt(0,sfx_neco_count).tostring()+".wav",origin=player.GetOrigin(),sound_level=soundlevel,pitch=100});
    }
    if (player.GetTeam() == 2){
        EmitSoundEx({sound_name="sfx/chaos/chaos_"+RandomInt(0,sfx_chaos_count).tostring()+".wav",origin=player.GetOrigin(),sound_level=soundlevel,pitch=100});
    }
}

//SFX EVENT HADLER

::neco_words<-[
    {command_name="neco",           sound="sfx/neco-arc/neco-arc_82.wav"},
    {command_name="nyaa",           sound="sfx/neco-arc/neco-arc_4.wav"},  
    {command_name="doridoridori",   sound="sfx/neco-arc/neco-arc_53.wav"},
    {command_name="burenyuu",       sound="sfx/neco-arc/neco-arc_1.wav"}
];
::neco_arc<-"models/player/nekoarc_test1.mdl";
::neco_chaos<-"models/player/nekoarc_test1_chaos.mdl";
::spam_cd<-1.50;
if ("MyEvenets" in this)
	MyEvenets.clear();
::MyEvenets <- {
//JUST ADD SFX COOLDOWN
    OnGameEvent_player_spawn = function(params)
    {
        local player = GetPlayerFromUserID(params.userid);
        player.ValidateScriptScope();
        player.GetScriptScope().cooldown<-0.00;
    }
//SFX SOUND EVENTS
    OnGameEvent_weapon_reload = function(params)
    {
        ::sfx_play(params.userid);
    }
    OnGameEvent_player_death = function(params)
    {
        ::sfx_play(params.userid);
    }
    OnGameEvent_weapon_zoom = function(params)
    {
        ::sfx_play(params.userid);
    }
    OnGameEvent_player_say = function(params)
    {
        local player = GetPlayerFromUserID(params.userid);
        player.ValidateScriptScope();
        local txt = params.text;
        if(player.GetTeam() == 3){
            if(txt==neco_words[0].command_name){
                EmitSoundEx({sound_name=neco_words[0].sound,origin=player.GetOrigin(),sound_level=soundlevel,pitch=100});
            }
            else if(txt==neco_words[1].command_name){
                EmitSoundEx({sound_name=neco_words[1].sound,origin=player.GetOrigin(),sound_level=soundlevel,pitch=100});
            }
            else if(txt==neco_words[2].command_name){
                EmitSoundEx({sound_name=neco_words[2].sound,origin=player.GetOrigin(),sound_level=soundlevel,pitch=100});
            }
            else if(txt==neco_words[3].command_name){
                EmitSoundEx({sound_name=neco_words[3].sound,origin=player.GetOrigin(),sound_level=soundlevel,pitch=100});
            }
        }
    }
}
__CollectGameEventCallbacks(MyEvenets)

//FORCE PLAYER MODEL

function player_model_tick(){
    for (local player; player = Entities.FindByClassname(player,"player");){
        if(player.IsAlive()&&player.GetTeam()==3&&player.GetModelName()!=neco_arc){
            player.PrecacheModel(neco_arc);
            player.SetModel(neco_arc);
        }
        if(player.IsAlive()&&player.GetTeam()==2&&player.GetModelName()!=neco_chaos){
            player.PrecacheModel(neco_chaos);
            player.SetModel(neco_chaos);
        }   
    }
    EntFireByHandle(self, "CallScriptFunction", "player_model_tick", 2.00, null, null);
}
player_model_tick();

//CHANGE RAIN DENSITY

rain<-0;
rain_max<-50; //CS:GO VSCRIPT VALUE 500
function rain_tick(){
    if(rain_max<rain)return;
    rain++;
    EntFire("rain","AddOutput","renderamt " + rain.tostring(),0,null);
    EntFireByHandle(self, "CallScriptFunction", "rain_tick", 2.00, null, null);
}

//RANDOM SKYBOX

function random_sky(){
    local skyboxes = ["sky_csgo_night02","deadcore_sky_9"];
    SetSkyboxTexture(skyboxes[RandomInt(0,skyboxes.len()-1)].tostring());
}

//MAP MUSIC

music_count<-24;
music_ringer_count<-5;
PrecacheSoundRange("#music/music_", music_count, ".mp3");
PrecacheSoundRange("#music/ringer_", music_ringer_count, ".mp3");

sisyphus_tunes <-[
    {name="American Football - Never Meant",                                        path="#music/music_0.mp3",   time=257    },
    {name="Beck - Loser",                                                           path="#music/music_1.mp3",   time=235    },
    {name="Billy Idol - Rebel Yell",                                                path="#music/music_2.mp3",   time=288    },
    {name="Boa - Duvet",                                                            path="#music/music_3.mp3",   time=203    },
    {name="Cortex - Devil's Dance",                                                 path="#music/music_4.mp3",   time=148    },
    {name="Hideki Taniuchi - Death Note",                                           path="#music/music_5.mp3",   time=190    },
    {name="Melty Blood OST - Neco Arc",                                             path="#music/music_6.mp3",   time=137    },
    {name="Eiffel 65 - Blue",                                                       path="#music/music_7.mp3",   time=282    },
    {name="Duster - Me And The Birds",                                              path="#music/music_8.mp3",   time=95     },
    {name="Radiohead - Knives Out",                                                 path="#music/music_9.mp3",   time=254    },
    {name="Outkast - Hey Ya!",                                                      path="#music/music_10.mp3",  time=221    },
    {name="Eyeliner - Payphone",                                                    path="#music/music_11.mp3",  time=321    },
    {name="Gorillaz - Melancholy Hill",                                             path="#music/music_12.mp3",  time=226    },
    {name="Loverboy - Workin' For The Weekend",                                     path="#music/music_13.mp3",  time=218    },
    {name="Penpals - Tell Me Why",                                                  path="#music/music_14.mp3",  time=72     },
    {name="Nujabes - Shiki no Uta",                                                 path="#music/music_15.mp3",  time=300    },
    {name="Silver Fins - Waiting So Long",                                          path="#music/music_16.mp3",  time=79     },
    {name="Susumu Hirasawa - Gats",                                                 path="#music/music_17.mp3",  time=214    },
    {name="Modest Mouse - Sunspots In The House Of The Late Scapegoat",             path="#music/music_18.mp3",  time=156    },
    {name="The Drums - Money",                                                      path="#music/music_19.mp3",  time=233    },
    {name="Tears for Fears - Everybody Wants To Rule The World",                    path="#music/music_20.mp3",  time=250    },
    {name="Iron Maiden - The Trooper",                                              path="#music/music_21.mp3",  time=250    },
    {name="Men at Work - Down Under",                                               path="#music/music_22.mp3",  time=209    },
    {name="The Pixies - Where Is My Mind?",                                         path="#music/music_23.mp3",  time=233    },
    {name="a-ha - Take on Me",                                                      path="#music/music_24.mp3",  time=225    }
]

ringers <- [
    {path="#music/ringer_0.mp3", time=50},
    {path="#music/ringer_1.mp3", time=38},
    {path="#music/ringer_2.mp3", time=32},
    {path="#music/ringer_3.mp3", time=26},
    {path="#music/ringer_4.mp3", time=67}
]

function sisyphus_playlist(){ //THE ROUND IS NOT ENOUGH LONG TO HAVE TO RECICLY THE MUSIC TABLE THAT'S WHY THERE'S NO FUNCTION FOR THAT
    function play_random_music(){
        EntFire("random_ringer_sound","Kill","",0,null);
        local random_song = RandomInt(0, sisyphus_tunes.len()-1);
        local selected_song = sisyphus_tunes[random_song];
        ClientPrint(null, 3, "\x07FF0000>>> \x074B69FFNOW PLAYING: \x07CCCCCC" + selected_song.name + "\x07FF0000 <<<");
        SpawnEntityGroupFromTable({a = {ambient_generic = {message = selected_song.path.tostring(),pitch=100,health=10,spawnflags=49,targetname="random_playlist_sound"}}});
        EntFire("random_playlist_sound","PlaySound","",0,null);
        EntFireByHandle(self,"CallScriptFunction","play_random_ringer",selected_song.time,null,null);
    }
    function play_random_ringer(){
        EntFire("random_playlist_sound","Kill","",0,null);
        local random_ringer = RandomInt(0, ringers.len()-1);
        local selected_ringer = ringers[random_ringer];
        ClientPrint(null, 3, "\x07FF0000>>> \x074B69FFYOU ARE LISTENING TO \x07CCCCCC|| GFL 66.6 FM ||\x07D32CE6 BROUGHT TO YOUR BY GHOSTFAP.COM\x07FF0000 <<<");
        SpawnEntityGroupFromTable({a = {ambient_generic = {message = selected_ringer.path.tostring(),pitch=100,health=10,spawnflags=49,targetname="random_ringer_sound"}}});
        EntFire("random_ringer_sound","PlaySound","",0,null);
        EntFireByHandle(self,"CallScriptFunction","play_random_music",selected_ringer.time,null,null);
    }
    local chance = RandomInt(0, 10); //RANDOM SINCE IDK WHAT'S THE CHANCHE BETWEEN RINGER AND MUSIC ON CS:GO (50%? I don't wanna hear longus that much)
    if (chance < 8) {
        play_random_music();
    } else {
        play_random_ringer();
    }
}

//ZOMBIE TELEPORT

::zm_dest<-null;
::spawn_x<-13184;
function zm_tp(){
    if(!activator.IsAlive())return;
    zm_dest=null;
    for (local player; player = Entities.FindByClassname(player,"player");){
        if(player.GetTeam()==2){
            if(player.GetOrigin().x<spawn_x){
                if(TraceLinePlayersIncluded(player.GetOrigin(),player.GetOrigin()+Vector(0,0,-32),null)==0)continue;
                if(zm_dest==null)zm_dest=player.GetOrigin();
                if(zm_dest.x<spawn_x && player.GetOrigin().x<zm_dest.x&&player.GetOrigin().z>zm_dest.z){
                    zm_dest=player.GetOrigin();
                }
            }
        }
    }
    if(zm_dest==null)return;
    activator.SetOrigin(Vector(zm_dest.x,zm_dest.y,zm_dest.z+64));
}

//SQUID INGAME EVENT 

PrecacheSound("sfx/heat_death.mp3");
PrecacheSound("sfx/pizza_aggressive.mp3");

function red_mist_squid(){
    squid <- Entities.FindByName(null,"red_mist_squid_move");
    function red_mist_squid_sound_player(){
        SpawnEntityGroupFromTable({
            a = {ambient_generic = {message = "sfx/heat_death.mp3",origin=squid.GetOrigin()+Vector(0,0,-15000),radius=10000,pitch=50,health=10,targetname="squid_sound_agust"}},
            b = {ambient_generic = {message = "sfx/heat_death.mp3",origin=squid.GetOrigin()+Vector(-1000,0,-14000),radius=10000,pitch=40,health=8,targetname="squid_sound_agust"}},
            c = {ambient_generic = {message = "sfx/heat_death.mp3",origin=squid.GetOrigin()+Vector(-1000,0,-13000),radius=10000,pitch=30,health=7,targetname="squid_sound_agust"}},
            d = {ambient_generic = {message = "sfx/heat_death.mp3",origin=squid.GetOrigin()+Vector(-1000,0,-12000),radius=10000,pitch=20,health=6,targetname="squid_sound_agust"}},
            e = {ambient_generic = {message = "sfx/heat_death.mp3",origin=squid.GetOrigin()+Vector(-1000,0,-11000),radius=10000,pitch=40,health=8,targetname="squid_sound_agust"}},
            f = {ambient_generic = {message = "sfx/heat_death.mp3",origin=squid.GetOrigin()+Vector(-1000,0,-10000),radius=10000,pitch=30,health=7,targetname="squid_sound_agust"}},
            g = {ambient_generic = {message = "sfx/heat_death.mp3",origin=squid.GetOrigin()+Vector(-1000,0,-9000),radius=10000,pitch=20,health=6,targetname="squid_sound_agust"}}
        });
        EntFire("squid_sound_agust","PlaySound","",0,null);
        EntFire("squid_sound_agust","Kill","",13.98,null);
        EntFireByHandle(self,"CallScriptFunction","red_mist_squid_sound_player",14,null,null);
    }
    EntFireByHandle(squid,"Open","",0,null,null);
    EntFireByHandle(squid,"SetSpeed","249",0.1,null,null);
    red_mist_squid_sound_player();
}

function red_mist_kill(){
    if(!activator.IsAlive())return;
    local soundlevel2 = (40 + (20 * log10(10000 / 36.0))).tointeger();
    EmitSoundEx({sound_name="sfx/pizza_aggressive.mp3",origin=activator.GetOrigin()+Vector(0,0,15),sound_level=soundlevel2,pitch=RandomInt(70,130)});
    SpawnEntityGroupFromTable({a = {info_particle_system = {origin = activator.GetOrigin()+Vector(0,0,35),angles = Vector(90+RandomInt(-15,15),RandomInt(0,360),RandomInt(-15,15)),targetname="sys_particle_script",effect_name = "sisyphus_particle_003",start_active = true}}});
    EntFireByHandle(activator, "SetHealth", "-1", 0, null, null);
}

red_mist_chance<-31;
function red_mist_squid_rng(){
    if(RandomInt(0,red_mist_chance)==red_mist_chance)EntFire("temp_red_mist_squid", "ForceSpawn", "", 30, null);
    else{
        printl("lucky you! you shall not die today, however odds are currently: " + red_mist_chance.tostring());
    }
}