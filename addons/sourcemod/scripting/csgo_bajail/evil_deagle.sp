/*
     ______      _ __   ____                   __   
    / ____/   __(_) /  / __ \___  ____ _____ _/ /__ 
   / __/ | | / / / /  / / / / _ \/ __ `/ __ `/ / _ \
  / /___ | |/ / / /  / /_/ /  __/ /_/ / /_/ / /  __/
 /_____/ |___/_/_/  /_____/\___/\__,_/\__, /_/\___/ 
                                     /____/         
	Special Thanks to meng
*/

Handle g_hAdminMenu;
bool g_bEnabled = true;
Handle g_hSpawnsADT;
Handle g_cvarEfxColor;
Handle g_cvarRecoilMul;
float g_fRecoilMul;
Handle g_cvarDamage;
char g_sDamage[8];
int g_iPointHurt;
int g_iEDEntityIndex;
int g_iEDOwnerIndex;
float g_fLastPosVec[3];
bool g_bIsRoundEnd;
int g_ihOwnerEntity, g_iiClip1, g_iiAmmo;
int g_iRingColor[4], g_iHaloSprite2, g_iGlowSprite;
char g_sMapCfgPath[PLATFORM_MAX_PATH];

public void OnConfigsExecuted() {
	if (GetConVarInt(g_cvarEfxColor) == 1) {
		g_iRingColor = {150, 125, 0, 255};
		g_iGlowSprite = PrecacheModel("materials/sprites/yellowglow1.vmt");
	}
	else {
		g_iRingColor = {255, 25, 15, 255};
		g_iGlowSprite = PrecacheModel("materials/sprites/redglow3.vmt");
	}

	g_fRecoilMul = -1.0*GetConVarFloat(g_cvarRecoilMul);
	GetConVarString(g_cvarDamage, STRING(g_sDamage));
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	if (convar == g_cvarRecoilMul)
		g_fRecoilMul = (-1.0 * StringToFloat(newValue));
	else if (convar == g_cvarDamage)
		strcopy(STRING(g_sDamage), newValue);
}

public Action CommandEDControl(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_evildeagle <0/1>");
		return Plugin_Handled;
	}

	char sArg[8];
	GetCmdArgString(STRING(sArg));
	int ibuffer = StringToInt(sArg);
	switch (ibuffer) {
		case 0: {
			g_bEnabled = false;
			ReplyToCommand(client, "\x04[Evil Deagle] \x03Plugin DISABLED");
		}
		case 1: {
			if (GetArraySize(g_hSpawnsADT) < 1) {
				g_bEnabled = false;
				ReplyToCommand(client, "\x04[Evil Deagle] \x03No saved spawn positions. Plugin DISABLED");
			} else {
				if(!g_bEnabled) {
					g_bEnabled = true;
					ReplyToCommand(client, "\x04[Evil Deagle] \x03Plugin ENABLED");
				}
				else ReplyToCommand(client, "\x04[Evil Deagle] \x03Plugin already ENABLED");
			}
		}
	}

	return Plugin_Handled;
}

