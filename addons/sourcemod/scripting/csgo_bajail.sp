#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <multicolors>
#include <cstrike>
#include <ctban>
#include <smlib>
#include <sdkhooks>
#include <adminmenu>
#include <steamworks>
#include <devzones>

#include "csgo_bajail/globals.sp"
#include "csgo_bajail/mapzones.sp"
#include "csgo_bajail/functions.sp"
#include "csgo_bajail/menus.sp"
#include "csgo_bajail/dv.sp"
#include "csgo_bajail/sql.sp"
#include "csgo_bajail/store.sp"
#include "csgo_bajail/grenades_bonus.sp"
#include "csgo_bajail/commands.sp"
#include "csgo_bajail/evil_deagle.sp"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() 
{
	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("Le plugin \"CSGO: BaJail\" n'est supporté que sur Counter-Strike: Global Offensive !");
	
	CreateConVar("csgo_bajail_version", PLUGIN_VERSION, "CSGO: BaJail", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_blind", Event_Blind);
	HookEvent("hegrenade_detonate", Event_GrenadeDetonate, EventHookMode_Pre);
	HookEvent("flashbang_detonate", Event_FlashDetonate);

	RegAdminCmd("sm_spec", Command_Spec, ADMFLAG_SLAY);
	RegAdminCmd("sm_switch", Command_Switch, ADMFLAG_SLAY);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY);
	RegAdminCmd("sm_rr", Command_ResetRound, ADMFLAG_SLAY);
	RegAdminCmd("sm_savepos", Command_SavePos, ADMFLAG_ROOT);
	RegAdminCmd("sm_jailtime", Command_JailTime, ADMFLAG_ROOT);
	RegAdminCmd("sm_tokens", Command_Tokens, ADMFLAG_SLAY);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY);

	RegConsoleCmd("sm_plainte", Command_Plainte);
	RegConsoleCmd("sm_dv", Command_DV);
	RegConsoleCmd("sm_lr", Command_DV);
	RegConsoleCmd("sm_gift", Command_Gift);
	RegConsoleCmd("sm_points", Command_Points);
	RegConsoleCmd("sm_hud", Command_HUD);
	RegConsoleCmd("sm_afk", Command_Afk);
	RegConsoleCmd("sm_qr", Command_Qr);
	
	RegConsoleCmd("sm_store", Command_Store);
	RegConsoleCmd("sm_shop", Command_Store);
	RegConsoleCmd("sm_boutique", Command_Store);
	
	RegConsoleCmd("sm_testhudmsg", Command_TestHudMsg);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_ViewWeapon, "+lookatweapon");
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	
	RegConsoleCmd("spectate", Command_Spectate);	
	RegConsoleCmd("joinclass", Command_JoinClass);	
	RegConsoleCmd("drop", Command_Drop);
	
	char sBuffer[32];
	for (int i; i < sizeof(g_sBlockCMD); i++) {
		Format(STRING(sBuffer), "%s", g_sBlockCMD[i]);
		RegConsoleCmd(sBuffer, Command_Blocked);
	}
	
	ServerCommand("sm_rcon mp_ignore_round_win_conditions 1");
	FindConVar("sv_allow_thirdperson").SetBool(true);
	
	ConVar g_hCvarTeamName1 = FindConVar("mp_teamname_1");
	ConVar g_hCvarTeamName2 = FindConVar("mp_teamname_2");
	
	g_hCvarTeamName1.SetString("Gardiens");
	g_hCvarTeamName2.SetString("Détenus");
	
	
	//AddNormalSoundHook(Hook_NormalSound);
	
	/// EVIL DEAGLE ///
	
	CreateConVar("sm_evildeagle_version", "2.0", "CSGO: Evil Deagle", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarEfxColor = CreateConVar("sm_evildeagle_efxcolor", "0", "The color of the evil deagle's location effects. [0 = red | 1 = gold]", _, true, 0.0, true, 1.0);
	g_cvarRecoilMul = CreateConVar("sm_evildeagle_recoil", "700", "Recoil effect adjustment. [range 100 - 700]", _, true, 100.0, true, 700.0);
	g_cvarDamage = CreateConVar("sm_evildeagle_damage", "700", "Damage adjustment. [range 100 - 700]", _, true, 100.0, true, 700.0);
	HookConVarChange(g_cvarRecoilMul, OnSettingChanged);
	HookConVarChange(g_cvarDamage, OnSettingChanged);
	
	g_hSpawnsADT = CreateArray(3);
	
	g_ihOwnerEntity = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
	g_iiClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iiAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	
	if ((g_iFlashDuration = FindSendPropInfo("CCSPlayer", "m_flFlashDuration")) == -1)
		SetFailState("Failed to find CCSPlayer::m_flFlashDuration offset");

	if ((g_iFlashAlpha = FindSendPropInfo("CCSPlayer", "m_flFlashMaxAlpha")) == -1)
		SetFailState("Failed to find CCSPlayer::m_flFlashMaxAlpha offset");
	
	RegAdminCmd("sm_evildeagle", CommandEDControl, ADMFLAG_RCON);
	RegAdminCmd("sm_evildeagle_show", CommandShowPos, ADMFLAG_RCON);
	RegAdminCmd("sm_evildeagle_save", CommandSavePos, ADMFLAG_RCON);
	RegAdminCmd("sm_evildeagle_remove", CommandRemovePos, ADMFLAG_RCON);
	
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("weapon_fire", EventWeaponFire);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
	
	char configspath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(configspath), "configs/evil-deagle");
	if (!DirExists(configspath))
		CreateDirectory(configspath, 0x0265);

	BuildPath(Path_SM, STRING(configspath), "configs/enemy-down/positions");
	if (!DirExists(configspath))
		CreateDirectory(configspath, 0x0265);
	
	BuildPath(Path_SM, STRING(configspath), "configs/enemy-down/jailtime");
	if (!DirExists(configspath))
		CreateDirectory(configspath, 0x0265);
		
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(topmenu);
	
	HookUserMessage(GetUserMessageId("TextMsg"), MsgHook_AdjustMoney, true);
	
	ResetMap();
	
	LoadTranslations("common.phrases");
	
	CreateTimer(0.1, EntrerOuPas, _, TIMER_REPEAT);
}

public void OnAdminMenuReady(Handle topmenu) {
	/// EVIL DEAGLE ///
	
	if (topmenu == g_hAdminMenu)
		return;
	
	g_hAdminMenu = topmenu;
	TopMenuObject serverCmds = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_SERVERCOMMANDS);
	AddToTopMenu(g_hAdminMenu, "sm_evildeagle", TopMenuObject_Item, TopMenuHandler, serverCmds, "sm_evildeagle", ADMFLAG_CUSTOM5);
}

