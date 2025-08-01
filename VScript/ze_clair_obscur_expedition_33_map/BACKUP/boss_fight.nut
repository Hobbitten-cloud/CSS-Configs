// === BOSS FIGHT SCRIPT ===
// Requirements:
// - game_text: "boss_hp_display", "player_hp_display", "turn_display"
// - logic_script: "vs_boss_logic"
// - players must have "can_attack" as targetname

// === GLOBAL STATE ===
::bossHP <- 1000;
::playerHP <- {};
::turnPhase <- "PLAYER";
::currentPlayerIndex <- 0;
::playerList <- [];
::bossPhase <- 1;

//::attackTargetname <- "can_attack";
::attackers <- ["mage", "healer", "knight"]

::maxPlayerHP <- 300;
::cooldown_heal <- 10.0;
::cooldown_defend <- 5.0;

// === UTILS ===
function max(a, b) { return a > b ? a : b; }
function min(a, b) { return a < b ? a : b; }

// === INIT BOSS ===
function InitBossFight() 
{
	local player = null;
	while ((player = Entities.FindByClassname(player, "player")) != null) 
	{
		if (attackers.find(player.GetName())) 
		{
			local id = player.entindex();
			playerHP[id] <- 100;
			playerList.append(id);
		}
	}

	BroadcastMessage("=== BOSS FIGHT INITIATED ===");
	DisplayHP();
	StartPlayerTurn();
}

// === HUD DISPLAY ===
function DisplayHP() 
{
	foreach (idx in playerList) 
	{
		local p = EntIndexToHScript(idx); 

		if (!p) 
		{
			continue;
		}

		local hp = p.GetHealth();

		EntFire("boss_hp_display", "AddOutput", "message Boss HP: " + bossHP, 0.00, p);
		EntFire("boss_hp_display", "Display", "", 0.01, p);
		EntFire("player_hp_display", "AddOutput", "message Your HP: " + hp, 0.00, p);
		EntFire("player_hp_display", "Display", "", 0.02, p);
	}
	EntFire("vs_boss_logic", "RunScriptCode", "DisplayHP()", 1.0);
}

function DisplayTurnInfo() 
{
	foreach (idx in playerList) 
	{
		local p = EntIndexToHScript(idx); if (!p) continue;
		local msg = (idx == playerList[currentPlayerIndex]) ? "Your turn!" : "Waiting for your turn...";
		EntFire("turn_display", "AddOutput", "message " + msg, 0.00, p);
		EntFire("turn_display", "Display", "", 0.01, p);
	}
}

// === CHAT BROADCAST ===
function BroadcastMessage(msg) 
{
	foreach (idx in playerList) 
	{
		local p = EntIndexToHScript(idx);
		if (p) ClientPrint(p, 3, msg);
	}
}

// === PLAYER TURN ===
function StartPlayerTurn() 
{
	turnPhase = "PLAYER";
	currentPlayerIndex = 0;
	BroadcastMessage("Your turn! Use !attack, !defend, or !heal.");
	DisplayTurnInfo();
	DisplayHP();
}

// === PLAYER ACTION ===
function PlayerAction(entidx, action) 
{
	if (turnPhase != "PLAYER") 
	{
		return;
	}

	local currentID = playerList[currentPlayerIndex];
	local isTurn = (entidx == currentID);
	local now = Time();
	local p = EntIndexToHScript(entidx); if (!p) return;
	local msg = "";

	switch (action) 
	{
		case "attack":
			if (!isTurn) 
			{
				ClientPrint(p, 3, "Wait your turn to attack!");
				return;
			}

			local dmg = RandomInt(100, 500);
			bossHP -= dmg;
			msg = p.GetName() + " attacks for " + dmg + "!";
			break;

		case "defend":
			local curHP = p.GetHealth();

			if (curHP >= maxPlayerHP) 
			{
				ClientPrint(p, 3, "You're already at full HP.");
				return;
			}

			local newHP = min(curHP + 20, maxPlayerHP);
			p.SetHealth(newHP);
			playerHP[entidx] = newHP;
			msg = p.GetName() + " defends (+" + (newHP - curHP) + " HP).";
			break;

		case "heal":
			local curHP = p.GetHealth();

			if (curHP >= maxPlayerHP) 
			{
				ClientPrint(p, 3, "You're already at full HP.");
				return;
			}

			local newHP = min(curHP + 40, maxPlayerHP);
			p.SetHealth(newHP);
			playerHP[entidx] = newHP;
			msg = p.GetName() + " heals (+" + (newHP - curHP) + " HP).";
			break;

		default:
			msg = "Invalid action.";
			break;
	}

	BroadcastMessage(msg);
	DisplayHP();

	if (isTurn && action == "attack") 
	{
		currentPlayerIndex++;
		if (currentPlayerIndex >= playerList.len()) 
		{
			StartBossTurn();
		} 
		else 
		{
			DisplayTurnInfo();
		}
	}
}

// === BOSS TURN ===
function StartBossTurn() 
{
	turnPhase = "BOSS";
	BroadcastMessage("Boss is preparing to attack...");

	DoBossAction();
}

function DoBossAction() 
{
	if (bossHP <= 0) 
	{
		BroadcastMessage(">>> BOSS DEFEATED <<<");
		return;
	}

	local target = playerList[RandomInt(0, playerList.len() - 1)];
	local dmg = RandomInt(60, 120);
	local t = EntIndexToHScript(target); if (!t) return;

	local newHP = max(t.GetHealth() - dmg, 0);
	t.SetHealth(newHP);
	playerHP[target] = newHP;

	BroadcastMessage("Test1");

	if (newHP <= 0) 
	{
		BroadcastMessage("Test2");
		BroadcastMessage("Boss strikes " + t.GetName() + " for " + dmg + "! They have fallen.");
	} 
	else 
	{
		BroadcastMessage("Test3");
		BroadcastMessage("Boss strikes " + t.GetName() + " for " + dmg + "! HP left: " + newHP);
	}

	BroadcastMessage("Test4");

	DisplayHP();
	CheckBossPhase();
	StartPlayerTurn();
}

// === PHASE CHECK ===
function CheckBossPhase() 
{
	if (bossHP <= 0) 
	{
		BroadcastMessage(">>> BOSS DEFEATED <<<");
		return;
	}

	if (bossHP < 500 && bossPhase == 1) 
	{
		bossPhase = 2;
		BroadcastMessage("!! BOSS ENRAGES (PHASE 2) !!");
	}
}

// === CHAT HANDLER ===
function OnGameEvent_player_say(params) 
{
    BroadcastMessage("TEST " + params["userid"])
    local player = GetPlayerFromUserID(params["userid"]);
    
	if (!player || !player.IsValid() || !player.IsAlive()) 
	{
		return;
	}
    
	player.ValidateScriptScope();
    
    local playerInput = params["text"].tolower();
    local entidx = player.entindex();

    if (!attackers.find(player.GetName())) 
	{
        ClientPrint(player, 3, "You are not allowed to attack.");
        return;
    }

    switch (playerInput) 
	{
        case "!attack": 
			PlayerAction(entidx, "attack"); 
			break;

        case "!defend": 
			PlayerAction(entidx, "defend"); 
			break;

        case "!heal":   
			PlayerAction(entidx, "heal"); 
			break;
    }
}

__CollectGameEventCallbacks(this)