public Action CommandShowPos(int client, int args) {
	int arraySize = GetArraySize(g_hSpawnsADT);
	if (arraySize < 1) {
		ReplyToCommand(client, "\x04[Evil Deagle] \x03No saved spawn positions.");
		return Plugin_Handled;
	}

	CreateTimer(1.0, TimerShowSpawns, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	ReplyToCommand(client, "\x04[Evil Deagle] \x03Showing spawns for 1 minute.");

	return Plugin_Handled;
}

public Action TimerShowSpawns(Handle timer, any client) {
	static int timesRepeated;
	int arraySize = GetArraySize(g_hSpawnsADT);

	if ((timesRepeated++ > 60) || (arraySize < 1) || !IsClientInGame(client)) {
		timesRepeated = 0;
		return Plugin_Stop;
	}

	float fVec[3];
	for (int i = 0; i < arraySize; i++) {
		GetArrayArray(g_hSpawnsADT, i, fVec);
		TE_SetupGlowSprite(fVec, g_iGlowSprite, 1.0, 0.7, 217);
		TE_SendToClient(client);
	}

	PrintHintText(client, "Total Saved Spawns: %i", arraySize);

	return Plugin_Continue;
}

public Action CommandSavePos(int client, int args) {
	Handle hKV = CreateKeyValues("EDSP");
	float fVec[3];
	char sBuffer[32];
	GetClientAbsOrigin(client, fVec);
	fVec[2] += 16.0;
	Format(STRING(sBuffer), "vec:%i%i", RoundToFloor(FloatAbs(fVec[0])), RoundToFloor(FloatAbs(fVec[1])));
	FileToKeyValues(hKV, g_sMapCfgPath);
	KvSetVector(hKV, sBuffer, fVec);
	KeyValuesToFile(hKV, g_sMapCfgPath);
	PushArrayArray(g_hSpawnsADT, fVec);
	ReplyToCommand(client, "\x04[Evil Deagle] \x03Spawn position saved! [total spawn positions: %d]", GetArraySize(g_hSpawnsADT));
	CloseHandle(hKV);

	return Plugin_Handled;
}

public Action CommandRemovePos(int client, int args) {
	float client_fVec[3], spawn_fVec[3];
	char sBuffer[32];
	GetClientAbsOrigin(client, client_fVec);
	client_fVec[2] += 16.0;
	int arraySize = GetArraySize(g_hSpawnsADT);
	if (arraySize) {
		for (int i = 0; i < arraySize; i++) {
			GetArrayArray(g_hSpawnsADT, i, spawn_fVec);
			if (GetVectorDistance(client_fVec, spawn_fVec) < 48.0) {
				Handle hKV = CreateKeyValues("EDSP");
				FileToKeyValues(hKV, g_sMapCfgPath);
				Format(STRING(sBuffer), "vec:%i%i", RoundToFloor(FloatAbs(spawn_fVec[0])), RoundToFloor(FloatAbs(spawn_fVec[1])));
				if (KvJumpToKey(hKV, sBuffer)) {
					KvDeleteThis(hKV);
					RemoveFromArray(g_hSpawnsADT, i);
					KvRewind(hKV);
					KeyValuesToFile(hKV, g_sMapCfgPath);
					ReplyToCommand(client, "\x04[Evil Deagle] \x03Spawn position successfully removed!");
				}
				else
					LogError("Error removing spawn position. Invalid KV key (%s).", sBuffer);

				CloseHandle(hKV);

				return Plugin_Handled;
			}
		}
	}

	ReplyToCommand(client, "\x04[Evil Deagle] \x03No valid spawn position found.");

	return Plugin_Handled;
}

public Action EventRoundStart(Event event, const char[] name, bool dontBroadcast) {	
	if (!g_bEnabled)
		return;

	if (GetArraySize(g_hSpawnsADT) < 1) {
		g_bEnabled = false;
		return;
	}

	g_bIsRoundEnd = false;
	g_iEDEntityIndex = -1;
	g_iEDOwnerIndex = -1;
	g_fLastPosVec[0] = 0.0;
	g_iPointHurt = CreateEntityByName("point_hurt");
	DispatchSpawn(g_iPointHurt);
	CreateTimer(0.1, TimerTrackED, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action EventRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	g_bIsRoundEnd = true;
}

void SpawnNewED(int spott) {
	g_iRingColor = {255, 25, 15, 255};
	g_iGlowSprite = PrecacheModel("materials/sprites/redglow3.vmt");
	int entity = CreateEntityByName("weapon_deagle");
	Entity_SetName(entity, "evil_deagle");
	DispatchSpawn(entity);
	float fVec[3];
	switch (spott) {
		case 0: {
			int arraysize = GetArraySize(g_hSpawnsADT);
			if (arraysize < 1) {
				g_bEnabled = false;
				return;
			}
			GetArrayArray(g_hSpawnsADT, GetURandomIntRange(0, arraysize-1), fVec);
		}
		case 1: {
			fVec = g_fLastPosVec;
		}
	}
	TeleportEntity(entity, fVec, NULL_VECTOR, NULL_VECTOR);
	SetEntData(entity, g_iiClip1, 1);
	g_iEDEntityIndex = entity;
	g_bEvilSpawned = true;
}

public Action TimerTrackED(Handle timer) {
	if (g_bIsRoundEnd) {
		return Plugin_Stop;
	}

	if (!IsValidEntity(g_iEDEntityIndex)) {
		if (!g_bEvilSpawned) {
			SpawnNewED(g_fLastPosVec[0] == 0.0 ? 0 : 1);
		}
		return Plugin_Continue;
	}

	if ((g_iEDOwnerIndex = GetEntDataEnt2(g_iEDEntityIndex, g_ihOwnerEntity)) != -1) {
		if (!g_bEvilBonus) {
			if (isVip(g_iEDOwnerIndex))
				SetEntityHealth(g_iEDOwnerIndex, GetClientHealth(g_iEDOwnerIndex) + 50);
			else
				SetEntityHealth(g_iEDOwnerIndex, GetClientHealth(g_iEDOwnerIndex) + 25);
			g_bEvilBonus = true;
			g_iRingColor = {150, 125, 0, 255};
			g_iGlowSprite = PrecacheModel("materials/sprites/yellowglow1.vmt");
		}
		if (GetEntData(g_iEDEntityIndex, g_iiClip1) > 1)
			SetEntData(g_iEDEntityIndex, g_iiClip1, 1);
		if (GetEntData(g_iEDOwnerIndex, g_iiAmmo + 4) > 1)
			SetEntData(g_iEDOwnerIndex, g_iiAmmo + 4, 0);
		if (!GetEntData(g_iEDEntityIndex, g_iiClip1) && !GetEntData(g_iEDOwnerIndex, g_iiAmmo + 4))
			SetEntData(g_iEDOwnerIndex, g_iiAmmo + 4, 1);

		return Plugin_Continue;
	}

	if (g_iEvilBeamCD) {
		g_iEvilBeamCD--;

		if (!g_iEvilBeamCD) {
			float fVec[3];
			GetEntPropVector(g_iEDEntityIndex, Prop_Data, "m_vecOrigin", fVec);
			TE_SetupGlowSprite(fVec, g_iGlowSprite, 1.0, 0.7, 217);
			TE_SendToAll();
			fVec[2] += 3;
			TE_SetupBeamRingPoint(fVec, 8.0, 36.0, g_iBeamSprite, g_iHaloSprite2, 0, 10, 1.0, 7.0, 1.0, g_iRingColor, 7, 0);
			TE_SendToAll();
			g_iEvilBeamCD = 10;
		}
	}

	return Plugin_Continue;
}

public Action EventWeaponFire(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || g_bLastRequest)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == g_iEDOwnerIndex) {
		char weapon[16];
		GetEventString(event, "weapon", STRING(weapon));
		if (StrContains(weapon, "deagle", false) != -1) {
			SetEntData(client, g_iiAmmo + 4, 1);
			if(IsValidEntity(g_iEDEntityIndex))
				if (GetEntData(g_iEDEntityIndex, g_iiClip1) == 1)
					RequestFrame(TimerRecoil, client);
		}
	}
}