public void OnMapStart() {
	PrecacheSound(SOUND_TIMEWARNING);
	PrecacheSound(SOUND_JIHAD);
	PrecacheSound(SOUND_VIPDAY);
	PrecacheSound(SOUND_OPENCT);
	PrecacheSound(SOUND_OPENT);
	PrecacheSound(SOUND_QL);
	PrecacheSound(SOUND_QR);
	PrecacheSound(SOUND_DCT);
	PrecacheSound(SOUND_TAZER);
	PrecacheSound(SOUND_DV);
	PrecacheSound(SOUND_DVSTART);
	PrecacheSound(SOUND_REFUSE);
	PrecacheSound(SOUND_ACCEPTE);
	PrecacheSound(SOUND_NOSCOPE);
	PrecacheSound(SOUND_COWBOY);
	PrecacheSound(SOUND_PANPAN);
	PrecacheSound(SOUND_TP);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_CTBAN);
	PrecacheSound(SOUND_PLAINTE);
	PrecacheSound(SOUND_THUNDER);
	PrecacheSound(SOUND_LUMIERE);
	
	PrecacheModel(MODEL_GARDIEN1, true);
	PrecacheModel(MODEL_GARDIEN2, true);
	PrecacheModel(MODEL_CHEF1, true);
	PrecacheModel(MODEL_CHEF2, true);
	PrecacheModel(MODEL_PRISONNIER1, true);
	PrecacheModel(MODEL_PRISONNIER2, true);
	PrecacheModel(MODEL_PRISONNIER3, true);
	PrecacheModel(MODEL_PRISONNIER4, true);
	PrecacheModel(MODEL_PRISONNIER5, true);
	PrecacheModel(MODEL_VIP, true);
	PrecacheModel(ARMS_GARDIEN1, true);
	PrecacheModel(ARMS_GARDIEN2, true);
	PrecacheModel(ARMS_CHEF1, true);
	PrecacheModel(ARMS_CHEF2, true);
	PrecacheModel(ARMS_PRISONNIER1, true);
	PrecacheModel(ARMS_PRISONNIER2, true);
	PrecacheModel(ARMS_PRISONNIER3, true);
	PrecacheModel(ARMS_PRISONNIER4, true);
	PrecacheModel(ARMS_PRISONNIER5, true);
	PrecacheModel(ARMS_VIP, true);

	PrecacheModel(SMOKE_PARTICLE, true);
	
	g_iBeamSprite = PrecacheModel("sprites/halo01.vmt");
	g_iBeamSprite2 = PrecacheModel("sprites/laser.vmt");
	g_iBeamSprite3 = PrecacheModel("sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("sprites/muzzleflash4.vmt"); 
	g_iLightingSprite = PrecacheModel("sprites/lgtning.vmt"); 
	g_iSmokeSprite = PrecacheModel("sprites/steam1.vmt");
	
	g_bPlaying = false;
	
	ServerCommand("sm_reloadadmins");	
	
	//PrecacheModel("models/weapons/w_eq_fraggrenade.mdl", true);
	
	ServerCommand("sm_rcon mp_ignore_round_win_conditions 1");
	CS_TerminateRound(0.0, CSRoundEnd_GameStart);
	FindConVar("sv_allowupload").SetInt(1);	
	FindConVar("sv_downloadurl").SetString("https://fastdl.enemy-down.eu/");
	FindConVar("sv_ignoregrenaderadio").SetInt(1);	

	ConnectDb();
	
	GetCurrentMap(STRING(g_sMap));
	if (StrContains(g_sMap, "workshop") != -1) {
		char mapPart[3][64];
		ExplodeString(g_sMap, "/", mapPart, 3, 64);
		strcopy(STRING(g_sMap), mapPart[2]);
	}
	
	
	BuildPath(Path_SM, STRING(g_sMapConfigPath), "configs/enemy-down/positions/%s.cfg", g_sMap);
	if (!FileExists(g_sMapConfigPath))
		CreateConfig();
	
	BuildPath(Path_SM, STRING(g_sMapTimePath), "configs/enemy-down/jailtime/%s.cfg", g_sMap);
	if (FileExists(g_sMapTimePath))
		ReadJailtime();
	else
		g_iJailTime = 0;
	
	g_iPhraseCpt = ReadJailReasons();
	
	/// EVIL DEAGLE ///
	
	g_iHaloSprite2 = PrecacheModel("materials/sprites/halo01.vmt");
	
	BuildPath(Path_SM, STRING(g_sMapCfgPath), "configs/evil-deagle/%s.cfg", g_sMap);
	
	KeyValues kv = new KeyValues("EDSP");
	if (kv.ImportFromFile(g_sMapCfgPath) && kv.GotoFirstSubKey(false)) {
		float fVec[3];
		do {
			kv.GetVector(NULL_STRING, fVec);
			PushArrayArray(g_hSpawnsADT, fVec);
		} while (kv.GotoNextKey(false));
	}
	delete kv;
	
	ResetMap();
	g_iCdrQr = 6;
	
	g_hGlobalTimer = CreateTimer(1.0, Timer_Global, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(120.0, Timer_Pub, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action MsgHook_AdjustMoney(UserMsg msg_id, Handle msg, const players[], int playersNum, bool reliable, bool init) {
	char buffer[64];
	PbReadString(msg, "params", STRING(buffer), 0);
	
	if (StrEqual(buffer, "#Player_Cash_Award_Killed_Enemy")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Win_Hostages_Rescue")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Win_Defuse_Bomb")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Win_Time")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Elim_Bomb")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Elim_Hostage")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_T_Win_Bomb")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Point_Award_Assist_Enemy_Plural")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Point_Award_Assist_Enemy")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Point_Award_Killed_Enemy_Plural")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Point_Award_Killed_Enemy")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Kill_Hostage")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Damage_Hostage")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Get_Killed")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Respawn")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Interact_Hostage")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Killed_Enemy")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Rescued_Hostage")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Bomb_Defused")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Bomb_Planted")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Killed_Enemy_Generic")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Killed_VIP")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_Kill_Teammate")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Win_Hostage_Rescue")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Loser_Bonus")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Loser_Zero")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Rescued_Hostage")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Hostage_Interaction")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Hostage_Alive")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Planted_Bomb_But_Defused")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_CT_VIP_Escaped")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_T_VIP_Killed")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_no_income")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Generic")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_Custom")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Team_Cash_Award_no_income_suicide")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_ExplainSuicide_YouGotCash")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_ExplainSuicide_TeammateGotCash")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_ExplainSuicide_EnemyGotCash")) {
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_ExplainSuicide_Spectators")) {
		return Plugin_Handled;
	}
	if(StrEqual(buffer, "#SFUI_Notice_Warmup_Has_Ended")) {
		return Plugin_Handled;
	}
	if(StrEqual(buffer, "#Cstrike_TitlesTXT_Game_teammate_attack")) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void OnMapEnd() {
	ResetMap();
	DisconnectDb();
	
	/// EVIL DEAGLE ///
	
	ClearArray(g_hSpawnsADT);
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason) {
	if (reason == CSRoundEnd_GameStart && g_bPlaying)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	ResetMap();
	
	g_hGlobalTimer = CreateTimer(1.0, Timer_Global, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	if (StrContains(g_sMap, "razor_go") != -1) {
		char sEntity[64];
		float fPosition[3];
		for (int i = MaxClients; i < GetMaxEntities(); i++) {
			if (i != INVALID_ENT_REFERENCE && IsValidEdict(i) && IsValidEntity(i)) {
				GetEdictClassname(i, STRING(sEntity));
				if (StrEqual(sEntity, "weapon_c4")) {
					RemoveEdict(i);
				} else if(StrEqual(sEntity, "weapon_hegrenade")) {
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPosition);
					fPosition[0] = RoundFloat(fPosition[0] * 100.0) / 100.0;
					fPosition[1] = RoundFloat(fPosition[1] * 100.0) / 100.0;
					fPosition[2] = RoundFloat(fPosition[2] * 100.0) / 100.0;
					RemoveEdict(i);
					int ArmeHe = CreateEntityByName("weapon_hegrenade");
					if (IsValidEdict(ArmeHe) && IsValidEntity(ArmeHe)) {
						DispatchSpawn(ArmeHe);
						TeleportEntity(ArmeHe, view_as<float>(fPosition), NULL_VECTOR, NULL_VECTOR);
					}
				} else if(StrEqual(sEntity, "weapon_flashbang")) {
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPosition);
					fPosition[0] = RoundFloat(fPosition[0] * 100.0) / 100.0;
					fPosition[1] = RoundFloat(fPosition[1] * 100.0) / 100.0;
					fPosition[2] = RoundFloat(fPosition[2] * 100.0) / 100.0;
					RemoveEdict(i);
					int ArmeGss = CreateEntityByName("weapon_flashbang");
					if (IsValidEdict(ArmeGss) && IsValidEntity(ArmeGss)) {
						DispatchSpawn(ArmeGss);
						TeleportEntity(ArmeGss, view_as<float>(fPosition), NULL_VECTOR, NULL_VECTOR);
					}
				} else if(StrEqual(sEntity, "weapon_hkp2000")) {
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPosition);
					fPosition[0] = RoundFloat(fPosition[0] * 100.0) / 100.0;
					fPosition[1] = RoundFloat(fPosition[1] * 100.0) / 100.0;
					fPosition[2] = RoundFloat(fPosition[2] * 100.0) / 100.0;
					RemoveEdict(i);
					int ArmeHkp2000 = CreateEntityByName("weapon_hkp2000");
					if (IsValidEdict(ArmeHkp2000) && IsValidEntity(ArmeHkp2000)) {
						DispatchSpawn(ArmeHkp2000);
						if(fPosition[0] == -1297.000000 && fPosition[1] == 486.000000) {
							fPosition[0] += 10.0;
							fPosition[1] -= 10.0;
						}
						TeleportEntity(ArmeHkp2000, view_as<float>(fPosition), NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
	}
	
	if (GetTeamClientCount(2) >= 4)
		RequestFrame(Frame_GetJihad);
	
	if (GetTeamClientCount(3) >= 3)g_bCanDct = true;
	else g_bCanDct = false;
	
	if (GetTeamClientCount(2) > 1 && GetTeamClientCount(3) > 1) {
		LoopClients(i) {
			if (IsValidClient(i) && GetClientTeam(i) >= CS_TEAM_T) {
				g_iPlayerStuff[i].POINTS += 10;
				
				if (isVipPlus(i) && g_iPlayerStuff[i].POINTS > LIMIT_POINT_VIPPLUS) {
					g_iPlayerStuff[i].POINTS = LIMIT_POINT_VIPPLUS;
					CPrintToChat(i, "%s Vous avez atteint la limite de points.", PREFIX);
				}
				else if (isVip(i) && g_iPlayerStuff[i].POINTS > LIMIT_POINT_VIP) {
					g_iPlayerStuff[i].POINTS = LIMIT_POINT_VIP;
					CPrintToChat(i, "%s Vous avez atteint la limite de points.", PREFIX);
				}
				else if (g_iPlayerStuff[i].POINTS > LIMIT_POINT && (!isVipPlus(i) || !isVip(i))) {
					g_iPlayerStuff[i].POINTS = LIMIT_POINT;
					CPrintToChat(i, "%s Vous avez atteint la limite de points.", PREFIX);
				}
			}
		}
	}	
	
	if (ReadPosition("button")) {
		int iEntity;
		float fEntityPos[3];
		
		while ((iEntity = FindEntityByClassname(iEntity, "func_button")) != -1) {			
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityPos);
			if (fEntityPos[0] == g_fReadPos[0][0] && fEntityPos[1] == g_fReadPos[0][1] && fEntityPos[2] == g_fReadPos[0][2]) {
				if (g_bPlaying)
					HookSingleEntityOutput(iEntity, "OnIn", Hook_JailOpen);
				else
					AcceptEntityInput(iEntity, "Press", -1, -1);					
			}
		}
	}
	
	if (ReadPosition("button2")) {
		int iEntity2;
		float fEntityPos2[3];
		
		while ((iEntity2 = FindEntityByClassname(iEntity2, "func_button")) != -1) {			
			GetEntPropVector(iEntity2, Prop_Send, "m_vecOrigin", fEntityPos2);
			
			if (fEntityPos2[0] == g_fReadPos[0][0] && fEntityPos2[1] == g_fReadPos[0][1] && fEntityPos2[2] == g_fReadPos[0][2])
				Entity_Lock(iEntity2);
		}
	}
	
	if (g_iJailTime && g_iJailTime < 99999) CPrintToChatAll("%s Ouverture des cellules dans {lime}%i {default}secondes.", PREFIX, g_iJailTime);	
	
	if (GetTotalPlayer(3) > 1 && GetTotalPlayer(2) > 1) {
		g_hCheckChef = CreateTimer(10.0, Timer_CheckChef);
		g_iGameAnswer = GetRandomInt(1, 3);
		g_hArmurerieCt = CreateTimer(10.0, Timer_ArmurerieIsT);
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	g_iTimelimit = 0;
	g_iJailsCooldown = 0;
	g_bRoundEnded = true;
	g_iMin = 0;
	g_iSec = 0;
	
	LoopClients(i) 
	{
		if (IsValidClient(i)) 
		{
			if (g_iPlayerTeam[i]) 
			{
				if (g_iPlayerTeam[i] > 3) 
					g_iPlayerTeam[i] -= 2;
				if (GetClientTeam(i) != g_iPlayerTeam[i] && GetClientTeam(i) > CS_TEAM_SPECTATOR && (!CTBan_IsClientBanned(i) && g_iPlayerTeam[i] == CS_TEAM_CT || g_iPlayerTeam[i] == CS_TEAM_T)) 
				{
					CS_SwitchTeam(i, g_iPlayerTeam[i]);
				}
				g_iPlayerTeam[i] = 0;
			}
			
			if (bajail[i].g_bNeedClass) {
				FakeClientCommandEx(i, "joinclass 1");
				bajail[i].g_bNeedClass = false;
			}
			
			bajail[i].g_NoDv = false;
			
			if(GetClientTeam(i) == CS_TEAM_T)
				g_iJour[i]++;
			else if(GetClientTeam(i) == CS_TEAM_CT)
				if(g_iJour[i] != 1)
					g_iJour[i] = 1;
		}
	}
	
	ReBalance();
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return Plugin_Continue;
	
	if (GetClientTeam(client) == CS_TEAM_CT && CTBan_IsClientBanned(client)) 
	{
		RequestFrame(Frame_CTBanned, client);
		return Plugin_Continue;
	}

	ResetClient(client);
	
	bajail[client].g_bPlayerDied = false;
	
	SendConVarValue(client, FindConVar("mp_playercashawards"), "0");
	SendConVarValue(client, FindConVar("mp_teamcashawards"), "0");
	CreateTimer(0.0, Timer_RemoveRadar, client);
	
	int iHealthBonus = 0;
	
	if (GetClientTeam(client) == CS_TEAM_CT)
		iHealthBonus += 10;
	
	if (isVip(client)) {
		g_iPlayerStuff[client].GIFT = 1;
		iHealthBonus += 15;
	} else if (isModoTest(client) || isModo(client) || isAdmin(client)) {
		iHealthBonus += 15;
	}
	else {
		char PlayerClanTag[32];
		CS_GetClientClanTag(client, STRING(PlayerClanTag));
		
		if (StrEqual(PlayerClanTag, "Enemy-Down.eu <3") || StrEqual(PlayerClanTag, "«Membre»") || StrEqual(PlayerClanTag, "Enemy-Down") || StrEqual(PlayerClanTag, "«ENYD»"))
			iHealthBonus += 10;
	}	
	
	SetEntityHealth(client, GetClientHealth(client) + iHealthBonus);
	
	if (GetClientTeam(client) == CS_TEAM_CT) {			
		switch (GetRandomInt(1,3)) {
			case 1,2: {
				g_iPlayerSkin[client] = 1;
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_GARDIEN1);
			}
			case 3: {
				g_iPlayerSkin[client] = 2;
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_GARDIEN2);
			}
		}
	} else if (GetClientTeam(client) == CS_TEAM_T) {
		switch (GetRandomInt(1,7)) {
			case 1,2: {
				g_iPlayerSkin[client] = 1;
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_PRISONNIER1);
			}
			case 3,4: {
				g_iPlayerSkin[client] = 2;
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_PRISONNIER2);
			}
			case 5: {
				g_iPlayerSkin[client] = 3;
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_PRISONNIER3);
			}
			case 6: {
				g_iPlayerSkin[client] = 4;
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_PRISONNIER4);
			}
			case 7: {
				g_iPlayerSkin[client] = 5;
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_PRISONNIER5);
			}
		}
		
		if(isVip(client) && ReadPosition("jail_vip")) {
			switch (GetRandomInt(1, 10)) {
				case 1: {
					CPrintToChat(client, "{green}[VIP] {default}Vous venez de spawn dans la Jail VIP !");
					TeleportEntity(client, g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
				}
			}
		}
	}
	
	RequestFrame(Frame_PlayerInit, client);
	bajail[client].g_bDropLock = true;
	
	RequestFrame(Frame_SpawnChoice, client);
	
	return Plugin_Continue;
}

