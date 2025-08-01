// ================================
// Bracken System for Hobbiten :D
// - Handles Bracken player behavior
// - Prevents damage from Brackens
// - Traps Bracken in room after killing a human
// ================================

// Max number of players (set once at script load)
::MaxPlayers <- MaxClients().tointeger()

// ----------------------------------------
// Utility: Collects and binds game event callbacks
// ----------------------------------------
function CollectEventsInScope(events) {
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	local Instance = self
	foreach (name, callback in events) {
		local callback_binded = callback.bindenv(this)
		events_table[name] = @(params) Instance.IsValid() ? callback_binded(params) : delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events_table)
}

// ----------------------------------------
// Global Bracken-related event logic
// - Handles spawn, death, and damage prevention
// ----------------------------------------
CollectEventsInScope({

	// When a player spawns, reset Bracken and trap flags
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if (!player || !player.IsValid()) return;

		player.ValidateScriptScope()
		player.GetScriptScope().is_brecken <- null
		player.GetScriptScope().is_trapped <- false
		player.KeyValueFromString("targetname", "player_none")

		// Fire player_activate if on survivor team
		if (!IsPlayerABot(player) && player.GetTeam() == 0) {
			SendGlobalGameEvent("player_activate", {userid = params.userid})
		}
	},

	// When a player dies, clear Bracken status and trap
	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if (!player || !player.IsValid()) return;

		player.ValidateScriptScope()
		player.GetScriptScope().is_brecken <- null
		player.GetScriptScope().is_trapped <- false
		player.KeyValueFromString("targetname", "player_none")
	},

	// Prevent Bracken from dealing damage
	OnScriptHook_OnTakeDamage = function(params) {
		if (params.attacker && params.attacker.IsValid()) {
			local scope = params.attacker.GetScriptScope()
			if ("is_brecken" in scope && scope.is_brecken) {
				params.damage = 0
				params.attacker = null
			}
		}
	}
})

// ----------------------------------------
// Bracken Trap Logic
// - Called manually when a Bracken kills a human
// - Traps them in a defined room for 60 seconds
// ----------------------------------------
function StartBrackenTrapTimer(player)
{
	// === Room configuration ===
	local room_min = Vector(2432, 9600, -6560);     // bottom corner
	local room_max = Vector(3072, 10240, -6496);    // top corner
	local return_pos = Vector(2752, 9920, -6520);   // teleport-to location (center of room)

	local check_interval = 1.0;      // how often to check position (in seconds)
	local trap_duration = 60.0;      // how long they are trapped

	// Set trapped flag in player scope
	player.ValidateScriptScope()
	local scope = player.GetScriptScope()
	scope.is_trapped <- true

	// Helper: check if player has left the room bounds
	function IsOutside(pos) {
		return pos.x < room_min.x || pos.x > room_max.x ||
		       pos.y < room_min.y || pos.y > room_max.y ||
		       pos.z < room_min.z || pos.z > room_max.z;
	}

	// Repeated check: teleport player back if they try to escape
	function CheckAndTeleport() {
		if (!player || !player.IsValid()) return;

		local scope = player.GetScriptScope()
		if (!("is_brecken" in scope) || !scope.is_brecken) return;
		if (!("is_trapped" in scope) || !scope.is_trapped) return;

		if (IsOutside(player.GetOrigin())) {
			player.SetOrigin(return_pos);
			ScriptPrintMessageCenterAll("You are trapped for 60 seconds!");
		}

		// Repeat the check every X seconds
		EntFireByHandle(self, "RunScriptCode", "CheckAndTeleport()", check_interval, null, null);
	}

	// End the trap after time expires
	function ReleaseTrap() {
		if (!player || !player.IsValid()) return;
		player.GetScriptScope().is_trapped = false;
		ScriptPrintMessageCenterAll("You are now free to leave.");
	}

	// Start the repeated trap-check and the release timer
	EntFireByHandle(self, "RunScriptCode", "CheckAndTeleport()", 1.0, null, null);
	EntFireByHandle(self, "RunScriptCode", "ReleaseTrap()", trap_duration, null, null);
}