public void TimerRecoil(int client) {
	static float fPlayerAng[3], fPlayerVel[3], fPush[3];
	GetClientEyeAngles(client, fPlayerAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPlayerVel);
	fPlayerAng[0] *= -1.0;
	fPlayerAng[0] = DegToRad(fPlayerAng[0]);
	fPlayerAng[1] = DegToRad(fPlayerAng[1]);
	fPush[0] = g_fRecoilMul*Cosine(fPlayerAng[0])*Cosine(fPlayerAng[1])+fPlayerVel[0];
	fPush[1] = g_fRecoilMul*Cosine(fPlayerAng[0])*Sine(fPlayerAng[1])+fPlayerVel[1];
	fPush[2] = g_fRecoilMul*Sine(fPlayerAng[0])+fPlayerVel[2]; 
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fPush);
}

public void EventPlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || g_bLastRequest)
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker == g_iEDOwnerIndex) {
		char weapon[16];
		GetEventString(event, "weapon", STRING(weapon));
		if (StrEqual(weapon, "deagle") && IsValidEntity(g_iPointHurt)) {
			int victim = GetClientOfUserId(GetEventInt(event,"userid"));
			float attackerPos[3];
			GetClientAbsOrigin(attacker, attackerPos);
			TeleportEntity(g_iPointHurt, attackerPos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(victim, "targetname", "hurt");
			DispatchKeyValue(g_iPointHurt, "DamageTarget", "hurt");
			DispatchKeyValue(g_iPointHurt, "Damage", g_sDamage);
			DispatchKeyValue(g_iPointHurt, "DamageType", "0");
			AcceptEntityInput(g_iPointHurt, "Hurt", attacker);
			DispatchKeyValue(victim, "targetname", "nohurt");
		}
	}
}

public void EventPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled)
		return;

	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (client == g_iEDOwnerIndex) {
		GetClientAbsOrigin(client, g_fLastPosVec);
		g_fLastPosVec[2] += 16.0;
	}
}

/*
	get U random int. *added v1.3 *thx to psychonic
*/

int GetURandomIntRange(int min, int max) {
	return (GetURandomInt() % (max-min+1)) + min;
}  

/* 
	menu support *added v1.3 
*/

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "adminmenu")) g_hAdminMenu = null;
}

public void TopMenuHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Evil Deagle");
	else if (action == TopMenuAction_SelectOption)
		MainMenu(client);
}

void MainMenu(int client) {
	Menu menu = new Menu(MainMenuHandler);
	menu.SetTitle("Evil Deagle");
	menu.AddItem("0", "Enable Plugin");
	menu.AddItem("1", "Disable Plugin");
	menu.AddItem("2", "Show Spawns");
	menu.AddItem("3", "Save New Spawn");
	menu.AddItem("4", "Remove Spawn");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int selection) {
	if (action == MenuAction_Select) {
		char sBuffer[7], iBuffer;
		GetMenuItem(menu, selection, STRING(sBuffer));
		iBuffer = StringToInt(sBuffer);
		switch (iBuffer) {
			case 0: {
				FakeClientCommand(client, "say /evildeagle 1");
			}
			case 1: {
				FakeClientCommand(client, "say /evildeagle 0");
			}
			case 2: {
				FakeClientCommand(client, "say /evildeagle_show");
				MainMenu(client);
			}
			case 3: {
				FakeClientCommand(client, "say /evildeagle_save");
				MainMenu(client);
			}
			case 4: {
				FakeClientCommand(client, "say /evildeagle_remove");
				MainMenu(client);
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}