public void Frame_Respawn(int client) {
	if (IsValidClient(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
		CS_RespawnPlayer(client);
}

public void Frame_CTBanned(int client) {
	if (IsValidClient(client) && GetClientTeam(client) == CS_TEAM_CT) {
		PerformSmite(client);
		CS_SwitchTeam(client, CS_TEAM_T);
		RequestFrame(Frame_Respawn, client);
	}
}

public Action Timer_RemoveRadar(Handle Timer, any client) {
	if (IsValidClient(client))	
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
} 

public void Frame_PlayerInit(int client) {
	if (IsValidClient(client, true)) {
		if (GetClientTeam(client) == CS_TEAM_CT) {			
			SetClientListeningFlags(client, VOICE_NORMAL);
			if (g_iPlayerSkin[client] == 1)
				SetEntityModel(client, MODEL_GARDIEN1);
			else if (g_iPlayerSkin[client] == 2)
				SetEntityModel(client, MODEL_GARDIEN2);
			DisarmClient(client);
			GivePlayerItemAny(client, "weapon_m4a1");
			GivePlayerItemAny(client, "weapon_deagle");
			GivePlayerItemAny(client, "weapon_knife");
			GivePlayerItemAny(client, "weapon_taser");
			GivePlayerItemAny(client, "weapon_hegrenade");
			GivePlayerItem(client, "item_assaultsuit");
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
			g_iPlayerStuff[client].RW = 3;
			g_iPlayerStuff[client].TAZER = 2;
			if (isVip(client)) {
				g_iPlayerStuff[client].RW += 2;
				g_iPlayerStuff[client].TAZER++;
			}
		}
		else if (GetClientTeam(client) == CS_TEAM_T) {
			SetClientListeningFlags(client, (g_iJailsCooldown ? VOICE_MUTED : VOICE_NORMAL));
			if (g_iPlayerSkin[client] == 1)
				SetEntityModel(client, MODEL_PRISONNIER1);
			else if (g_iPlayerSkin[client] == 2)
				SetEntityModel(client, MODEL_PRISONNIER2);
			else if (g_iPlayerSkin[client] == 3)
				SetEntityModel(client, MODEL_PRISONNIER3);
			else if (g_iPlayerSkin[client] == 4)
				SetEntityModel(client, MODEL_PRISONNIER4);
			else if (g_iPlayerSkin[client] == 5)
				SetEntityModel(client, MODEL_PRISONNIER5);
			DisarmClient(client);
			g_iPlayerStuff[client].REND = 1;
			GivePlayerItemAny(client, "weapon_knife_t");
			
			char s_locPhrase[256];

			Format(STRING(s_locPhrase), "%s", g_sPhrases[GetRandomInt(0, g_iPhraseCpt -1)]);
			
			CPrintToChat(client, "%s {lime}Jour %i {default}: %s", PREFIX, g_iJour[client], s_locPhrase);
			
		}
		bajail[client].g_bDropLock = false;
	}
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(g_iLastRequest.ROULETTE > 0) 
	{
		char sWeapon[32];
		event.GetString("weapon", STRING(sWeapon));
		if (StrContains(sWeapon, "deagle") != -1) 
		{
			if(client == g_indexDV[INDEX_T] || client == g_indexDV[INDEX_CT]) 
			{
				CreateTimer(0.1, rouletteDisarm, client);
			}
		}
	}
	else if (g_bWaitBall && GetClientTeam(client) == CS_TEAM_T) 
	{
		char sWeapon[32];
		event.GetString("weapon", STRING(sWeapon));
		if (StrContains(sWeapon, "awp") != -1) 
		{
			LoopClients(i) 
			{
				if (IsValidClient(i, true) && GetClientTeam(i) >= CS_TEAM_T) 
				{
					SetEntityMoveType(i, MOVETYPE_WALK);
				}
			}
			
			g_bWaitBall = false;
		}
	} 
	else if (g_iPlayerStuff[client].RW && GetClientTeam(client) == CS_TEAM_CT) 
	{
		char sWeapon[32];
		event.GetString("weapon", STRING(sWeapon));
		if (StrContains(sWeapon, "knife") != -1) 
		{
			RWing(client);
		}
	}
}

public Action rouletteDisarm(Handle Timer, any client) 
{
	if(IsValidClient(client, true))
	{
		DisarmClient(g_indexDV[INDEX_T]);
		DisarmClient(g_indexDV[INDEX_CT]);
		if(client == g_indexDV[INDEX_T]) 
		{
			GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_knife");
			if(IsValidClient(g_indexDV[INDEX_CT], true)) 
			{
				GivePlayerItemAny(g_indexDV[INDEX_CT], "weapon_knife");
				GivePlayerItemAny(g_indexDV[INDEX_CT], "weapon_deagle");
			}
		}
		else if(client == g_indexDV[INDEX_CT]) 
		{
			GivePlayerItemAny(g_indexDV[INDEX_CT], "weapon_knife");
			if(IsValidClient(g_indexDV[INDEX_T], true)) 
			{
				GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_knife");
				GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_deagle");
			}
		}
	}
}
	
public void Hook_JailOpen(const char[] output, int entity, int activator, float delay) {
	if (g_iJailsCooldown) {
		Entity_Lock(entity);
		
		if (GetTotalPlayer(3) == 1 && GetTeamClientCount(3) > 1 || GetTotalPlayer(2) == 1) {
			CheckEverything(-1);
		}
		else {
			if (GetClientTeam(activator) == CS_TEAM_CT && g_hCheckChef != null) {
				PerformSmite(activator);
				CPrintToChatAll("%s {lightblue}%N {default}a ouvert les cellules trop tôt !", PREFIX, activator);
				CPrintToChatAll("%s Les Prisonniers ont {green}quartier libre{default} !", PREFIX);
				EmitSoundToAll(SOUND_OPENT, _, _, _, _, 0.1);
				g_bQuartierLibre = true;
			} else if (GetClientTeam(activator) == CS_TEAM_CT && !g_bNoChef) {
				CPrintToChatAll("%s Les Cellules ont été ouvertes par {lightblue}%N {default}!", PREFIX, activator); 
				CPrintToChatAll("%s Écoutez bien les ordres des Gardiens.", PREFIX); 
				EmitSoundToAll(SOUND_OPENCT, _, _, _, _, 0.1);
			} else if (GetClientTeam(activator) == CS_TEAM_CT) {
				CPrintToChatAll("%s Les Cellules ont été ouvertes par {lightblue}%N {default}!", PREFIX, activator); 
				CPrintToChatAll("%s Les Prisonniers ont {green}quartier libre{default}, aucun chef désigné.", PREFIX);
				EmitSoundToAll(SOUND_OPENT, _, _, _, _, 0.1);
				g_bQuartierLibre = true;
			} else if (GetClientTeam(activator) == CS_TEAM_T) {
				CPrintToChatAll("%s Les Cellules ont été ouvertes par {darkred}%N {default}!", PREFIX, activator); 
				CPrintToChatAll("%s Les Prisonniers ont {green}quartier libre {default}!", PREFIX);
				EmitSoundToAll(SOUND_OPENT, _, _, _, _, 0.1);
				g_bQuartierLibre = true;
			} 
			
			char format[128];
			Format(STRING(format), "Cellules ouvertes par %N", activator);		
			PrintHudMessageAll(format);
			
			CPrintToChatAll("%s Les Prisonniers peuvent désormais parler !", PREFIX);
			
			CheckTheGame();
			
			ReBalance(true);
		}
		
		LoopClients(i)
		if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_T)
			SetClientListeningFlags(i, VOICE_NORMAL);
		
		g_iJailsCooldown = 0;
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {		
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (g_bRoundEnded) {
		return;
	}
	
	if (IsValidClient(attacker) && attacker != victim) {
		if (g_bLastRequest) {
			if(!g_iLastRequest.ISOLOIR && !g_iLastRequest.BROCHETTE && !g_iLastRequest.VIP) {
				ResetClient(attacker);
			}
			else if (g_iLastRequest.ROULETTE == 2 || g_iLastRequest.ROULETTE == 4) {
				SetNoRecoil(false);
			}
			else if (g_iLastRequest.VIP && victim == g_indexDV[INDEX_VIP] && attacker == g_indexDV[INDEX_T]) {
				CPrintToChatAll("%s %N a reussi sa DV ! Il peut abattre les gardes du corps.", PREFIX, g_indexDV[INDEX_T]);
				ServerCommand("sm_freeze @ct 20");
				LoopClients(i) {
					if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				}
			}
		}
		
		if (GetClientTeam(attacker) == CS_TEAM_T) {
			g_iPlayerStuff[attacker].POINTS += 5;
			if (isVip(attacker))
			{
				g_iPlayerStuff[attacker].POINTS += 5;
				CPrintToChat(attacker, "%s Vous avez gagné le double de crédits grâce à votre {green}bonus VIP.", PREFIX);
			}
			
			if (isVipPlus(attacker) && g_iPlayerStuff[attacker].POINTS > LIMIT_POINT_VIPPLUS) {
				g_iPlayerStuff[attacker].POINTS = LIMIT_POINT_VIPPLUS;
				CPrintToChat(attacker, "%s Vous avez atteint la limite de points.", PREFIX);
			}
			else if (isVip(attacker) && g_iPlayerStuff[attacker].POINTS > LIMIT_POINT_VIP) {
				g_iPlayerStuff[attacker].POINTS = LIMIT_POINT_VIP;
				CPrintToChat(attacker, "%s Vous avez atteint la limite de points.", PREFIX);
			}
			else if (g_iPlayerStuff[attacker].POINTS > LIMIT_POINT && (!isVipPlus(attacker) || !isVip(attacker))) {
				g_iPlayerStuff[attacker].POINTS = LIMIT_POINT;
				CPrintToChat(attacker, "%s Vous avez atteint la limite de points.", PREFIX);
			}
			
			bajail[attacker].g_bRendLock = true;
			
			TrashTimer(g_hTimerRendLock[attacker]);
			
			CreateTimer(5.0, Timer_RendLockRemover, attacker);
		}
	}
	
	if (IsValidClient(victim)) {
		if(!isModoTest(victim) || !isModo(victim) || !isAdmin(victim) || !isResp(victim) || !isRooted(victim) || !isMe(victim)) SetClientListeningFlags(victim, VOICE_MUTED);
		
		CheckEverything(victim);
		
		ResetClient(victim);
		
		if (!g_bLastRequest && !g_bDernierCT && !g_bLRWait && !g_bLRDenied && IsValidClient(attacker) && attacker != victim && GetClientTeam(attacker) == CS_TEAM_CT) {
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", g_fDeathPosition[victim]);
			g_iKilledBy[victim] = attacker;
			g_iKillsCount[attacker]++;
			
			TrashTimer(g_hTimerFreekill[attacker]);
			
			g_hTimerFreekill[attacker] = CreateTimer(1.0, Timer_FreekillRemover, attacker);
			
			if (g_iKillsCount[attacker] == 5) {            	
				CPrintToChatAll("???????????????");
				CPrintToChatAll("   {darkred}FREEKILL MASSIF");
				CPrintToChatAll("Gardien: {lightblue}%N", attacker);
				ServerCommand("sm_ctban #%i", GetClientUserId(attacker));
				LoopClients(i) {
					if (IsValidClient(i) && g_iKilledBy[i] == attacker && !IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T) {
						CPrintToChat(i, "Vous avez été automatiquement respawn.");
						RequestFrame(Frame_Respawn, i);
						TeleportEntity(i, g_fDeathPosition[i], NULL_VECTOR, NULL_VECTOR);
					}
				}
				CPrintToChatAll("???????????????");
			}
		}
		
		bajail[victim].g_bPlayerDied = true;
		
		if (!g_bPlaying) RequestFrame(Frame_Respawn, victim);
	}
}

public Action Timer_RendLockRemover(Handle timer, any client) {
	if (IsValidClient(client))
		bajail[client].g_bRendLock = false;
	
	g_hTimerRendLock[client] = null;
}

public Action Timer_FreekillRemover(Handle timer, any client) {
	if (IsValidClient(client))
		g_iKillsCount[client] = 0;
	
	
	LoopClients(i) {
		if (IsValidClient(i) && g_iKilledBy[i] == client) {
			g_iKilledBy[i] = -1;
		}
	}
	
	g_hTimerFreekill[client] = null;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	if (!IsValidClient(client, true))
		return Plugin_Continue;
	
	if (buttons & IN_ATTACK2) {
		if (g_iSavePos[client].STATUS && g_iSavePos[client].STATUS < 4 && !g_iSavePos[client].LOCK) {
			bool bButton = false;
			float fPosition[3];
			int entity = GetClientAimTarget(client, false);
			if (entity != INVALID_ENT_REFERENCE && IsValidEdict(entity) && IsValidEntity(entity)) {
				char sClassname[32];
				GetEdictClassname(entity, STRING(sClassname));
				if (StrEqual(sClassname, "func_button"))
					bButton = true;
			}
			if (g_iSavePos[client].STATUS == 1) {
				GetClientEyePosition(client, fPosition);
				if (bButton) {
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fPosition);
					CPrintToChat(client, "%s Bouton détecté.", PREFIX);
				}
				g_fSavePos[client][0][0] = RoundFloat(fPosition[0] * 100.0) / 100.0;
				g_fSavePos[client][0][1] = RoundFloat(fPosition[1] * 100.0) / 100.0;
				g_fSavePos[client][0][2] = RoundFloat(fPosition[2] * 100.0) / 100.0;
				if (!bButton) g_fSavePos[client][0][2] -= 64.0;
				CPrintToChat(client, "%s Définissez la position du {lightblue}Gardien{default}.", PREFIX);
			}
			else if (g_iSavePos[client].STATUS == 2) {
				GetClientEyePosition(client, fPosition);
				if (bButton) {
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fPosition);
					CPrintToChat(client, "%s Bouton détecté.", PREFIX);
				}
				g_fSavePos[client][1][0] = RoundFloat(fPosition[0] * 100.0) / 100.0;
				g_fSavePos[client][1][1] = RoundFloat(fPosition[1] * 100.0) / 100.0;
				g_fSavePos[client][1][2] = RoundFloat(fPosition[2] * 100.0) / 100.0;
				if (!bButton) g_fSavePos[client][1][2] -= 64.0;
				CPrintToChat(client, "%s Définissez la position des {grey}Spectateurs{default}.", PREFIX);
			}
			else if (g_iSavePos[client].STATUS == 3) {
				GetClientEyePosition(client, fPosition);
				if (bButton) {
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fPosition);
					CPrintToChat(client, "%s Bouton détecté.", PREFIX);
				}
				g_fSavePos[client][2][0] = RoundFloat(fPosition[0] * 100.0) / 100.0;
				g_fSavePos[client][2][1] = RoundFloat(fPosition[1] * 100.0) / 100.0;
				g_fSavePos[client][2][2] = RoundFloat(fPosition[2] * 100.0) / 100.0;
				if (!bButton) g_fSavePos[client][2][2] -= 64.0;
				CPrintToChat(client, "%s Écrivez le nom de la Dernière Volonté.", PREFIX);
			}
			g_iSavePos[client].STATUS++;
			g_iSavePos[client].LOCK = true;
			buttons &= ~IN_ATTACK2;
			return Plugin_Changed;		
		}
	}
	else if (g_iSavePos[client].LOCK)
		g_iSavePos[client].LOCK = false;
	
	if (g_bLRPause || !g_bPlaying || g_iSavePos[client].STATUS && g_iSavePos[client].STATUS < 4)
		return Plugin_Continue;
	
	if (buttons & IN_USE && !bajail[client].g_bLastRequestPlayer && g_bLastRequest) {
		buttons &= ~IN_USE;
		return Plugin_Changed;		
	}
	
	if ((buttons & IN_ATTACK2 || buttons & IN_USE || buttons & IN_DUCK) && g_iCowboy[client].COWBOY && !g_bLRPause) {
		if (g_iCowboy[client].MRB && !g_iCowboy[client].LOCK) {
			if (buttons & IN_USE || buttons & IN_DUCK) {
				PerformSmite(client);
				CPrintToChatAll("%s {%s}%N {default}a essayé de tricher !", PREFIX, (GetClientTeam(client) == CS_TEAM_T ? "red" : "blue"), client);
			}
			else {
				g_iCowboy[client].MRB--;
				char format[64];
				Format(STRING(format), "Appuie %ix sur CLIC DROIT !", g_iCowboy[client].MRB);
				PrintHudMessage(client, format);
				
				if (!g_iCowboy[client].MRB) {					
					GivePlayerItemAny(client, "weapon_deagle");
					g_iCowboy[client].WIN = true;
					PrintHudMessage(client, "Tire sur ton adversaire !");
				}
			}
		}
		else if (g_iCowboy[client].USE && !g_iCowboy[client].LOCK) {
			if (buttons & IN_ATTACK2 || buttons & IN_DUCK) {
				PerformSmite(client);
				CPrintToChatAll("%s {%s}%N {default}a essayé de tricher !", PREFIX, (GetClientTeam(client) == CS_TEAM_T ? "red" : "blue"), client);
			}
			else {
				g_iCowboy[client].USE--;
				char format[64];
				Format(STRING(format), "Appuie %ix sur UTILISER !", g_iCowboy[client].USE);
				PrintHudMessage(client, format);
				
				if (!g_iCowboy[client].USE) {					
					GivePlayerItemAny(client, "weapon_deagle");
					g_iCowboy[client].WIN = true;
					PrintHudMessage(client, "Tire sur ton adversaire !");
				}
			}
		}
		else if (g_iCowboy[client].CROUCH && !g_iCowboy[client].LOCK) {		
			if (buttons & IN_ATTACK2 || buttons & IN_USE) {
				PerformSmite(client);
				CPrintToChatAll("%s {%s}%N {default}a essayé de tricher !", PREFIX, (GetClientTeam(client) == CS_TEAM_T ? "red" : "blue"), client);
			}
			else {
				g_iCowboy[client].CROUCH--;
				char format[64];
				Format(STRING(format), "Appuie %ix sur ACCROUPI !", g_iCowboy[client].CROUCH);
				PrintHudMessage(client, format);
				
				if (!g_iCowboy[client].CROUCH) {
					GivePlayerItemAny(client, "weapon_deagle");
					g_iCowboy[client].WIN = true;
					PrintHudMessage(client, "Tire sur ton adversaire !");
				}
			}
		}
		
		g_iCowboy[client].LOCK = true;
		
		buttons &= ~IN_ATTACK2;
		buttons &= ~IN_USE;
		buttons &= ~IN_DUCK;
		return Plugin_Changed;
	}
	else if (g_iCowboy[client].LOCK)
	g_iCowboy[client].LOCK = false;
	
	if (buttons & IN_ATTACK || buttons & IN_ATTACK2) {
		if (g_iLastRequest.UNSCOPE) {
			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (iWeapon != -1 && iWeapon == GetPlayerWeaponSlot(client, 2))
				buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if (g_iLastRequest.BROCHETTE && GetClientTeam(client) == CS_TEAM_CT && g_bWaitBall) {
			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (iWeapon != -1 && iWeapon == GetPlayerWeaponSlot(client, 0)) {
				buttons &= ~IN_ATTACK;
				return Plugin_Changed;
			}
		}
		else if (IsInZone(client, "Mur Invisible") && GetClientTeam(client) == CS_TEAM_CT && !g_bDernierCT && !g_bLRDenied && !g_bLastRequest) {
			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if (iWeapon != -1 && iWeapon == GetPlayerWeaponSlot(client, 0)) {
				char sWeapon[32];
				GetEdictClassname(iWeapon, STRING(sWeapon));
				
				if (StrContains(sWeapon, "awp") != -1) {
					buttons &= ~IN_ATTACK;
					return Plugin_Changed;
				}
			}
		}
		else if (bajail[client].g_bExploding || GetClientTeam(client) == CS_TEAM_CT && !g_bDernierCT && !g_bLRDenied && !g_bLastRequest && !g_bQr && IsInZone(client, "(T)")) {
			buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if (GetClientTeam(client) == CS_TEAM_T && !bajail[client].g_bReceptDone && g_iJailsCooldown && !g_bLRWait && !g_bLastRequest && !g_bLRDenied && IsInZone(client, "Jail")) {
			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (iWeapon != -1 && iWeapon != GetPlayerWeaponSlot(client, 2)) {
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
				return Plugin_Changed;
			}
		}
		else if (GetClientTeam(client) == CS_TEAM_T) {
			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (iWeapon != -1 && iWeapon == GetPlayerWeaponSlot(client, CS_SLOT_C4) && bajail[client].g_bIsKamikaze) {
				if (bajail[client].g_bReceptDone) {
					DisarmClient(client);					
					GivePlayerItemAny(client, "weapon_knife_t");
					bajail[client].g_bExploding = true;
					CreateTimer(1.5, Timer_PlayerJihad, client);
					SetEntityRenderColor(client, 255, 30, 0, 255);
					EmitAmbientSound(SOUND_JIHAD, NULL_VECTOR, client);
				}
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
				return Plugin_Changed;
			}
		}
		
		if (GetClientTeam(client) == CS_TEAM_CT && !g_bLastRequest) {
			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if (iWeapon != -1) {
				char sWeapon[32];
				GetEdictClassname(iWeapon, STRING(sWeapon));
				
				if (StrContains(sWeapon, "taser") != -1) {
					if (buttons & IN_ATTACK && !bajail[client].g_bClickLocker && !g_bLRWait && g_iPlayerStuff[client].TAZER) {
						if (Tazing(client)) bajail[client].g_bClickLocker = true;
						
						if (!g_iPlayerStuff[client].TAZER) {
							RemovePlayerItem(client, iWeapon);
							RemoveEdict(iWeapon);
							if ((iWeapon = GetPlayerWeaponSlot(client, 2)) != -1) {
								RemovePlayerItem(client, iWeapon);
								RemoveEdict(iWeapon);
							}
							GivePlayerItemAny(client, "weapon_knife");
						}
					}
					else if (buttons & IN_ATTACK2)
					{					
						char format[64];
						Format(STRING(format), "Taser%s restant%s: %i", (g_iPlayerStuff[client].TAZER > 1 ? "s" : ""),(g_iPlayerStuff[client].TAZER > 1 ? "s" : ""), g_iPlayerStuff[client].TAZER);
						PrintHudMessage(client, format);
					}
					buttons &= ~IN_ATTACK;
					buttons &= ~IN_ATTACK2;
					return Plugin_Changed;
				}
			}
		}
	}
	else if (bajail[client].g_bClickLocker)
		bajail[client].g_bClickLocker = false;
	
	if (buttons & IN_USE && buttons & IN_ATTACK2 && GetClientTeam(client) == CS_TEAM_T && g_iPlayerStuff[client].REND && !bajail[client].g_bTazed && bajail[client].g_bReceptDone && !bajail[client].g_bRendLock && !bajail[client].g_bExploding && !g_bDernierCT) {
		g_iRendCounter[client]++;
		
		if (g_iRendCounter[client] == 22)
			Rending(client);
	}
	else
		g_iRendCounter[client] = 0;
	
	return Plugin_Continue;
}

public Action Timer_FreezeCooldown(Handle Timer, any client)  { 
	if (IsValidClient(client))
		bajail[client].g_bFreezeCooldown = false;
}

public Action Hook_NormalSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)  { 
	if (bajail[entity].g_bBadGrenade && StrContains(sample, "weapons/hegrenade/he_bounce", false) != -1) {
		SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
		SetEntProp(entity, Prop_Data, "m_takedamage", 2);
		SetEntProp(entity, Prop_Data, "m_iHealth", 1);
		SDKHooks_TakeDamage(entity, 0, 0, 1.0);
		bajail[entity].g_bBadGrenade = false;
		return Plugin_Handled;
	}
	else if (StrContains(sample, "weapons/flashbang/flashbang_explode2", false) != -1 || StrContains(sample, "weapons/flashbang/flashbang_explode1", false) != -1) { 
		return Plugin_Handled; 
	} 
	
	return Plugin_Continue; 
}

public Action Timer_PlayerJihad(Handle timer, any client) {
	if (IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_T && bajail[client].g_bExploding && bajail[client].g_bReceptDone)
		Detonate(client);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageCallback);
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUseCallback);
	SDKHook(client, SDKHook_WeaponEquip, WeaponPickCallback);
	g_hTimerHUD[client] = CreateTimer(1.0, Timer_HUDPanel, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
	bajail[client].g_bHUDStatus = true;
	if (g_hDatabase != null) {
		LoadData(client);
	}
	
	if(isModoTest(client) || isModo(client) || isAdmin(client) || isRooted(client) || isMe(client) || isResp(client)) 
		SetClientListeningFlags(client, VOICE_NORMAL);
	else 
		SetClientListeningFlags(client, VOICE_MUTED);
	
	g_iJour[client] = 1;
	/*bajail[g_indexDV[INDEX_T]].g_bHasPatateChaude[MAXPLAYERS + 1];
	g_bExploding[MAXPLAYERS+1] = false;
	g_bTazed[MAXPLAYERS+1] = false;
	g_bRending[MAXPLAYERS+1] = false;
	g_bReceptDone[MAXPLAYERS+1] = false;
	g_bWantsCaptain[MAXPLAYERS+1] = false;
	g_bWantsCaptainSecours[MAXPLAYERS+1] = false;
	g_bLastRequestPlayer[MAXPLAYERS+1] = false;
	g_bNeedClass[MAXPLAYERS+1] = false;
	g_bGardienChef[MAXPLAYERS+1] = false;
	g_bPlayerDied[MAXPLAYERS+1] = false;
	g_bFreezeCooldown[MAXPLAYERS+1] = false;
	g_bJailVIP[MAXPLAYERS+1] = false;
	g_bGotUSP[MAXPLAYERS+1] = false;
	g_bGotDeagle[MAXPLAYERS+1] = false;
	g_bLoaded[MAXPLAYERS+1] = false;
	g_bArmoryLeft[MAXPLAYERS+1] = false;
	g_bPlayerGiftLock[MAXPLAYERS+1] = false;
	g_bDropLock[MAXPLAYERS+1] = false;
	g_bFlashBonus[MAXPLAYERS+1] = false;
	g_bRendLock[MAXPLAYERS+1] = false;
	g_bDisconnecting[MAXPLAYERS+1] = false;
	g_bHUDStatus[MAXPLAYERS+1] = false;
	g_bClickLocker[MAXPLAYERS+1] = false;
	g_bBadGrenade[MAXENTITIES] = false;
	g_bClientIsAveugled[MAXPLAYERS+1] = false;
	g_bClientIsFrozen[MAXPLAYERS+1] = false;
	g_bClientIsParalyzed[MAXPLAYERS+1] = false;
	g_bIsKamikaze[MAXPLAYERS + 1] = false;
	g_NoDv[MAXPLAYERS + 1] = false;
	g_bisMembre[MAXPLAYERS + 1] = false;
	g_bIsFan[MAXPLAYERS + 1] = false;*/
}

