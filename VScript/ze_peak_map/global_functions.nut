// ==========================================================================
// Global Functions for any Pasas Maps!
// Just IncludeScript this script, and you should have every function
// ==========================================================================
::MaxPlayers <- MaxClients().tointeger()

// Enum for Lerp smoothing type
enum LerpEase {
	Linear,
	EaseIn,
	EaseOut,
	EaseInOut
}

// Coroutine stuff.
::coroutine_delays <- {}
if (!("coroutine_entity" in getroottable()))
	::coroutine_entity <- null

// ==========================================
// Thanks Luffaren for most of the functions
// ==========================================
::GetTouchingPlayers <- function(trigger, team = 0, touchers = []){
	local tplayers = []
	if (touchers.len()==0) {
		for (local h; h = Entities.FindByName(h, "player");) {
			touchers.push(h)
		}
	}
	foreach(h in touchers){
		if (!h.IsAlive())
			continue

		if (team != 0 && team != h.GetTeam())
			continue

		if (IsPlayerTouching(h, trigger))
			tplayers.push(h)
	}
	return tplayers;
}

::IsPlayerTouching <- function(player, trigger){
	return(IsTouching(player.GetOrigin() + Vector(0,0,16.5), trigger, 16.5) || IsTouching(player.EyePosition() - Vector(0,0,12.0), trigger, 16.5));
}

::IsTouching <- function(point, trigger, thickness = 0){
	local mins = trigger.GetBoundingMins() - Vector(thickness,thickness,thickness);
	local maxs = trigger.GetBoundingMaxs() + Vector(thickness,thickness,thickness);
	local relative = point - trigger.GetOrigin();
	local pforward = relative.Dot(trigger.GetForwardVector());
	local pright = relative.Dot(trigger.GetRightVector());
	local pup = relative.Dot(trigger.GetUpVector());
	if (pforward >= mins.x && pforward <= maxs.x &&
		pright >= mins.y && pright <= maxs.y &&
		pup >= mins.z && pup <= maxs.z) 
			return true;
	return false;
}

// This expects two entities, not vectors.
::GetDistanceEntity <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	local z1 = vector1.GetOrigin().z;
	local z2 = vector2.GetOrigin().z;
	if(vector1.GetClassname()=="player")z1+=36;
	if(vector2.GetClassname()=="player")z2+=36;

	return sqrt((vector1.GetOrigin().x-vector2.GetOrigin().x)*(vector1.GetOrigin().x-vector2.GetOrigin().x) +
				(vector1.GetOrigin().y-vector2.GetOrigin().y)*(vector1.GetOrigin().y-vector2.GetOrigin().y) +
				(z1-z2)*(z1-z2));
}

// XY version
::GetDistanceEntityXY <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	local z1 = vector1.GetOrigin().z;
	local z2 = vector2.GetOrigin().z;
	if(vector1.GetClassname()=="player")z1+=36;
	if(vector2.GetClassname()=="player")z2+=36;

	return sqrt((vector1.GetOrigin().x-vector2.GetOrigin().x)*(vector1.GetOrigin().x-vector2.GetOrigin().x) +
				(vector1.GetOrigin().y-vector2.GetOrigin().y)*(vector1.GetOrigin().y-vector2.GetOrigin().y));
}

// Variation of GetDistanceEntity, but takes in vectors instead.
// This expects 2 vectors, not entities
::GetDistance <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return sqrt((vector1.x - vector2.x) * (vector1.x - vector2.x) + 
				(vector1.y - vector2.y) * (vector1.y - vector2.y) +
				(vector1.z - vector2.z) * (vector1.z - vector2.z))
}

// XY version
::GetDistanceXY <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return sqrt((vector1.x - vector2.x) * (vector1.x - vector2.x) + 
				(vector1.y - vector2.y) * (vector1.y - vector2.y))
}

// This expects 2 vectors, not entities
::GetDirection <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return (vector2 - vector1)
}

