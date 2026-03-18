::MyEventTable1 <- {
	function OnGameEvent_player_death(params)
	{
		local userid = params.userid;
		local player = GetPlayerFromUserID(userid);

		if (player != null)
		{
			//printl(player.GetName() + " is now dead!");
			player.KeyValueFromString("targetname", "default");
			//printl(player.GetName() + " is now reset!");
		}
	}
}

::MyEventTable2 <- {
	function OnGameEvent_player_spawn(params) 
	{
		local userid = params.userid;
		local player = GetPlayerFromUserID(userid);

		if (player != null)
		{
			//printl(player.GetName() + " New player joined server");
			player.KeyValueFromString("targetname", "default");
			//printl(player.GetName() + " Targetname Applied");
		}
	}
}

__CollectGameEventCallbacks(MyEventTable1);
__CollectGameEventCallbacks(MyEventTable2);