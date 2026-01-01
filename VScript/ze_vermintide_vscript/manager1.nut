const flZombieTeleportDelay = 5.0;
const strZombieTeleportParticle = "zombieteleport1";
const flZombieTeleportSize = 128.0;
const flZombieTeleportParticleDuration = 10.0;

enum eTeams
{
	iZombie = 2,
	iHuman = 3
};

iMaxPlayers <- MaxClients().tointeger(),
flWorldBottom <- NetProps.GetPropVector(Entities.First(), "m_WorldMins").z;

function OnPostSpawn()
{
	MarkForPurge();

	local hBigNetwork = Entities.FindByName(null, "BigNet");
	MarkForPurge(hBigNetwork);
	hBigNetwork.Kill();
}

function TeleportZombies(strDestination)
{
	local hDestination = Entities.FindByName(null, strDestination);

	if (!hDestination)
		return;

	MarkForPurge(hDestination);

	local vOrigin = hDestination.GetOrigin(),
	flMaxs = flZombieTeleportSize / 2,
	tTraceInfo =
	{
		start = vOrigin,
		end = Vector(vOrigin.x, vOrigin.y, flWorldBottom),
		hullmin = Vector(-flMaxs, -flMaxs),
		hullmax = Vector(flMaxs, flMaxs),
		mask = 1 | 2 | 8 | 16384 | 65536
	};
	TraceHull(tTraceInfo);
	vOrigin = tTraceInfo.endpos;

	SpawnZombieTeleportParticle(vOrigin);

	local qaAngle = hClosestDestination.GetAbsAngles(){z = 0};

	EntFireByHandle(self, "RunScriptCode", "TeleportZombiesDelay(Vector(" + vOrigin.x + ", " + vOrigin.y + ", " + vOrigin.z + "), QAngle(" + qaAngle.x + ", " + qaAngle.y + "))", flZombieTeleportDelay, hPlayer, null);
}

function TeleportZombiesNearestHumans(strDestination)
{
	local iHumanCount = 0,
	vHumanAverageOrigin = Vector();

	foreach (hPlayer in GetAliveTeamPlayers(eTeams.iHuman))
		iHumanCount++,
		vHumanAverageOrigin += hPlayer.GetOrigin();

	vHumanAverageOrigin.x /= iHumanCount,
	vHumanAverageOrigin.y /= iHumanCount,
	vHumanAverageOrigin.z /= iHumanCount;

	local flShortestDistance = -1.0,
	hClosestDestination;

	for (local hDestination; hDestination = Entities.FindByName(hDestination, strDestination);)
	{
		MarkForPurge(hDestination);

		local vOrigin = hDestination.GetOrigin(),
		flDistance = (vHumanAverageOrigin - vOrigin).Length();

		if (flShortestDistance != -1 && flDistance >= flShortestDistance)
			continue;

		flShortestDistance = flDistance,
		hClosestDestination = hDestination;
	}

	if (!hClosestDestination)
		return;

	local vOrigin = hClosestDestination.GetOrigin(),
	flMaxs = flZombieTeleportSize / 2,
	tTraceInfo =
	{
		start = vOrigin,
		end = Vector(vOrigin.x, vOrigin.y, flWorldBottom),
		hullmin = Vector(-flMaxs, -flMaxs),
		hullmax = Vector(flMaxs, flMaxs),
		mask = 1 | 2 | 8 | 16384 | 65536
	};
	TraceHull(tTraceInfo);
	vOrigin = tTraceInfo.endpos;

	SpawnZombieTeleportParticle(vOrigin);

	local qaAngle = hClosestDestination.GetAbsAngles(){z = 0};

	EntFireByHandle(self, "RunScriptCode", "TeleportZombiesDelay(Vector(" + vOrigin.x + ", " + vOrigin.y + ", " + vOrigin.z + "), QAngle(" + qaAngle.x + ", " + qaAngle.y + "))", flZombieTeleportDelay, hPlayer, null);
}

function SpawnZombieTeleportParticle(vOrigin)
{
	local hParticle = SpawnEntityFromTable("info_particle_system"
	{
		origin = vOrigin,
		effect_name = strZombieTeleportParticle,
		start_active = true
	});
	MarkForPurge(hParticle);

	EntFireByHandle(hParticle, "Kill", "", flZombieTeleportParticleDuration, null, null);
}

function TeleportZombiesDelay(vOrigin, qaAngle)
{
	foreach (iPlayerIndex, hPlayer in GetAliveTeamPlayers(eTeams.iZombie))
		TeleportZombie(activator, vOrigin, qaAngle);
}

function TeleportZombie(hPlayer, vOrigin, qaAngle)
{
	hPlayer.SetAbsOrigin(vOrigin);
	hPlayer.SnapEyeAngles(qaAngle);

	local flVerticalVelocity = hPlayer.GetAbsVelocity().z;

	if (flVerticalVelocity > 0)
		flVerticalVelocity = 0.0;

	hPlayer.SetAbsVelocity(Vector(0, 0, flVerticalVelocity));
}

function GetAliveTeamPlayers(iTeam)
{
	local aPlayers = array(0);

	for (local iPlayer = 1; iPlayer <= iMaxPlayers; iPlayer++)
	{
		local hPlayer = PlayerInstanceFromIndex(iPlayer);
		MarkForPurge(hPlayer);

		if (!hPlayer || !hPlayer.IsAlive() || hPlayer.GetTeam() != iTeam)
			continue;

		aPlayers.push(hPlayer);
	}

	return aPlayers;
}

function MarkForPurge(hEntity = null)
{
	if (!hEntity)
		hEntity = self;

	NetProps.SetPropBool(hEntity, "m_bForcePurgeFixedupStrings", true);
}