// End of Luffaren Functions

::Lerp <- function(start, end, amount, easing = LerpEase.Linear) {
	local t = amount

	switch(easing) {
		case LerpEase.EaseIn: {
			t = t * t
			break
		}
		case LerpEase.EaseOut: {
			t = t * (2 - t)
			break
		}
		case LerpEase.EaseInOut: {
			t = t < 0.5 ? 2 * (t * t) : -1 + (4 - 2 * t) * t
			break
		}
	}

	return start + (end - start) * t
}

::SetPlayerFOV <- function(player, fov, time = 0.0) {
	if (time > 0.0) {
		local whichFOV = fov == 0 ? "m_iFOV" : "m_iDefaultFOV";
		NetProps.SetPropInt(player, "m_iFOVStart", NetProps.GetPropInt(player, whichFOV));
		NetProps.SetPropFloat(player, "m_flFOVTime", Time());
		NetProps.SetPropFloat(player, "m_Local.m_flFOVRate", time);
	}

	NetProps.SetPropInt(player, "m_iFOV", fov);
}

// This expects cleanup after use. Not cleaning this up will result 
// in bad consequences. and also leaked entities.
// Centered only is used for players.
::AttachParticleToEntity <- function(particle, entity, centered = true) {
	local ent_origin = entity.GetOrigin()
	local _origin = null
	if (entity.GetClassname() == "player" && centered)
		_origin = entity.GetCenter()
	else
		_origin = ent_origin

	local p = SpawnEntityFromTable("info_particle_system", {
		origin = _origin
		effect_name = particle
		start_active = false
	})
	
	local temp_name = format("attachparticlefunction_%d", RandomInt(0, 1024))
	local original_name = entity.GetName()

	p.ValidateScriptScope()

	entity.KeyValueFromString("targetname", temp_name)
	p.KeyValueFromString("cpoint1", temp_name)

	p.GetScriptScope().entity_to_follow <- entity
	p.GetScriptScope().FollowEntity <- function() {
		if (entity_to_follow == null) {
			self.Kill()
			return -1
		}

		if (!entity_to_follow.IsValid()) {
			self.Kill()
			return -1
		}

		if (entity_to_follow.GetClassname() == "player" && !entity_to_follow.IsAlive()) {
			self.Kill()
			return -1
		}

		if (entity_to_follow != null && entity_to_follow.IsValid() && self != null && self.IsValid())
			self.SetOrigin(entity_to_follow.GetOrigin() + Vector(0, 0, entity_to_follow.GetClassname() == "player" && centered ? 36 : 0))

		return -1
	}
	p.GetScriptScope().centered <- centered
	p.AcceptInput("Start", null, null, null)

	NetProps.SetPropBool(p, "m_bForcePurgeFixedupStrings", true)
	entity.KeyValueFromString("targetname", original_name)

	AddThinkToEnt(p, "FollowEntity")

	return p
}

// Variation of AttachParticleToEntity.
// Once again, expected to be cleaned up.
::AttachEntityToEntity <- function(classname, keyvalues, entity, centered = true) {
	local e = CreateEntity(classname, keyvalues)

	e.ValidateScriptScope()

	e.GetScriptScope().entity_to_follow <- entity
	e.GetScriptScope().centered <- centered
	e.GetScriptScope().FollowEntity <- function() {
		if (entity_to_follow == null) {
			self.Kill()
			return -1
		}

		if (!entity_to_follow.IsValid()) {
			self.Kill()
			return -1
		}

		if (entity_to_follow.GetClassname() == "player" && !entity_to_follow.IsAlive()) {
			self.Kill()
			return -1
		}

		if (entity_to_follow != null && entity_to_follow.IsValid() && self != null && self.IsValid())
			self.SetOrigin(entity_to_follow.GetOrigin() + Vector(0, 0, entity_to_follow.GetClassname() == "player" && centered ? 36 : 0))

		return -1
	}
	
	AddThinkToEnt(e, "FollowEntity")

	return e
}