public Action TakeDamageCallback(int client, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if (!IsValidClient(attacker, true) || !IsValidClient(client, true))
		return Plugin_Continue;
	
	if (g_iSavePos[client].STATUS || g_bRoundEnded || bajail[client].g_bRending || !bajail[client].g_bReceptDone && GetClientTeam(client) == CS_TEAM_T && IsInZone(client, "Jail") && g_iJailsCooldown && !g_bLRWait && !g_bLastRequest && !g_bLRDenied || g_bLRWait || g_bLRPause || !bajail[client].g_bLastRequestPlayer && g_bLastRequest) {
		damage = 0.0;		
		return Plugin_Changed;
	}	
	
	if (g_iCowboy[attacker].COWBOY && g_iCowboy[client].COWBOY) {	
		damage = 1000.0;		
		return Plugin_Changed;
	}
	
	if (g_iLastRequest.ROULETTE == 3) {	
		switch(GetRandomInt(1,5)) {
			case 1:damage = 1000.0;
			default:damage = 0.0;
		}
				
		return Plugin_Changed;
	}
	
	if(g_iLastRequest.AIM) {
		if(damagetype == DMG_FALL
		|| damagetype == DMG_GENERIC
		|| damagetype == DMG_CRUSH
		|| damagetype == DMG_SLASH
		|| damagetype == DMG_BURN
		|| damagetype == DMG_VEHICLE
		|| damagetype == DMG_FALL
		|| damagetype == DMG_BLAST
		|| damagetype == DMG_SHOCK
		|| damagetype == DMG_SONIC
		|| damagetype == DMG_ENERGYBEAM
		|| damagetype == DMG_DROWN
		|| damagetype == DMG_PARALYZE
		|| damagetype == DMG_NERVEGAS
		|| damagetype == DMG_POISON
		|| damagetype == DMG_ACID
		|| damagetype == DMG_AIRBOAT
		|| damagetype == DMG_PLASMA
		|| damagetype == DMG_RADIATION
		|| damagetype == DMG_SLOWBURN
		|| attacker == 0) {
			return Plugin_Handled;
		}
		else if(damagetype & CS_DMG_HEADSHOT) {
			damage = float(GetClientHealth(client) + GetClientArmor(client));
			return Plugin_Changed;
		}
		
		return Plugin_Handled;
	}
	
	if (g_iLastRequest.VIP) {	
		if(GetClientTeam(client) == CS_TEAM_CT) {
			damage = 0.0;
		}
				
		return Plugin_Changed;
	}
	
	if (inflictor && inflictor <= MaxClients) {
		char sWeapon[32];
		GetEdictClassname(GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon"), STRING(sWeapon));
		
		if (StrContains(sWeapon, "knife") != -1 && (damage >= 25.0 && damage <= 40 || damage == 90.0)) {
			switch (GetRandomInt(1, 3)) {
				case 1,2: {
					damage = 15.0;
				}
				
				case 3: {
					damage = 20.0;
				}
			}
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action WeaponPickCallback(int client, int entity) {
	if (g_iLastRequest.PATATE == 1) {
		char weaponName[80];
		GetEntityClassname(entity, STRING(weaponName));
		
		if (StrContains(weaponName, "deagle", false) != -1) {
			if(client == g_indexDV[INDEX_T]) {
				bajail[g_indexDV[INDEX_T]].g_bHasPatateChaude = true;
				bajail[g_indexDV[INDEX_CT]].g_bHasPatateChaude = false;
			} else {
				bajail[g_indexDV[INDEX_CT]].g_bHasPatateChaude = true;
				bajail[g_indexDV[INDEX_T]].g_bHasPatateChaude = false;
			}
		}
	}
}

public Action WeaponCanUseCallback(int client, int weapon) {
	if (!IsValidClient(client, true) || bajail[client].g_bDropLock)
		return Plugin_Continue;
	
	char weaponName[80], entityName[64];
	GetEntityClassname(weapon, STRING(weaponName));
	Entity_GetName(weapon, STRING(entityName));
	
	if ((StrContains(weaponName, "knife", false) == -1 && (!g_iPlayerStuff[client].REND && GetClientTeam(client) == CS_TEAM_T && !g_bLastRequest && !g_bLRDenied || g_iLastRequest.COUTEAU) ||
	(StrContains(weaponName, "awp", false) == -1 && StrContains(weaponName, "knife", false) == -1 && (g_iLastRequest.UNSCOPE == 1 || g_iLastRequest.SCOPE == 1)) ||
	(StrContains(weaponName, "ssg08", false) == -1 && StrContains(weaponName, "knife", false) == -1 && (g_iLastRequest.UNSCOPE == 2 || g_iLastRequest.SCOPE == 2)) ||
	((StrContains(weaponName, "m4a1", false) == -1 && StrContains(weaponName, "knife", false) == -1 && GetClientTeam(client) == CS_TEAM_CT || StrContains(weaponName, "awp", false) == -1 && StrContains(weaponName, "knife", false) == -1 && GetClientTeam(client) == CS_TEAM_T) && g_iLastRequest.BROCHETTE) ||
	(StrContains(weaponName, "m249", false) == -1 && StrContains(weaponName, "knife", false) == -1 && g_iLastRequest.ISOLOIR) ||
	(StrContains(weaponName, "he", false) == -1 && g_iLastRequest.GRENADE) ||
	(StrContains(weaponName, "flashbang", false) == -1 && g_iLastRequest.BALLE) ||
	(StrContains(weaponName, "deagle", false) == -1 && StrContains(weaponName, "knife", false) == -1 && (g_iLastRequest.LANCER || g_iLastRequest.BASKET || g_iLastRequest.COWBOY || g_iLastRequest.ROULETTE)) ||
	(g_bLastRequest && !bajail[client].g_bLastRequestPlayer || g_bLRPause || bajail[client].g_bTazed) ||
	(StrContains(entityName, "evil_deagle", false) != -1 && GetClientTeam(client) == CS_TEAM_CT) ||
	(GetClientTeam(client) == CS_TEAM_CT && StrContains(weaponName, g_sCanUseUnlock[client], false) == -1 && !g_bLastRequest && !g_bLRDenied && !g_bLRWait && !g_bDernierCT && IsInZone(client, "(T)") && (!IsInZone(client, "Armurerie") || IsInZone(client, "Armurerie") && bajail[client].g_bArmoryLeft)) ||
	(StrContains(weaponName, "flashbang", false) != -1 && (!isVip(client) || bajail[client].g_bFlashBonus) && StrContains("flashbang", g_sCanUseUnlock[client], false) == -1 || StrContains(weaponName, "taser", false) != -1) && StrContains("taser", g_sCanUseUnlock[client], false) == -1)) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
} 

public Action Timer_TazerRefresh(Handle timer, any client) {
	if (IsValidClient(client, true) && bajail[client].g_bTazed) {
		g_fTazerCount[client] -= 0.1;
		if (g_fTazerCount[client] > 0.0) {
			float entorigin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", entorigin);
			
			for (int i = 1; i < 8; i++)  {
				entorigin[2] += (i*9);	
				
				TE_SetupBeamRingPoint(entorigin, 45.0, 45.1, g_iBeamSprite2, g_iBeamSprite, 0, 1, 0.1, 8.0, 1.0, COLOR_TAZER, 1, 0);					
				TE_SendToAll();
				
				entorigin[2]-= (i*9);
			}
		}
		else {
			bajail[client].g_bTazed = false;
			SetEntityMoveType(client, MOVETYPE_WALK);
			GivePlayerItemAny(client, "weapon_knife_t");
			
			TrashTimer(g_hTazerTimer[client], true);
		}
	}
	else
		TrashTimer(g_hTazerTimer[client], true);
}

public void OnClientDisconnect(int client) {
	if (IsClientInGame(client)) {
		bajail[client].g_bDisconnecting = true;
		CheckEverything(client);
		
		if (g_hDatabase != null)
			SaveData(client);
		
		ResetClient(client);
		
		g_iSavePos[client].STATUS = 0;
		g_iPlayerStuff[client].POINTS = 0;
		bajail[client].g_bHUDStatus = false;
		bajail[client].g_bLoaded = false;
		g_iPlayerTeam[client] = 0;
		
		TrashTimer(g_hTimerHUD[client], true);
		
		SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUseCallback);
		SDKUnhook(client, SDKHook_OnTakeDamage, TakeDamageCallback);
		SDKUnhook(client, SDKHook_WeaponEquip, WeaponPickCallback);
		
		if (g_iLastRequest.VIP && client == g_indexDV[INDEX_VIP]) {
			int iPlayers[MAXPLAYERS + 1];
			int iPlayersCount;
			
			CPrintToChatAll("%s Le vip a deconnecté %N election d'un nouveau.", PREFIX, g_indexDV[INDEX_VIP]);
			LoopClients(i) {
				if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) {
					iPlayers[iPlayersCount++] = i;
				}
			}
			
			g_indexDV[INDEX_VIP] = iPlayers[GetRandomInt(0, iPlayersCount-1)];
			
			SetEntProp(g_indexDV[INDEX_VIP], Prop_Data, "m_takedamage", 2, 1);
			
			SetEntityModel(client, MODEL_VIP);
			SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_VIP);
			
			CPrintToChatAll("%s Le joueur %N est le VIP pour cette DV, Protégé le !", PREFIX, g_indexDV[INDEX_VIP]);
		}
	}
}

public Action Timer_HUDPanel(Handle timer, any client) {
	if (IsValidClient(client)) {		
		if (IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT && g_iLastRequest.ISOLOIR && GetTotalPlayer(3) > 1 && IsInZone(client, "Isoloir") && g_iTimelimit < 88) {
			DisarmClient(client);
			CPrintToChatAll("%s Le Gardien {lightblue}%N {default}est sorti de l'isoloir sans être le Dernier CT.", PREFIX, client);
			PerformSmite(client);	
		}
		
		if (IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT && !g_bLRWait && !g_bLastRequest && !g_bLRDenied && !g_bDernierCT && IsInZone(client, "Conduits")) {
			CPrintToChatAll("%s Le Gardien {lightblue}%N {default}est entré dans un conduit.", PREFIX, client);
			PerformSmite(client);	
		}
		
		if (!IsInZone(client, "Armurerie") && !bajail[client].g_bArmoryLeft && GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) && g_iJailsCooldown < (g_iJailTime - 2)) {
			bajail[client].g_bArmoryLeft = true;
		}
		
		if (IsInZone(client, "Armurerie") && bajail[client].g_bArmoryLeft && GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) && !g_bDernierCT && !g_bLRWait && !g_bLRDenied && !g_bLastRequest) {
			DisarmClient(client);
			CPrintToChatAll("%s Le Gardien {lightblue}%N {default}est retourné dans l'Armurerie !", PREFIX, client);
			PerformSmite(client);	
		}
		
		if (g_iLastRequest.VIP && client == g_indexDV[INDEX_VIP]) {
			if(IsInZone(g_indexDV[INDEX_VIP], "VipEscorte")) {
				CPrintToChat(client, "%s {darkred}%N {default}a raté sa DV. Les Cts peuvent l'abattre!", PREFIX, g_indexDV[INDEX_T]);
				ServerCommand("sm_freeze @t 20");
				SetEntProp(g_indexDV[INDEX_T], Prop_Data, "m_takedamage", 2, 1);
				DisarmClient(g_indexDV[INDEX_T]);
				LoopClients(i) {
					if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) {
						SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
						GivePlayerItemAny(i, "weapon_m4a4");
						GivePlayerItemAny(i, "weapon_deagle");
						GivePlayerItemAny(i, "weapon_knife");
					}
				}
			}
		}
		
		char sNameCap[64];
		LoopClients(i) 
		{
			if(IsValidClient(i) && GetClientTeam(i) == CS_TEAM_CT && bajail[i].g_bGardienChef)
			{
				GetClientName(i, STRING(sNameCap));
				if(!IsPlayerAlive(i))
					sNameCap = "Décédé";
			}	
		}
		
		GetZoneName(client);
		
		int maxCredits[MAXPLAYERS + 1];
		if(isVipPlus(client))
			maxCredits[client] = LIMIT_POINT_VIPPLUS;
		else if(isVip(client))
			maxCredits[client] = LIMIT_POINT_VIP;
		else
			maxCredits[client] = LIMIT_POINT;
		
		if (strlen(sNameCap) == 0) {
			sNameCap = "Aucun";
		}
		
		if(bajail[client].g_bHUDStatus) 
		{
			if(g_hCheckChef != null) 
				PrintHintText(client, "     <font color='#0363ff'>Enemy-Down</font>\nCapitaine: Elections en cours\nCrédits: %i", g_iPlayerStuff[client].POINTS);
			else 
				PrintHintText(client, "     <font color='#0363ff'>Enemy-Down</font>\nCapitaine: %s\nCrédits: %i", sNameCap, g_iPlayerStuff[client].POINTS);
		}	
	}
	else if (!IsValidClient(client)) {
		TrashTimer(g_hTimerHUD[client], true);
	}
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast) 
{
	if (!dontBroadcast) {
		char sName[33];
		event.GetString("name", STRING(sName));
		
		Event hEvent = CreateEvent("player_connect", true);
		hEvent.SetString("name", sName);
		hEvent.SetInt("index", event.GetInt("index"));
		hEvent.SetInt("userid", event.GetInt("userid"));		
		hEvent.Fire(true);
		
		CPrintToChatAll("%s Le joueur {orange}%s {default}vient de se connecter.", PREFIX, sName);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}


public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	if (!dontBroadcast) {
		char sName[33];
		event.GetString("name", STRING(sName));
		
		Event hEvent = CreateEvent("player_disconnect", true);
		hEvent.SetInt("userid", event.GetInt("userid"));
		hEvent.SetString("name", sName);
		
		hEvent.Fire(true);
		
		CPrintToChatAll("%s Le joueur {orange}%s {default}vient de se déconnecter.", PREFIX, sName);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Timer_CheckChef(Handle timer) 
{
	if (GetTotalPlayer(3) > 1 && GetTotalPlayer(2) > 1) 
	{
		if (g_bChoixAleatoire || g_bChoixAleatoireSecours) 
		{
			int iPlayers[MAXPLAYERS + 1];
			int iPlayersCount;
			
			LoopClients(i) 
			{
				if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT && (bajail[i].g_bWantsCaptain || bajail[i].g_bWantsCaptainSecours && !g_bChoixAleatoire)) 
				{
					iPlayers[iPlayersCount++] = i;
				}
			}
			
			int client = iPlayers[GetRandomInt(0, iPlayersCount-1)];	
			
			CPrintToChatAll("%s Le Chef des Gardiens est {lightblue}%N{default} !", PREFIX, client);
			if (isVip(client)) {
				SetEntityModel(client, MODEL_CHEF2);
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_CHEF2);
			}
			else {
				SetEntityModel(client, MODEL_CHEF1);
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_CHEF1);
			}
			bajail[client].g_bGardienChef = true;
			SetEntityHealth(client, GetClientHealth(client) + 10);
		}
		else {
			CPrintToChatAll("%s Aucun chef, les Prisonniers auront {green}Quartier Libre {default}!", PREFIX);				
			g_bNoChef = true;
		}
	}
	
	g_hCheckChef = null;
	
	return Plugin_Continue;
}

