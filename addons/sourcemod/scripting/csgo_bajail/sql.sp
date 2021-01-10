/*
    _____ ____    __ 
   / ___// __ \  / / 
   \__ \/ / / / / /  
  ___/ / /_/ / / /___
 /____/\___\_\/_____/
                    
*/

void LoadData(int client) {
	if (!IsValidClient(client) || bajail[client].g_bLoaded)
		return;

	char sSteamid[18], sQuery[252];		
	GetClientAuthId(client, AuthId_SteamID64, STRING(sSteamid));
	if (sSteamid[1]) {
		Format(STRING(sQuery), "SELECT `points`, `hud` FROM `points` WHERE steamid = '%s' LIMIT 1", sSteamid);	

		Handle hQuery = SQL_Query(g_hDatabase, sQuery);
		if (SQL_FetchRow(hQuery)) {
			g_iPlayerStuff[client].POINTS += SQL_FetchInt(hQuery, 0);
			bajail[client].g_bHUDStatus = SQL_FetchInt(hQuery, 1) ? true : false;
		}
		else
			SaveData(client);

		bajail[client].g_bLoaded = true;

		if (hQuery != null && CloseHandle(hQuery)) hQuery = null;
	}
	else
		CreateTimer(1.0, Timer_LoadRetry, client);
}

void SaveData(int client) {
	if (!IsValidClient(client))
		return;
	
	char sSteamid[18], sQuery[252];		
	GetClientAuthId(client, AuthId_SteamID64, STRING(sSteamid));
	if (sSteamid[1]) 
	{
		Format(STRING(sQuery), "SELECT `points` FROM `points` WHERE `steamid` = '%s' LIMIT 1", sSteamid);

		Handle hQuery = SQL_Query(g_hDatabase, sQuery);
		if (SQL_FetchRow(hQuery))
			Format(STRING(sQuery), "UPDATE `points` SET `points` = '%i', `hud` = '%i' WHERE `steamid` = '%s'", g_iPlayerStuff[client].POINTS, bajail[client].g_bHUDStatus ? 1 : 0, sSteamid);
		else
			Format(STRING(sQuery), "INSERT INTO `points` VALUES (NULL, '%s', '%i', 1)", sSteamid, g_iPlayerStuff[client].POINTS);
		SQL_Query(g_hDatabase, sQuery);	

		if (hQuery != null && CloseHandle(hQuery)) hQuery = null;
	}
}

void ConnectDb() {
	char sError[255];
	g_hDatabase = SQL_Connect("bajail", true, STRING(sError));
	if (g_hDatabase != null) {
		LoopClients(i)
			if (IsValidClient(i))
				LoadData(i);
	}
	else
		CreateTimer(1.0, Timer_DBRetry, _, TIMER_FLAG_NO_MAPCHANGE);
}

void DisconnectDb() {
	if (g_hDatabase != null) {
		CloseHandle(g_hDatabase);
		g_hDatabase = null;
	}
}

public Action Timer_LoadRetry(Handle timer, any client) {
	if (g_hDatabase != null)
		LoadData(client);
}

public Action Timer_DBRetry(Handle timer) {
	if (g_hDatabase == null)
		ConnectDb();
}