::SetColor <- function(entity, r, g, b) {
	local clr = (r) | (g << 8) | (b << 16)
	NetProps.SetPropInt(entity, "m_clrRender", clr)
}

::ClientPrintSafe <- function(player, text) {
	//replace ^ with \x07 at run-time
	local escape = "^"

	//just use the normal print function if there's no escape character
	if (!startswith(text, escape)) {
		ClientPrint(player, 3, text)
		return
	}
	
	//split text at the escape character
	local splittext = split(text, escape, true)
	
	//format into new string
	local formatted = ""
	foreach (i, t in splittext)
		formatted += format("\x07%s", t)
	
	//print formatted string
	ClientPrint(player, 3, formatted)
} 

// Wont return anything though.
::SpawnTemplate <- function(template_name, _origin, _angles = QAngle(0, 0, 0)) {
	// Create a temporary entmaker
	local ent_maker = CreateEntity("env_entity_maker", {
		origin = _origin
		angles = _angles
		EntityTemplate = template_name
	})

	ent_maker.AcceptInput("ForceSpawn", null, null, null)
	ent_maker.Destroy()
}

// Wrapper for Spawning Entities. Includes support for parenting.
::CreateEntity <- function(classname, keyvalues, parent = null) {
	local entity = SpawnEntityFromTable(classname, keyvalues)
	NetProps.SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)

	if (parent != null)
		entity.AcceptInput("SetParent", "!activator", parent, null)

	return entity
}

// Strips the player of any weapons.
// Requires a map_stripper entity.
::StripPlayer <- function(player) {
	EntFire("map_stripper", "StripWeaponsAndSuit", null, 0, player)
}

// Precache array of sounds
::PrecacheSoundArray <- function(snd_array) {
	foreach (snd in snd_array)
		PrecacheSound(snd)
}

// Makes a variable permanent
// Expects a string as a variable name. Data can be any.
// Returns the variable data after.
::MakePermanent <- function(variable_name, variable_data) {
	if (!(variable_name in getroottable())) {
		getroottable()[variable_name] <- variable_data
		return getroottable()[variable_name]
	}
	return getroottable()[variable_name]
}

// Emits a sound to everyone. This takes in a soundscript.
// Be sure to precache the soundscript first.
// Might be superseeded soon.
::EmitSoundToAll <- function(sound_script) {
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue
		
		EmitSoundOnClient(sound_script, player)
	}
}

// Gets the current damage filter name of an entity.	
::GetDamageFilterName <- function(ent) {
	return NetProps.GetPropString(ent, "m_iszDamageFilterName")
}

// Sets a damage filter for an entity, if available. Set to empty string to reset.
::SetDamageFilter <- function(ent, filter_name) {
	ent.AcceptInput("SetDamageFilter", filter_name, null, null)
}

::DebugDrawTrigger <- function(trigger, r, g, b, alpha, duration) {
	local origin = trigger.GetOrigin()
	local mins = NetProps.GetPropVector(trigger, "m_Collision.m_vecMins")
	local maxs = NetProps.GetPropVector(trigger, "m_Collision.m_vecMaxs")
	if (trigger.GetSolid() == 2)
		DebugDrawBox(origin, mins, maxs, r, g, b, alpha, duration)
	else if (trigger.GetSolid() == 3)
		DebugDrawBoxAngles(origin, mins, maxs, trigger.GetAbsAngles(), Vector(r, g, b), alpha, duration)	
}