public Action Timer_Global(Handle timer) {
	for(int i = 1; i <= 2048; i++) {
		char entName[64];
		
		if(IsValidEntity(i))
			Entity_GetName(i, STRING(entName));
		if(StrContains(entName, "ballon") != -1) {
			if (!IsInZone(i, "Terrain")) TeleportEntity(i, g_fCentreStade, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	LoopClients(i) {
		if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_T && !bajail[i].g_bReceptDone && (IsInZone(i, "(T)") || !g_iJailsCooldown) && !g_bLastRequest && !g_bLRWait && !g_bLRDenied) {
			bajail[i].g_bReceptDone = true;
		}
		if (IsValidClient(i, true) && !g_bLastRequest) {
			if (g_fGravity[i])
				SetEntityGravity(i, g_fGravity[i]);
			else if (g_PlayerBonus[i].Gravity)
				SetEntityGravity(i, BONUS_GRAVITY); 
		}
		
		if (IsValidClient(i)) {
			Change_Tag(i);
			if(isModoTest(i) || isModo(i) || isAdmin(i) || isRooted(i) || isMe(i) || isResp(i))
				SetClientListeningFlags(i, VOICE_NORMAL);
		}
	}
	
	if(g_bPlaying) {
		g_iSec++;
		if(g_iSec >= 60) {
			g_iMin++;
			g_iSec = 0;
		}
	}
	
	if (!g_bPlaying && GetTeamClientCount(2) && GetTeamClientCount(3) || g_bPlaying && (!GetTeamClientCount(2) || !GetTeamClientCount(3))) {
		if (!g_bPlaying) {
			ServerCommand("sm_rcon mp_ignore_round_win_conditions %d", g_bPlaying);
			CS_TerminateRound(1.0, CSRoundEnd_GameStart);
		}
		else {
			CS_TerminateRound(1.0, CSRoundEnd_Draw);
			ServerCommand("sm_rcon mp_ignore_round_win_conditions %d", g_bPlaying);
		}
		
		g_bPlaying = !g_bPlaying;
		CPrintToChatAll("%s %s de la partie..", PREFIX, (g_bPlaying ? "Initialisation" : "Fermeture"));
	}
	
	if (g_iDVTimer > 0) {
		int client;
		LoopClients(i) {
			if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_T) {
				client = i;
				break;
			}
		}
		
		g_iDVTimer--;
		if (IsValidClient(client, true)) {
			if (g_iDVTimer == 20 || g_iDVTimer == 5)
				CPrintToChatAll("%s {darkred}%N {default}a {lime}%d {default}secondes pour choisir.", PREFIX, client, g_iDVTimer);
			else if (!g_iDVTimer) {
				SetEntityMoveType(client, MOVETYPE_WALK);
				DisarmClient(client);
				PerformSmite(client);
				
				CPrintToChatAll("%s {darkred}%N {default}a été trop long pour choisir.", PREFIX, client);
			}
		}
	}
	
	if (g_iJailsCooldown) {
		g_iJailsCooldown--;
		
		if (!g_iJailsCooldown) {
			CPrintToChatAll("%s Les Cellules ont été ouvertes automatiquement !", PREFIX); 
			if(!g_bQr) {
				CPrintToChatAll("%s Les Prisonniers ont {green}quartier libre {default}!", PREFIX);
				EmitSoundToAll(SOUND_QL, _, _, _, _, 0.1);
			}
			
			PrintHudMessageAll("Cellules ouvertes automatiquement");
			g_bQuartierLibre = true;
			
			CheckEverything(-1);
			
			CheckTheGame();	
			
			if (ReadPosition("button")) {
				int iEntity;
				float fEntityPos[3];
				
				while ((iEntity = FindEntityByClassname(iEntity, "func_button")) != -1) {			
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityPos);
					
					if (fEntityPos[0] == g_fReadPos[0][0] && fEntityPos[1] == g_fReadPos[0][1] && fEntityPos[2] == g_fReadPos[0][2]) {
						AcceptEntityInput(iEntity, "Press", -1, -1);
						Entity_Lock(iEntity);
					}
				}
			}
			
			LoopClients(i) {
				if (IsValidClient(i, true)) {
					SetClientListeningFlags(i, VOICE_NORMAL);
				}
			}
		}
	}	
	
	if (g_iTimelimit && g_bPlaying) {
		g_iTimelimit--;
		
		if (g_iTimelimit == 30) {
			if (!g_bLastRequest) {
				CPrintToChatAll("%s Il ne reste que {lime}30 {default}secondes !", PREFIX);
				EmitSoundToAll(SOUND_TIMEWARNING, _, _, _, _, 0.1);
			}
			else
				CPrintToChatAll("%s Il reste {lime}30 {default}secondes pour finir cette DV !", PREFIX);
		}
		else if(g_iTimelimit == 590) {
			g_bArmuIsCt = false;
		}
		else if (!g_iTimelimit) {
			LoopClients(i) {
				if (IsValidClient(i) && g_iPlayerBet[i].AMOUNT) {
					CPrintToChat(i, "%s Vos {lime}%i {default}points vous ont été rendus.", PREFIX, g_iPlayerBet[i].AMOUNT);
					g_iPlayerStuff[i].POINTS += g_iPlayerBet[i].AMOUNT;
					g_iPlayerBet[i].AMOUNT = 0;
				}
			}
			CPrintToChatAll("%s La limite de temps a été atteinte !", PREFIX);
			CS_TerminateRound(3.0, CSRoundEnd_Draw);			
		}
	}
	
	if (g_iCowboyTimer) {
		g_iCowboyTimer--;
		
		if (!g_iCowboyTimer) {
			int iCount = GetRandomInt(3, 7);
			
			if(g_iCowboyTimer == 0) EmitSoundToAll(SOUND_PANPAN, _, _, _, _, 0.1);
			
			LoopClients(i) {
				if (IsValidClient(i, true) && g_iCowboy[i].COWBOY) {
					switch (GetRandomInt(1, 3)) {
						case 1: {
							g_iCowboy[i].MRB = iCount;
						}
						
						case 2: {
							g_iCowboy[i].USE = iCount;
						}
						
						case 3: {
							g_iCowboy[i].CROUCH = iCount;
						}
					}
					
					char format[64];
					Format(STRING(format), "Appuie %ix sur %s !", g_iCowboy[i].MRB + g_iCowboy[i].USE + g_iCowboy[i].CROUCH, (g_iCowboy[i].MRB ? "CLIC DROIT" : (g_iCowboy[i].USE ? "UTILISER" : "ACCROUPI")));
					PrintHudMessage(i, format);
				}
			}
		}
	}
	else if (g_iLastRequest.COWBOY) {
		LoopClients(i) {
			if (IsValidClient(i, true) && g_iCowboy[i].COWBOY && !g_iCowboy[i].WIN) 
			{
				char display[80];
				Format(STRING(display), "Appuie %ix sur %s !", g_iCowboy[i].MRB + g_iCowboy[i].USE + g_iCowboy[i].CROUCH, (g_iCowboy[i].MRB ? "CLIC DROIT" : (g_iCowboy[i].USE ? "UTILISER" : "ACCROUPI")));
				PrintHudMessage(i, display);
			}
		}
	}
}

