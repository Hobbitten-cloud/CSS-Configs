IncludeScript("ze_peak_map/global_functions.nut") // DW i'll give this alongside this script, place it in "scripts/vscripts" and it will work.

::STAMINA_TEXT <- null

class Player {
	// Constants
	static MAX_STAMINA 			= 100
	static STAMINA_DRAIN_RATE	= 0.1	// drain per tick
	static STAMINA_REGEN_RATE	= 0.025	// regen per tick
	static WALL_DRAIN_MIN		= 0.5 	// the minimum multiplier while draining stamina depending on wall angle
	static WALL_DRAIN_MAX		= 1.25 	// the maximum multiplier while draining stamina depending on wall angle
	static CLIMB_SPEED			= 50
	static WALL_CHECK_DIST		= 32
	static STICK_VELOCITY		= 125.0

	// Main variables, buttons_last for the input handling, player to know whos the player attached.
	buttons_last	= 0
	player			= null

	show_stamina	= true
	showing_text	= false
	climbing 		= false
	stamina			= 0
	boosted_from_ground = false

	constructor(_ply) {
		this.player = _ply

		this.stamina = MAX_STAMINA
	}

	function PlayerThink() {
		if (!self.IsAlive()) return -1

		local deltatime = FrameTime()

		local buttons = NetProps.GetPropInt(self, "m_nButtons")
		local buttons_changed = info.buttons_last ^ buttons
		local buttons_pressed = buttons_changed & buttons
		local buttons_released = buttons_changed & (~buttons)

		info.buttons_last = buttons

		info.Climbing(deltatime, buttons, buttons_changed, buttons_pressed, buttons_released) 

		if (!info.showing_text) {
			info.ShowStamina()
			info.showing_text = true
		}

		return -1
	}

	function Climbing(deltatime, buttons, buttons_changed, buttons_pressed, buttons_released) {
		if (stamina < MAX_STAMINA) stamina += STAMINA_REGEN_RATE
		else stamina = MAX_STAMINA

		if (buttons & BTN_USE) {
			// Start climbing when holding the use key
			local trace_pos = player.GetOrigin() + Vector(0, 0, 1)

			// Tracing
			local trace = {
				start = trace_pos
				end = trace_pos + player.GetAbsAngles().Forward() * WALL_CHECK_DIST
				ignore = player
				mask = 16513
			}

			TraceLineEx(trace)

			local is_on_wall = trace.hit

			if (is_on_wall && stamina >= 0) {
				// Thanks copilot xd
				local n = trace.plane_normal
				local nlen = sqrt(n.x * n.x + n.y * n.y + n.z * n.z)
				if (nlen > 0.000001) n = n * (1.0 / nlen)

				local upDot = n.Dot(Vector(0, 0, 1))
				if (upDot < 0) upDot = -upDot
				if (upDot > 1) upDot = 1

				local wallness = 1.0 - upDot

				local drain_multiplier = Lerp(WALL_DRAIN_MIN, WALL_DRAIN_MAX, wallness)

				if ((player.GetFlags() & FL_ONGROUND) != 0 && !boosted_from_ground) {
					player.SetAbsVelocity(Vector(0, 0, 275)) // A quick boost

					boosted_from_ground = true
					RunWithDelay(@() boosted_from_ground = false, 0.2)
				}
				else if (!boosted_from_ground) {
					local new_velocity = player.GetAbsVelocity()
					local stick_velocity = trace.plane_normal * -STICK_VELOCITY
					new_velocity.x = stick_velocity.x
					new_velocity.y = stick_velocity.y
					new_velocity.z = CLIMB_SPEED

					player.SetAbsVelocity(new_velocity)
					climbing = true
				}

				stamina -= STAMINA_DRAIN_RATE * drain_multiplier
			}
		}

		climbing = false
	}

	function ShowStamina() {
		if (!player.IsAlive()) return

		if (show_stamina) {
			local text = format("Stamina: %d/%d", stamina, MAX_STAMINA)

		STAMINA_TEXT.KeyValueFromString("message", text)
			STAMINA_TEXT.AcceptInput("Display", null, player, null)
		}
		
		EntFireByHandle(player, "RunScriptCode", "info.ShowStamina();", 0.25, null, null)
	}
}

function OnPostSpawn() {
	STAMINA_TEXT = Entities.FindByName(STAMINA_TEXT, "_player_stamina_text")
}

CollectEventsInScope({
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)

		// Handle Bots
		if (IsPlayerABot(player)) {
			player.ValidateScriptScope()
			player.GetScriptScope().info <- Player(player)
		}
		else if (player.GetTeam() == 0) {
			player.ValidateScriptScope()
			player.GetScriptScope().info <- Player(player)
			player.GetScriptScope().PlayerThink <- player.GetScriptScope().info.PlayerThink

			AddThinkToEnt(player, "PlayerThink")

			SendGlobalGameEvent("player_activate", { userid = params.userid })
		}

		// Reset the player.
		AddThinkToEnt(player, null)

		player.KeyValueFromString("targetname", "player_none")


		if (!IsPlayerABot(player)) {
			player.GetScriptScope().info = Player(player)
			player.GetScriptScope().PlayerThink = player.GetScriptScope().info.PlayerThink

			AddThinkToEnt(player, "PlayerThink")
		}	
	}
})