::GetBoxFromRay <- function(start_pos, end_pos, box_half_size) {
	// Calculate the center point of the ray
	local center = Vector(
		(start_pos.x + end_pos.x) / 2,
		(start_pos.y + end_pos.y) / 2,
		(start_pos.z + end_pos.z) / 2
	)
	
	// Calculate min and max bounds
	local min_bounds = Vector(
		min(start_pos.x, end_pos.x) - box_half_size.x,
		min(start_pos.y, end_pos.y) - box_half_size.y,
		min(start_pos.z, end_pos.z) - box_half_size.z
	)
	
	local max_bounds = Vector(
		max(start_pos.x, end_pos.x) + box_half_size.x,
		max(start_pos.y, end_pos.y) + box_half_size.y,
		max(start_pos.z, end_pos.z) + box_half_size.z
	)
	
	return {
		min = min_bounds,
		max = max_bounds,
		center = center
	}
}

// Thanks CoPilot :D
::DrawOrientedBoxFromRay <- function(start_pos, direction, length, width, height, rgb = Vector(255, 0, 0), duration = 0.1) {
	// Normalize the direction vector
	local forward = direction
	forward.Norm()
	
	// Create right and up vectors using cross products
	local world_up = Vector(0, 0, 1)
	local right = forward.Cross(world_up)
	right.Norm()
	
	local up = right.Cross(forward)
	up.Norm()
	
	// Calculate box center
	local center = start_pos + (forward * (length / 2))
	
	// Calculate half-extents
	local half_length = length / 2
	local half_width = width / 2
	local half_height = height / 2
	
	// Calculate the 8 corners of the oriented box
	local corners = []
	
	// Front face
	corners.append(center + (forward * half_length) + (right * half_width) + (up * half_height))
	corners.append(center + (forward * half_length) + (right * half_width) - (up * half_height))
	corners.append(center + (forward * half_length) - (right * half_width) - (up * half_height))
	corners.append(center + (forward * half_length) - (right * half_width) + (up * half_height))
	
	// Back face
	corners.append(center - (forward * half_length) + (right * half_width) + (up * half_height))
	corners.append(center - (forward * half_length) + (right * half_width) - (up * half_height))
	corners.append(center - (forward * half_length) - (right * half_width) - (up * half_height))
	corners.append(center - (forward * half_length) - (right * half_width) + (up * half_height))
	
	// Draw the box edges
	DrawBoxEdges(corners, rgb, duration)
}

::DrawBoxEdges <- function(corners, rgb = Vector(255, 0, 0), duration = 0.1) {
	// Front face edges
	DebugDrawLine(corners[0], corners[1], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[1], corners[2], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[2], corners[3], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[3], corners[0], rgb.x, rgb.y, rgb.z, true, duration)
	
	// Back face edges
	DebugDrawLine(corners[4], corners[5], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[5], corners[6], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[6], corners[7], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[7], corners[4], rgb.x, rgb.y, rgb.z, true, duration)
	
	// Connecting edges
	DebugDrawLine(corners[0], corners[4], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[1], corners[5], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[2], corners[6], rgb.x, rgb.y, rgb.z, true, duration)
	DebugDrawLine(corners[3], corners[7], rgb.x, rgb.y, rgb.z, true, duration)
}

::min <- function(a, b) {
	return (a < b) ? a : b
}

::max <- function(a, b) {
	return (a > b) ? a : b
}

::ShuffleArray <- function(arr) {
    local shuffled = []
    // Create a copy of the array
    foreach(item in arr) {
        shuffled.append(item)
    }

    for (local i = shuffled.len() - 1; i > 0; i--) {
        local j = RandomInt(0, i)
        local temp = shuffled[i]
        shuffled[i] = shuffled[j]
        shuffled[j] = temp
    }
    return shuffled
}

::GetPlayerSteamID <- function(player) {
	return NetProps.GetPropString(player, "m_szNetworkIDString")
}

::GetPlayerName <- function(p) {
	return NetProps.GetPropString(p,"m_szNetname");
}

::GetCurrentWeapon <- function(player) {
	return NetProps.GetPropEntity(player, "m_hActiveWeapon")
}