public void Frame_GetJihad(int client) { 
	int iPlayers[MAXPLAYERS + 1];
	int iPlayersCount;
	
	LoopClients(i) {
		if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T) {
			iPlayers[iPlayersCount++] = i;
		}
	}
	
	client = iPlayers[GetRandomInt(0, iPlayersCount - 1)];	
	
	if (IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_T) {
		GivePlayerItemAny(client, "weapon_c4");
		bajail[client].g_bIsKamikaze = true;
		CPrintToChat(client, "%s Vous êtes un {darkred}kamikaze{default}, attendez le bon moment !", PREFIX);
	}
	
	LoopClients(i) {
		if (IsValidClient(i, true) && GetClientTeam(client) == CS_TEAM_T && i != client) {
			CPrintToChat(i, "%s Il y a un {darkred}kamikaze {default}parmi nous !", PREFIX);
		}
	}
	
	EmitSoundToAll("buttons/button4.wav", _, _, _, _, 0.1);
}

int GetChef(bool bSecours = false) 
{ 
	int iPlayers[MAXPLAYERS+1];
	int iPlayersCount;
	
	LoopClients(i) 
	{
		if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT && (bajail[i].g_bWantsCaptain && !bSecours || bajail[i].g_bWantsCaptainSecours && bSecours) && !bajail[i].g_bDisconnecting) 
		{
			iPlayers[iPlayersCount++] = i;
		}
	}
	
	int client = iPlayers[GetRandomInt(0, iPlayersCount - 1)];	
	
	if(IsValidClient(client))
		CPrintToChatAll("%s Le nouveau chef est {lightblue}%N {default}!", PREFIX, client);
		
	if (isVip(client)) {
		SetEntityModel(client, MODEL_CHEF2);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_CHEF2);
	}
	else {
		SetEntityModel(client, MODEL_CHEF1);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS_CHEF1);
	}
	bajail[client].g_bGardienChef = true;
	
	return iPlayersCount;
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrEqual(classname, "hegrenade_projectile") && g_iLastRequest.GRENADE)
		CreateTimer(0.0, Timer_GrenadeInit, entity, TIMER_FLAG_NO_MAPCHANGE);
	else if (StrEqual(classname, "flashbang_projectile") && !g_bLastRequest)
		CreateTimer(0.95, Timer_FlashbangTeleport, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_GrenadeInit(Handle timer, any entity) 
{
	if (entity == INVALID_ENT_REFERENCE || !IsValidEdict(entity) || !IsValidEntity(entity))
		return;
	
	SDKHook(entity, SDKHook_TouchPost, OnGrenadeImpactTouchPost);
	
	bajail[entity].g_bBadGrenade = true;
	
	int client = GetEntDataEnt2(entity, FindSendPropInfo("CBaseGrenade", "m_hThrower"));
	
	if (!IsValidClient(client, true))
		return;	
	
	CreateTimer(1.0, Timer_NewGrenade, client);
	BeamFollowCreate(entity, (GetClientTeam(client) == CS_TEAM_T ? COLOR_GRENADE_T : COLOR_GRENADE_CT));
}

public void OnGrenadeImpactTouchPost(int iGrenade, int iOther) {
    if (!iOther) {
		SetEntProp(iGrenade, Prop_Data, "m_takedamage", 2);
		SetEntProp(iGrenade, Prop_Data, "m_iHealth", 1);

		SDKHooks_TakeDamage(iGrenade, iGrenade, iGrenade, 10.0);
    }
    else {
        if (GetEntProp(iOther, Prop_Send, "m_nSolidType", 1) && !(GetEntProp(iOther, Prop_Send, "m_usSolidFlags", 2) & 0x0004)) {
            int iOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");

            if (iOwner != iOther) 
            {
			SetEntProp(iGrenade, Prop_Data, "m_takedamage", 2);
			SetEntProp(iGrenade, Prop_Data, "m_iHealth", 1);
			SDKHooks_TakeDamage(iGrenade, iGrenade, iGrenade, 10.0);
            }
        }
    }
}

public Action Timer_NewGrenade(Handle timer, any client) {
	if (IsValidClient(client, true) && g_iLastRequest.GRENADE && GetPlayerWeaponSlot(client, 3) == -1)
		GivePlayerItemAny(client, "weapon_hegrenade");
}

void BeamFollowCreate(int entity, int color[4]) {
	TE_SetupBeamFollow(entity, g_iBeamSprite3,	0, 1.0, 10.0, 10.0, 5, color);
	TE_SendToAll();
}

public void OnClientPostAdminCheck(int client)
{	
	CreateTimer(2.0, ClientConnectIntro, client);
}

public Action ClientConnectIntro(Handle timer, any client)
{
	if(IsValidClient(client))
	{
		CPrintToChat(client, "{darkred}▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");								   
		CPrintToChat(client, "{yellow}◾️ {default}Bienvenue sur notre serveur Ba-Jail");
		CPrintToChat(client, "{yellow}◾️ {default}Discord: {lightblue}%s", DISCORD_URL);
		CPrintToChat(client, "{yellow}◾️ {default}Site: {lightblue}%s", WEB_URL);	
		CPrintToChat(client, "{darkred}▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
		
		PrecacheSound("enemy-down/jail/intro.mp3");
		EmitSoundToClient(client, "enemy-down/jail/intro.mp3", client, _, _, _, 0.5);
	}	
}