::GetPlayerSpeedProp <- function(player) {
	return NetProps.GetPropFloat(player, "m_flLaggedMovementValue")
}

::SetPlayerSpeedProp <- function(player, speed) {
	NetProps.SetPropFloat(player, "m_flLaggedMovementValue", speed)
}

// Too stubborn to use EntFireByHandle.
// Thanks CoPilot. God damnit I need to stop using AI
// Might get superseeded with VScripts Example next time.

// Coroutine Functions
function CoroutineTick() {
	local current_time = Time()
	local threads_to_clean = []

	foreach(co, data in coroutine_delays) {
		if (co == null || typeof(co) != "thread") {
			if (dev_mode)
				printf("[Coroutines] Added a thread to cleanup due to it not being a thread.\n")
			threads_to_clean.push(co)
			continue
		}

		if (data.cancelled) {
			threads_to_clean.push(co)
			if (dev_mode)
				printf("[Coroutines] Added a thread to cleanup due to it being cancelled.\n")
			continue
		}

		if (!data.active)
			continue

		if (data.suspended && data.suspend_time <= current_time) {
			data.suspended = false

			if (co.getstatus() == "suspended") {
				co.wakeup()
			}
		}

		if (co.getstatus() != "suspended" && co.getstatus() != "running")
			threads_to_clean.push(co)
	}

	foreach(co in threads_to_clean) {
		if (dev_mode) {
			if (coroutine_delays[co].error)
				printf("[Coroutines] Cleaned up thread with an error.\n")
			else
				printf("[Coroutines] Cleaned up thread.\n")
		}
			
		delete coroutine_delays[co]
	}

	return -1
}

// Create a new entity for the coroutines to take place in, once.
if (coroutine_entity == null) {
	coroutine_entity = CreateEntity("info_target", {
		origin = Vector(0, 0, 0)
	})

	coroutine_entity.ValidateScriptScope()
	coroutine_entity.GetScriptScope().Tick <- CoroutineTick

	AddThinkToEnt(coroutine_entity, "Tick")
	printl("[Coroutines] Created Coroutine Entity.")
}

// ------------------------------------------------------------
// Creates the coroutine. pass in everything you need.
// Anything else can be passed through the argument table.
// ------------------------------------------------------------
// BE CAREFUL with coroutine functions!
// They can crash servers if they are not built for it!
// I'm looking at you, NiDE!
// ------------------------------------------------------------
::NewThread <- function(func, script_scope = null, entity_handle = null, argument_table = {}) {
	local co = newthread(func)

	coroutine_delays[co] <- {
		active = true,
		suspended = false,
		suspend_time = 0,
		cancelled = false
		error = false
	}

	try {
		if (argument_table.len() <= 0) {
			if (script_scope == null && entity_handle == null)
				co.call(co)
			else if (entity_handle == null)
				co.call(co, script_scope)
			else if (script_scope == null)
				co.call(co, entity_handle)
			else
				co.call(co, script_scope, entity_handle)
		}
		else
			co.call(co, script_scope, entity_handle, argument_table)
	}
	catch (e) {
		if (!dev_mode) {
			for (local player; player = Entities.FindByClassname(player, "player");) {
				if (dev_mode) {
					local Chat = @(m) (printl(m), ClientPrint(player, 2, m))  // Log to console only
					ClientPrint(player, 3, format("\x07FF0000COROUTINE ERROR [%s].\nCheck console for details", e))
					
					Chat(format("\n====== TIMESTAMP: %g ======\nCOROUTINE ERROR [%s]", Time(), e))
					Chat("CALLSTACK")
					local s, l = 2
					while (s = getstackinfos(l++))
						Chat(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))
					Chat("LOCALS")
					if (s = getstackinfos(2)) {
						foreach (n, v in s.locals) {
							local t = type(v)
							t ==    "null" ? Chat(format("[%s] NULL"  , n))    :
							t == "integer" ? Chat(format("[%s] %d"    , n, v)) :
							t ==   "float" ? Chat(format("[%s] %.14g" , n, v)) :
							t ==  "string" ? Chat(format("[%s] \"%s\"", n, v)) :
											Chat(format("[%s] %s %s" , n, t, v.tostring()))
						}
					}
				}
			}
		}
		else
			throw e

		if (co in coroutine_delays) {
			coroutine_delays[co].active = false
			coroutine_delays[co].error = true
		}
	}
	
	return co
}

::Delay <- function(thread, time) {
	if (thread in coroutine_delays) {
		if (!coroutine_delays[thread].active)
			return null

		coroutine_delays[thread].suspended = true
		coroutine_delays[thread].suspend_time = Time() + time
		
		local suspendFunc = function() { suspend() }
		return suspendFunc()
	}

	return null
}

::CancelThread <- function(thread) {
	if (thread in coroutine_delays) {
		if (dev_mode)
			printf("[Coroutines] Cancelling thread.\n")
		
		// Mark as inactive to skip processing in CoroutineTick
		coroutine_delays[thread].active = false
		
		// If the thread is suspended, we need to wake it up so it can terminate
		// Don't do this, just keep it suspended.
		// if (coroutine_delays[thread].suspended && thread.getstatus() == "suspended") {
		// 	coroutine_delays[thread].suspended = false
		// 	thread.wakeup()
		// }

		coroutine_delays[thread].cancelled = true
		
		// Schedule it for cleanup on next tick
		return true
	}
	
	return false
}

::CountActiveThreads <- function() {
	local count = 0
	local suspended_count = 0
	local running_count = 0
	local error_count = 0
	
	foreach(co, data in coroutine_delays) {
		if (data.active) {
			count++
			
			if (data.suspended)
				suspended_count++
			else if (co.getstatus() == "running")
				running_count++
		}

		if (data.error)
			error_count++
	}
	
	if (dev_mode)
		printl(format("[Coroutines] Active: %d (Suspended: %d, Running: %d, Errors: %d)", 
					 count, suspended_count, running_count, error_count))
	
	return {
		total = count
		suspended = suspended_count
		running = running_count
		errors = error_count
	}
}

::CollectEventsInScope <- function(events) {
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

// VScript Examples for EntFire Timers
::world_spawn <- Entities.FindByClassname(null, "worldspawn")
world_spawn.ValidateScriptScope()
::world_spawn_scope <- world_spawn.GetScriptScope()

::RunWithDelay <- function(func, delay = 0.0) {
	local func_name = UniqueString()
	world_spawn_scope[func_name] <- function[this]() {
		delete world_spawn_scope[func_name]
		func()
	}
	
	EntFireByHandle(world_spawn, "CallScriptFunction", func_name, delay, null, null)
	return func_name
}

// Constants go here, for example, Keymaps or smthing
// Keymaps / Buttons
const BTN_ATTACK1 	= 1
const BTN_ATTACK2 	= 2048
const BTN_ATTACK3	= 33554432
const BTN_JUMP		= 2
const BTN_DUCK		= 4
const BTN_FORWARD	= 8
const BTN_BACK		= 16
const BTN_LEFT		= 128
const BTN_RIGHT		= 256
const BTN_USE		= 32
const BTN_CANCEL	= 64
const BTN_MOVELEFT	= 512
const BTN_MOVERIGHT	= 1024
const BTN_RUN		= 4096
const BTN_RELOAD 	= 8192
const BTN_ALT1		= 16384
const BTN_ALT2 		= 32768
const BTN_SCORE		= 65536
const BTN_SPEED		= 131072
const BTN_WALK		= 262144
const BTN_ZOOM		= 524288
const BTN_WEAPON1	= 1048576
const BTN_WEAPON2	= 2097152
const BTN_BULLRUSH	= 4194304
const BTN_GRENADE1	= 8388608
const BTN_GRENADE2	= 16777216

// Damage Types
const DMG_GENERIC				= 0
const DMG_CRUSH					= 1
const DMG_BULLET				= 2
const DMG_SLASH					= 4
const DMG_BURN 					= 8
const DMG_VEHICLE				= 16
const DMG_FALL 					= 32
const DMG_BLAST					= 64
const DMG_CLUB					= 128
const DMG_SHOCK 				= 256
const DMG_SONIC 				= 512
const DMG_ENERGYBEAM 			= 1024
const DMG_PREVENT_PHYSICS_FORCE	= 2048
const DMG_NEVERGIB 				= 4096
const DMG_ALWAYSGIB 			= 8192
const DMG_DROWN 				= 16384
const DMG_PARALYZE 				= 32768
const DMG_NERVEGAS				= 65536
const DMG_POISON 				= 131072
const DMG_RADIATION 			= 262144
const DMG_DROWNRECOVER 			= 524288
const DMG_ACID					= 1048576
const DMG_SLOWBURN				= 2097152
const DMG_REMOVENORAGDOLL		= 4194304
const DMG_PHYSGUN 				= 8388608
const DMG_PLASMA 				= 16777216
const DMG_AIRBOAT 				= 33554432
const DMG_DISSOLVE 				= 67108864
const DMG_BLAST_SURFACE 		= 134217728
const DMG_DIRECT 				= 268435456
const DMG_BUCKSHOT 				= 536870912

// Sound Recipient
const RECIPIENT_FILTER_DEFAULT			= 0
const RECIPIENT_FILTER_PAS_ATTENUATION	= 1
const RECIPIENT_FILTER_PAS 				= 2
const RECIPIENT_FILTER_PVS 				= 3
const RECIPIENT_FILTER_SINGLE_PLAYER	= 4
const RECIPIENT_FILTER_GLOBAL 			= 5
const RECIPIENT_FILTER_TEAM 			= 6

// FFade
const FFADE_IN				= 1
const FFADE_OUT				= 2
const FFADE_MODULATE		= 4
const FFADE_STAYOUT			= 8
const FFADE_PURGE			= 16 

// HUD Notify
const HUD_PRINTNOTIFY 		= 1
const HUD_PRINTCONSOLE 		= 2
const HUD_PRINTTALK 		= 3
const HUD_PRINTCENTER 		= 4 

// Entity Flags
const FL_ONGROUND 				= 1
const FL_DUCKING 				= 2
const FL_ANIMDUCKING 			= 4
const FL_WATERJUMP 				= 8
const PLAYER_FLAG_BITS 			= 11
const FL_ONTRAIN 				= 16
const FL_INRAIN 				= 32
const FL_FROZEN 				= 64
const FL_ATCONTROLS 			= 128
const FL_CLIENT 				= 256
const FL_FAKECLIENT 			= 512
const FL_INWATER 				= 1024
const FL_FLY 					= 2048
const FL_SWIM 					= 4096
const FL_CONVEYOR 				= 8192
const FL_NPC 					= 16384
const FL_GODMODE 				= 32768
const FL_NOTARGET 				= 65536
const FL_AIMTARGET 				= 131072
const FL_PARTIALGROUND 			= 262144
const FL_STATICPROP 			= 524288
const FL_GRAPHED 				= 1048576
const FL_GRENADE 				= 2097152
const FL_STEPMOVEMENT 			= 4194304
const FL_DONTTOUCH 				= 8388608
const FL_BASEVELOCITY 			= 16777216
const FL_WORLDBRUSH 			= 33554432
const FL_OBJECT 				= 67108864
const FL_KILLME 				= 134217728
const FL_ONFIRE 				= 268435456
const FL_DISSOLVING 			= 536870912
const FL_TRANSRAGDOLL 			= 1073741824
const FL_UNBLOCKABLE_BY_PLAYER 	= 2147483648