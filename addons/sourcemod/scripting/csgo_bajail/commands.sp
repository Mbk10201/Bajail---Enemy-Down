/*
    ______                                          __    
   / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
  / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
 / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  ) 
 \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/  
                                                         
*/

public Action Command_TestHudMsg(int client, int args)
{
	PrintHudMessage(client, "Test");
}	

public Action Command_Spectate(int client, int args) {
	if (IsValidClient(client, true))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Command_ViewWeapon(int client, const char []command, int argc) {
	if (!IsValidClient(client, true))
		return Plugin_Continue;

	float clientpos[3];
	GetClientAbsOrigin(client, clientpos);
	clientpos[2] -= 42;

	int randomx = GetRandomInt(-500, 500);
	int randomy = GetRandomInt(-500, 500);

	float startpos[3];
	startpos[0] = clientpos[0] + randomx;
	startpos[1] = clientpos[1] + randomy;
	startpos[2] = clientpos[2] + 1600;

	SetEntProp(client, Prop_Send, "m_fEffects", GetEntProp(client, Prop_Send, "m_fEffects") ^ 4);
	EmitAmbientSound(SOUND_LUMIERE, startpos, client, SNDLEVEL_NORMAL);
	
	return Plugin_Handled;
}

public Action Command_Qr(int client, int args) {
	if (g_bPlaying) {
		if(g_iCdrQr == 0) {
			if(bajail[client].g_bGardienChef && GetTotalPlayer(CS_TEAM_CT, true) <= GetTotalPlayer(CS_TEAM_T, true) && g_iJailsCooldown)
				MenuQr(client);
			else
				CPrintToChat(client, "%s Vous ne remplissez pas les conditions requises !", PREFIX);
		}
		else CPrintToChat(client, "%s L'ordre quartier restreint sera disponible dans %d round%s.", PREFIX, g_iCdrQr, (g_iCdrQr > 1 ? "s" : ""));
	}
}

void MenuQr(int client) {
	Menu menu = new Menu(MenuHandler_OrderQr);

	menu.SetTitle("Où voulez-vous effectuer le quartier restreint ?");
	menu.AddItem("piscine", "Piscine");
	menu.AddItem("vestiaires", "Vestiaires et douche");
	menu.AddItem("foot", "Foot");
	menu.AddItem("garage", "Garage");
	menu.AddItem("infirmerie", "Infirmerie");

	menu.ExitButton = true;

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_OrderQr(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {		
		char info[512];		
		GetMenuItem(menu, param2, STRING(info));
		
		if (IsValidClient(client, true) && GetTotalPlayer(CS_TEAM_CT, true) <= GetTotalPlayer(CS_TEAM_T, true) && bajail[client].g_bGardienChef && g_iJailsCooldown) {
			if (ReadPosition(info)) {
				LoopClients(i) {
					if(IsValidClient(i, true)) {
						if(GetClientTeam(i) == CS_TEAM_CT) TeleportEntity(i, g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
						else bajail[i].g_NoDv = true;
					}
				}
				
				g_iJailsCooldown = 1;
				g_bQr = true;
				g_iCdrQr = 6;
				CPrintToChatAll("%s L'ordre est quartier restreint %s.", PREFIX, info);
				
				char format[128];
				Format(STRING(format), "-- L'ordre est quartier restreint %s --", info);	
				PrintHudMessageAll(format);
				
				EmitSoundToAll(SOUND_QR, _, _, _, _, 0.1);
			}
			else {
				MenuQr(client);
				CPrintToChat(client, "%s La zone %s n'a pas été correctement configurée veuillez contacter MBK / Nevada pour lui en faire part.", PREFIX, info);
			}
		}
		else {
			CPrintToChat(client, "%s Vous ne remplissez pas les conditions requises !", PREFIX);
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action Command_JoinClass(int client, int args) {
	if (g_bPlaying) {
		if (IsValidClient(client, true))
			return Plugin_Handled;
		
		if (!g_iJailsCooldown) {
			FakeClientCommandEx(client, "spec_mode");
			bajail[client].g_bNeedClass = true;			
			return Plugin_Handled;
		}
		else if (GetTotalPlayer(3) && GetTotalPlayer(2) && !bajail[client].g_bPlayerDied) {
			CS_RespawnPlayer(client);		
			return Plugin_Handled;
		}
	}
	else {
		if (IsValidClient(client, true))
			return Plugin_Handled;

		CS_RespawnPlayer(client);	
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Command_Drop(int client, int args) {
	if (IsValidClient(client, true)) {
		char sWeapon[64];
		GetClientWeapon(client, STRING(sWeapon));
		if(g_iLastRequest.ROULETTE || g_iLastRequest.COWBOY) {
			return Plugin_Handled;
		}
		if(StrContains(sWeapon, "taser", false) != -1 && GetClientTeam(client) == CS_TEAM_CT) {
			CPrintToChat(client, "%s Vous ne pouvez pas lâcher cette arme (%s).", PREFIX, sWeapon);
			EmitSoundToClient(client, SOUND_CTBAN);
			return Plugin_Handled;
		}
	}
		
	
	return Plugin_Continue;
}

public Action Command_JoinTeam(int client, const char[] command, int args) {
	if (!IsValidClient(client))
		return Plugin_Continue;
	
	char sTeamChoosen[5];
	GetCmdArg(1, STRING(sTeamChoosen));
	int iTeamChoosen = StringToInt(sTeamChoosen);
	int iDestination = -1;
	
	if (iTeamChoosen) {
		if (GetClientTeam(client) == iTeamChoosen) {
			if (g_iPlayerTeam[client] && g_iPlayerTeam[client] < 4) {
				CPrintToChat(client, "%s Vous avez annulé votre changement d'équipe.", PREFIX);
				g_iPlayerTeam[client] = 0;
			}
			return Plugin_Handled;
		}
		else if (iTeamChoosen > 1) {
			if (iTeamChoosen == 3 && CTBan_IsClientBanned(client)) {
				CPrintToChat(client, "{lightblue}[CTBan] {default}Vous êtes banni des Gardiens ! Faites une demande sur le forum pour y avoir de nouveau accès.", PREFIX);
				EmitSoundToClient(client, SOUND_CTBAN);
				return Plugin_Handled;	
			}
			iDestination = iTeamChoosen;
		}
		else if (iTeamChoosen == 1 && GetClientTeam(client) > 1) {
			bool bDied = false;
			if (bajail[client].g_bPlayerDied) bDied = true;
			PerformSmite(client);
			ChangeClientTeam(client, 1);
			g_iPlayerTeam[client] = 0;
			if (!bDied) bajail[client].g_bPlayerDied = false;
			return Plugin_Handled;	
		}
		else {
			return Plugin_Continue;
		}
	}
	else if (GetClientTeam(client) >= CS_TEAM_T) {
		return Plugin_Handled;
	}
	else if (CTBan_IsClientBanned(client)) {
		CPrintToChat(client, "{lightblue}[CTBan] {default}Vous êtes banni des Gardiens ! Faites une demande sur le forum pour y avoir de nouveau accès.", PREFIX);
		EmitSoundToClient(client, SOUND_CTBAN);
		return Plugin_Handled;	
	}

	if (iDestination != -1 && GetClientTeam(client) > 1) {
		if (g_bPlaying && !g_iJailsCooldown) {
			g_iPlayerTeam[client] = iDestination;
			CPrintToChat(client, "%s Vous changerez d'équipe à la fin du round.", PREFIX);
		}
		else {
			if (!bajail[client].g_bPlayerDied) RequestFrame(Frame_Respawn, client);
			PerformSmite(client);
			CS_SwitchTeam(client, iDestination);
		}
		return Plugin_Handled;
	}
	else if (iDestination != -1) {
		CS_SwitchTeam(client, iDestination);
		if (!g_bPlaying || (g_iJailsCooldown && !bajail[client].g_bPlayerDied)) RequestFrame(Frame_Respawn, client);
		return Plugin_Handled;	
	}
	
	return Plugin_Continue;
}

public Action Command_Say(int client, int args) {
	if (IsValidClient(client) || IsValidClient(client, true)) {
		char sText[512];
		GetCmdArgString(STRING(sText));
		StripQuotes(sText);
		TrimString(sText);
	
		if (strcmp(sText, " ") == 0 || strcmp(sText, "") == 0 || strlen(sText) == 0 || StrContains(sText, "!") == 0)
			return Plugin_Handled;
		
		if (StrContains(sText, "@") == 0 || StrContains(sText, "/") == 0 || StrContains(sText, "@@@") == 0)
			return Plugin_Continue;
	
		if(g_iSavePos[client].STATUS == 4) {
			SavePosition(sText, g_fSavePos[client][0], g_fSavePos[client][1], g_fSavePos[client][2]);
		
			CPrintToChat(client, "%s Positions pour {orange}%s {default}sauvegardées !", PREFIX, sText);
			g_iSavePos[client].STATUS = 0;
		} else {
			if (GetClientTeam(client) == CS_TEAM_SPECTATOR) {
				if (isMe(client))CPrintToChatAll("{grey}[Spectateur] {lightblue}«{darkred}Fondateur{lightblue}»{green} %N {default}➝ %s", client, sText);
				else if (isResp(client))CPrintToChatAll("{grey}[Spectateur] {lightblue}«\x09Responsable{lightblue}»{green} %N {default}➝ %s", client, sText);
				else if (isMappeur(client))CPrintToChatAll("{grey}[Spectateur] \x08«\x05Mappeur\x08»{green} %N {default}: %s", client, sText);
				else if (isModoTest(client))CPrintToChatAll("{grey}[Spectateur] {lightgreen}«{olive}Modérateur Test{lightgreen}»{green} %N {default}: %s", client, sText);
				else if (isModo(client))CPrintToChatAll("{grey}[Spectateur] {lightgreen}«{olive}Modérateur{lightgreen}»{green} %N {default}: %s", client, sText);
				else if (isAdmin(client))CPrintToChatAll("{grey}[Spectateur] {olive}«{lightgreen}Admin{olive}»{green} %N {default}: %s", client, sText);
				else if (isVipPlus(client))CPrintToChatAll("{grey}[Spectateur] {lightblue}«{darkred}۷ìㄕ+ツ{lightblue}»{green} %N {default}: %s", client, sText);
				else if (isVip(client))CPrintToChatAll("{grey}[Spectateur] {lightblue}«{yellow}★VIP★{lightblue}»{green} %N {default}: %s", client, sText);
				else CPrintToChatAll("{grey}[Spectateur] {green}%N {default}: %s", client, sText);
			}
			else {
				if (isMe(client))CPrintToChatAll("%s{lightblue}«{darkred}Fondateur{lightblue}»{green} %N {default}➝ %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else if (isResp(client))CPrintToChatAll("%s{lightblue}«\x09Responsable{lightblue}»{green} %N {default}➝ %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else if (isMappeur(client))CPrintToChatAll("%s\x08«\x05Mappeur\x08»{green} %N {default}: %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else if (isModoTest(client))CPrintToChatAll("%s{lightgreen}«{olive}Modérateur Test{lightgreen}»{green} %N {default}: %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else if (isModo(client))CPrintToChatAll("%s{lightgreen}«{olive}Modérateur{lightgreen}»{green} %N {default}: %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else if (isAdmin(client))CPrintToChatAll("%s{olive}«{lightgreen}Admin{olive}»{green} %N {default}: %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else if (isVipPlus(client))CPrintToChatAll("%s{lightblue}«{darkred}۷ìㄕ+ツ{lightblue}»{green} %N {default}: %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else if (isVip(client))CPrintToChatAll("%s{lightblue}«{yellow}★VIP★{lightblue}»{green} %N {default}: %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else if (bajail[client].g_bGardienChef)CPrintToChatAll("%s{green}[{lightblue}Capitaine{green}]{green} %N {default}: %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), client, sText);
				else CPrintToChatAll("%s%s{green}%N {default}: %s", (!IsPlayerAlive(client) ? "{grey}*Mort* " : ""), (GetClientTeam(client) == CS_TEAM_T ? "{grey}[{darkred}Détenu{grey}] " : "{grey}[{lightblue}Gardien{grey}] "), client, sText);
			}
		}
	}

	return Plugin_Handled;
}

public Action Command_SayTeam(int client, int args) {
	if (IsValidClient(client) && !IsPlayerAlive(client)) return Plugin_Handled;
	else return Plugin_Continue;
}

public Action Command_ResetRound(int client, int args) {	
	CS_TerminateRound(1.0, CSRoundEnd_Draw);
	
	CPrintToChatAll("%s Le round va être restart", PREFIX);
}

public Action Command_Spec(int client, int args) {
	if (args != 1) {
		CPrintToChat(client, "%s {orange}!spec <NOM> {default}| Switch un joueur en Spectateur.", PREFIX);
		return Plugin_Handled;
	}
	
	char sTarget[50];
	GetCmdArg(1, STRING(sTarget));
	
	int target = FindTarget(client, sTarget);

	if (IsValidClient(target) && GetClientTeam(target) > 1) {
		CPrintToChatAll("%s {%s}%N {default}a été switch en {grey}Spectateur{default}.", PREFIX, GetClientTeam(target) == 2 ? "red" : "blue", target);
		bool bDied = false;
		if (bajail[target].g_bPlayerDied) bDied = true;
		PerformSmite(target);
		ChangeClientTeam(target, 1);		
		if (!bDied) bajail[target].g_bPlayerDied = false;
	}
	else
		CPrintToChat(client, "%s Ce joueur n'est dans aucune équipe.", PREFIX);
	
	return Plugin_Handled;
}

public Action Command_Afk(int client, int args) {
	if (IsValidClient(client) && GetClientTeam(client) != 1) {
		CPrintToChatAll("%s {%s}%N {default}est maintenant {grey}AFK{default}!", PREFIX, GetClientTeam(client) == CS_TEAM_T ? "red" : "blue", client);
		PerformSmite(client);
		ChangeClientTeam(client, 1);		
	}
	else
		CPrintToChat(client, "%s Vous êtes déjà en spectateur.", PREFIX);
	
	return Plugin_Handled;
}

public Action Command_Switch(int client, int args) {
	if (args != 1) {
		CPrintToChat(client, "%s {orange}!switch <NOM> {default}| Switch un joueur d'équipe.", PREFIX);
		return Plugin_Handled;
	}
	
	char sTarget[50];
	GetCmdArg(1, STRING(sTarget));
	
	int target = FindTarget(client, sTarget);

	if (IsValidClient(target) && GetClientTeam(target) > 1) {
		if (GetClientTeam(target) == 2 && CTBan_IsClientBanned(target)) {
			CPrintToChat(client, "%s {darkred}%N {default}est banni des Gardiens.");
			return Plugin_Handled;
		}
		if (!g_bPlaying || g_iJailsCooldown) {
			CPrintToChatAll("%s {%s}%N {default}a été switch en {%s}%s{default}.", PREFIX, GetClientTeam(target) == 2 ? "red" : "blue", target, GetClientTeam(target) == 2 ? "blue" : "red", GetClientTeam(target) == 2 ? "Gardien" : "Prisonnier");
			CS_SwitchTeam(target, GetClientTeam(target) == 2 ? 3 : 2);
			RequestFrame(Frame_Respawn, target);
		}
		else {
			CPrintToChatAll("%s {%s}%N {default}sera switch en {%s}%s{default}.", PREFIX, GetClientTeam(target) == 2 ? "red" : "blue", target, GetClientTeam(target) == 2 ? "blue" : "red", GetClientTeam(target) == 2 ? "Gardien" : "Prisonnier");
			g_iPlayerTeam[target] = GetClientTeam(target) == 2 ? 5 : 4;
		}
	}
	else
		CPrintToChat(client, "%s Ce joueur n'est dans aucune équipe.", PREFIX);
	
	return Plugin_Handled;
}

public Action Command_Respawn(int client, int args) {
	if (args != 1) {
		CPrintToChat(client, "%s {orange}!respawn <NOM> {default}| Respawn un joueur.", PREFIX);
		return Plugin_Handled;
	}
	
	char sTarget[50];
	GetCmdArg(1, STRING(sTarget));
	
	if(StrEqual(sTarget, "@all"))
	{
		LoopClients(i)
		{	
			if (!IsValidClient(client) && IsPlayerAlive(client))
				continue;
			
			CS_RespawnPlayer(i);
			CPrintToChat(i, "%s Vous avez été respawn.", PREFIX);
			return Plugin_Handled;
		}
	}
	
	int target = FindTarget(client, sTarget);

	if (IsValidClient(target) && GetClientTeam(target) > 1) {
			CPrintToChatAll("%s {%s}%N {default}a été respawn{default}.", PREFIX, GetClientTeam(target) == 2 ? "red" : "blue", target);
			RequestFrame(Frame_Respawn, target);
			TeleportEntity(target, g_fDeathPosition[target], NULL_VECTOR, NULL_VECTOR);
	}
	else
		CPrintToChat(client, "%s Ce joueur n'est dans aucune équipe.", PREFIX);
	
	return Plugin_Handled;
}

public Action Command_SavePos(int client, int args) {
	if (IsPlayerAlive(client)) {
		if (!g_iSavePos[client].STATUS) {
			g_iSavePos[client].STATUS = 1;
			CPrintToChat(client, "%s Définissez la position du {darkred}Prisonnier{default}.", PREFIX);	
		}
		else {
			g_iSavePos[client].STATUS = 0;
			CPrintToChat(client, "%s Procédure SavePos annulée.", PREFIX);		
		}
	}
	else
		CPrintToChat(client, "%s Vous devez être en vie.", PREFIX);

	return Plugin_Handled;
}

public Action Command_JailTime(int client, int args) {
	if (!args) {
		ReplyToCommand(client, "[SM] Usage: sm_jailtime <time>");
		return Plugin_Handled;
	}   

	char sValue[512];
	GetCmdArgString(STRING(sValue));
	StripQuotes(sValue);
	TrimString(sValue);

	SaveJailtime(StringToInt(sValue));
	CPrintToChat(client, "%s JailTime défini à {lime}%s {default}secondes.", PREFIX, sValue);

	return Plugin_Handled;
}

public Action Command_Tokens(int client, int args) {
	if(args < 2) {
		CPrintToChat(client, "%s sm_tokens <NOM> <MONTANT>", PREFIX);
		return Plugin_Handled;
	}
	
	char buffer[100];
	GetCmdArg(1, STRING(buffer));
	int target = FindTarget(client, buffer, true, false);
	if (target == -1)	return Plugin_Handled;
	
	GetCmdArg(2, STRING(buffer));
	int amount = StringToInt(buffer);
	if (amount < 1) return Plugin_Handled;
	
	int maxCredits[MAXPLAYERS + 1];
	
	if(isVipPlus(target))
		maxCredits[target] = LIMIT_POINT_VIPPLUS;
	else if(isVip(target))
		maxCredits[target] = LIMIT_POINT_VIP;
	else
		maxCredits[target] = LIMIT_POINT;

	if (g_iPlayerStuff[target].POINTS + amount > maxCredits[target]) {
		amount = maxCredits[target] - g_iPlayerStuff[target].POINTS;
		if (amount == 0) {
			CPrintToChat(client, "%s %N {lime}a déjà atteint la limite de points.", PREFIX, target);
			return Plugin_Handled;
		}
	}
	
	g_iPlayerStuff[target].POINTS += amount;
	CPrintToChat(client, "%s %N {lime}a bien reçu ses points supplémentaires.", PREFIX, target);
	CPrintToChat(target, "%s Vous venez d'obtenir {green}%i points {lime}gratuits.", PREFIX, amount);	
	
	return Plugin_Handled;
}

public Action Command_Plainte(int client, int args) {
	if (client && IsClientInGame(client)) {
		if (args < 1) {
			ReplyToCommand(client, "%s Utilisation: /plainte <message COMPLET>", PREFIX);
			return Plugin_Handled;
		}
		
		int timestamp;
		timestamp = GetTime();
		
		if ((timestamp - g_iPlainte[client]) < 60) {
			ReplyToCommand(client, "%s Vous devez attendre %i secondes avant de refaire une plainte", PREFIX, ( 60 - (timestamp - g_iPlainte[client])) );
			return Plugin_Handled;
		}
		
		g_iPlainte[client] = GetTime();
		char message[128];
		
		GetCmdArgString(STRING(message));
		
		LoopClients(i) {
			if (IsClientInGame(i) && (isModoTest(i) || isModo(i) || isAdmin(i) || isRooted(i))) {
				CPrintToChat(i, "%s Plainte de {darkred}%N : {lightblue}%s", PREFIX, client, message);
				EmitSoundToClient(i, SOUND_PLAINTE);
			}
		}
		
		CPrintToChat(client, "%s {green}Votre plainte a bien été envoyée, merci d'être patient.", PREFIX);
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_Gift(int client, int args) {
	if (IsValidClient(client)) {
		if (isVip(client)) {
			if (IsPlayerAlive(client)) {
				if (!g_bLastRequest) {
					if (g_iPlayerStuff[client].GIFT) {
						int health = GetClientHealth(client);
					
						if (GetClientTeam(client) == CS_TEAM_CT) {
							switch (GetRandomInt(1, 22)) {
								case 1: {
									CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
							
								case 2: {
									CPrintToChat(client, "%s {default}Vous avez gagné un {green}ensemble de choc{default}.", PREFIX);
									DisarmClient(client);
									GivePlayerItemAny(client, "weapon_ump45");
									GivePlayerItemAny(client, "weapon_elite");
									GivePlayerItemAny(client, "weapon_hegrenade");
									GivePlayerItemAny(client, "weapon_flashbang");
									GivePlayerItemAny(client, "weapon_smokegrenade");
									GivePlayerItemAny(client, "weapon_knife");
									GivePlayerItemAny(client, "weapon_taser");
									SetEntityHealth(client, health + 30);		
									if (health + 30 > 200)
											SetEntityHealth(client, 200);							
									if(g_iBonusSpeed[client] != 1) {
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + 0.2);
										g_iBonusSpeed[client]++;
									}
								}
							
								case 3: {
									if (health < 200) {
										CPrintToChat(client, "%s {default}Vous avez gagné {green}50HP{default}.", PREFIX);
										SetEntityHealth(client, health + 50);

										if (health + 50 > 200)
											SetEntityHealth(client, 200);
									} else
										CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
							
								case 4: {
									if (health < 200) {
										CPrintToChat(client, "%s {default}Vous avez gagné {green}25 HP{default}.", PREFIX);
										SetEntityHealth(client, health + 25);
										
										if (health + 25 > 200)
											SetEntityHealth(client, 200);
									} else
										CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
							
								case 5: {
									CPrintToChat(client, "%s {default}Vous avez perdu {green}30 HP{default}.", PREFIX);
									SetEntityHealth(client, health - 30);									
									if (health <= 0)
										SetEntityHealth(client, 1);
								}
							
								case 6: {
										CPrintToChat(client, "%s {default}Vous avez gagné une {green}flashbang{default}.", PREFIX);
										GivePlayerItemAny(client, "weapon_flashbang");
								}
							
								case 7: {
									CPrintToChat(client, "%s {default}Vous avez gagné une {green}fumigène{default}.", PREFIX);
									GivePlayerItemAny(client, "weapon_smokegrenade");
								}
							
								case 8: {
									if(g_iBonusSpeed[client] != 1) {
										CPrintToChat(client, "%s {default}Vous avez gagné de {green}la vitesse{default}.", PREFIX);
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + 0.2);
										g_iBonusSpeed[client]++;
									}
									else CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);	
								}
							
								case 9: {
									if(g_iBonusSpeed[client] != -1) {
										CPrintToChat(client, "%s {default}Vous avez perdu de {green}la vitesse{default}.", PREFIX);
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") - 0.2);
										g_iBonusSpeed[client]--;
									}
									else CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
							
								case 10: {
									CPrintToChat(client, "%s {default}Vous avez gagné un {green}pack de grenades{default}.", PREFIX);
									if (GetPlayerWeaponSlot(client, 3) == -1)
										GivePlayerItemAny(client, "weapon_hegrenade");
									GivePlayerItemAny(client, "weapon_smokegrenade");
									GivePlayerItemAny(client, "weapon_flashbang");
								}
							
								case 11: {
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
								}
								
								case 12: {
									CPrintToChat(client, "%s {default}Vous n'avez vraiment pas de chance.", PREFIX);
									DisarmClient(client);
									CPrintToChat(client, "%s {default}Vous avez perdu {green}20 points d'achat {default}!", PREFIX);
									g_iPlayerStuff[client].POINTS -= 20;
									if (g_iPlayerStuff[client].POINTS < 0)
										g_iPlayerStuff[client].POINTS = 0;
									GivePlayerItemAny(client, "weapon_knife");
									GivePlayerItemAny(client, "weapon_deagle");
									g_iPlayerStuff[client].TAZER = 0;
									SetEntityHealth(client, health - 50);
									SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.85);									
									if (health <= 0)
										SetEntityHealth(client, 1);
								}
								
								case 13: {
									if (health < 200) {
										CPrintToChat(client, "%s {default}Vous avez gagné {green}25 HP{default}.", PREFIX);									
										SetEntityHealth(client, health + 25);

										if (health + 25 > 200)
											SetEntityHealth(client, 200);
									}									
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
								}
							
								case 14: {
									CPrintToChat(client, "%s {default}Vous avez perdu {green}30 HP{default}.", PREFIX);
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
									SetEntityHealth(client, health - 30);									
									if (health <= 0)
										SetEntityHealth(client, 1);
								}
								
								case 15: {
									CPrintToChat(client, "%s {default}Vous avez gagné un {green}pack de grenades{default}.", PREFIX);
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
									if (GetPlayerWeaponSlot(client, 3) == -1)
										GivePlayerItemAny(client, "weapon_hegrenade");
									GivePlayerItemAny(client, "weapon_smokegrenade");
									GivePlayerItemAny(client, "weapon_flashbang");
								}
								
								case 16: {
									if(g_iBonusSpeed[client] != -1) {
										CPrintToChat(client, "%s {default}Vous avez perdu de {green}la vitesse{default}.", PREFIX);
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") - 0.2);
										g_iBonusSpeed[client]--;
									}
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
								}
								
								case 17: {
									if (health < 200) {
										CPrintToChat(client, "%s {default}Vous avez gagné {green}25 HP{default}.", PREFIX);
										SetEntityHealth(client, health + 25);
										
										if (health + 25 > 200)
											SetEntityHealth(client, 200);
									} else
										CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
							
								case 18: {
									if(g_iBonusSpeed[client] != 1) {
										CPrintToChat(client, "%s {default}Vous avez gagné de {green}la vitesse{default}.", PREFIX);
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + 0.2);
										g_iBonusSpeed[client]++;
									}
									else CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
								
								case 19: {
									CPrintToChat(client, "%s {default}Vous avez gagné {green}25 points d'achat {default}!", PREFIX);
									g_iPlayerStuff[client].POINTS += 25;
									
									if (isVipPlus(client) && g_iPlayerStuff[client].POINTS > LIMIT_POINT_VIPPLUS) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT_VIPPLUS;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
									else if (isVip(client) && g_iPlayerStuff[client].POINTS > LIMIT_POINT_VIP) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT_VIP;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
									else if (g_iPlayerStuff[client].POINTS > LIMIT_POINT && (!isVipPlus(client) || !isVip(client))) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
								}
								
								case 20: {
									CPrintToChat(client, "%s {default}Vous avez gagné {green}50 points d'achat {default}!", PREFIX);
									g_iPlayerStuff[client].POINTS += 50;
									
									if (isVipPlus(client) && g_iPlayerStuff[client].POINTS > LIMIT_POINT_VIPPLUS) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT_VIPPLUS;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
									else if (isVip(client) && g_iPlayerStuff[client].POINTS > LIMIT_POINT_VIP) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT_VIP;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
									else if (g_iPlayerStuff[client].POINTS > LIMIT_POINT && (!isVipPlus(client) || !isVip(client))) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
								}
								
								case 21: {
									if(g_iBonusGravity[client] != 1)
									{
										CPrintToChat(client, "%s {default}Vous avez gagné de {green}la gravité {default}!", PREFIX);
										g_iBonusGravity[client]++;
										g_fGravity[client] += 0.3;
									}
									else CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
								
								case 22: {
									switch (GetRandomInt(1, 10)) {
										case 1, 2, 3, 4, 5, 6, 7, 8, 9: {
											CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
										}
										
										case 10: {
											if (GetTeamClientCount(2) > 3 && GetTeamClientCount(3) > 2 && !bajail[client].g_bPlayerGiftLock) {
												char sError[255];
												g_hDatabase = SQL_Connect("autovip", true, STRING(sError));
												if (g_hDatabase != null) {
													char sQuery[252], sSteamid[32];
													int timestamp = GetTime();
														
													GetClientAuthId(client, AuthId_SteamID64, STRING(sSteamid));
													
													Format(STRING(sQuery), "SELECT datefin FROM af_droits WHERE steamid = '%s' AND datefin > %i LIMIT 0,1", sSteamid, timestamp + 3600);
													Handle hQuery = SQL_Query(g_hDatabase, sQuery);

													if (SQL_FetchRow(hQuery)) {
														int iUserID = SQL_FetchInt(hQuery, 1);
														Format(STRING(sQuery), "SELECT * FROM af_logs WHERE membre = '%i' AND detail = 'VIP Gratuit' AND timestamp > '%d' LIMIT 0,1", iUserID, timestamp - 604800);
														hQuery = SQL_Query(g_hDatabase, sQuery);

														if (!SQL_FetchRow(hQuery)) {
															EmitSoundToAll(SOUND_VIPDAY, _, _, _, _, 0.1);
																				
															CPrintToChatAll("%s {lightblue}%N {default}vient de gagner {green}1 journée de VIP{default}.", client);
																			
															Format(STRING(sQuery), "UPDATE af_droits SET datefin = datefin + 86400 WHERE steam_id = '%s'", sSteamid);				
															SQL_Query(g_hDatabase, sQuery);
															Format(STRING(sQuery), "INSERT INTO af_logs VALUES (NULL, '%i', 'VIP Gratuit', '+1 jour', 'Serveur BaJail', '%i', '')", iUserID, timestamp);				
															SQL_Query(g_hDatabase, sQuery);
															}
															else
																CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
													}
													else
														CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);

													if (hQuery != null && CloseHandle(hQuery)) hQuery = null;

													CloseHandle(g_hDatabase);
													g_hDatabase = null;
												} else
													CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
											} else
												CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
										}
									}
								}
							}
						} else {
							switch (GetRandomInt(1, 22)) {
								case 1: {
									CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
							
								case 2: {
									if (!bajail[client].g_bJailVIP && ReadPosition("jail_vip")) {
										CPrintToChat(client, "%s {default}Vous avez été téléporté dans {green}la cellule VIP{default}.", PREFIX);
										TeleportEntity(client, g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
									}
									else {
										CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
									}
									bajail[client].g_bJailVIP = true;
								}
							
								case 3: {
									if (health < 200) {
										CPrintToChat(client, "%s {default}Vous avez gagné {green}25HP{default}.", PREFIX);
										SetEntityHealth(client, health + 25);
										
										if (health + 25 > 200)
											SetEntityHealth(client, 200);
									}
								}
							
								case 4: {
									if (health < 200) {
										CPrintToChat(client, "%s {default}Vous avez gagné {green}15 HP{default}.", PREFIX);
										SetEntityHealth(client, health + 15);
										
										if (health + 15 > 200)
											SetEntityHealth(client, 200);
									} else
										CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
							
								case 5: {
									CPrintToChat(client, "%s {default}Vous avez perdu {green}15 HP{default}.", PREFIX);
									SetEntityHealth(client, health - 15);							
									if (health <= 0)
										SetEntityHealth(client, 1);
								}
								
								case 6: {
									CPrintToChat(client, "%s {default}Vous avez gagné un {green}ensemble de choc{default}.", PREFIX);
									if (GetPlayerWeaponSlot(client, 1) == -1)
										GivePlayerItemAny(client, "weapon_usp_silencer");
									if (GetPlayerWeaponSlot(client, 3) == -1)
										GivePlayerItemAny(client, "weapon_hegrenade");
									GivePlayerItemAny(client, "weapon_flashbang");
									GivePlayerItemAny(client, "weapon_smokegrenade");
									SetEntityHealth(client, health + 30);
										
									if (health + 30 > 200)
										SetEntityHealth(client, 200);
									
									if(g_iBonusSpeed[client] != 1) {
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + 0.2);
										g_iBonusSpeed[client]++;
									}
								}
								
								case 7: {
									CPrintToChat(client, "%s {default}Vous avez gagné une {green}fumigène{default}.", PREFIX);
									GivePlayerItemAny(client, "weapon_smokegrenade");
								}
								
								case 8: {
									if(g_iBonusSpeed[client] != 1) {
										CPrintToChat(client, "%s {default}Vous avez gagné de {green}la vitesse{default}.", PREFIX);
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + 0.2);
										g_iBonusSpeed[client]++;
									}
									else CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
								
								case 9: {
									if(g_iBonusSpeed[client] != -1) {
										CPrintToChat(client, "%s {default}Vous avez perdu de {green}la vitesse{default}.", PREFIX);
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") - 0.2);
										g_iBonusSpeed[client]--;
									}
									else CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
								
								case 10: {
									CPrintToChat(client, "%s {default}Vous avez gagné un {green}pack de grenades{default}.", PREFIX);
									if (GetPlayerWeaponSlot(client, 3) == -1)
										GivePlayerItemAny(client, "weapon_hegrenade");
									GivePlayerItemAny(client, "weapon_flashbang");	
									GivePlayerItemAny(client, "weapon_smokegrenade");
								}
								
								case 11: {
									if (!bajail[client].g_bGotUSP && !bajail[client].g_bGotDeagle && GetPlayerWeaponSlot(client, 1) == -1) {
										CPrintToChat(client, "%s {default}Vous avez gagné un {green}USP{default}.", PREFIX);
										GivePlayerItemAny(client, "weapon_usp_silencer");
										bajail[client].g_bGotUSP = true;
									}
									else {
										CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
									}
								}
								
								case 12: {
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
								}
								
								case 13: {
									CPrintToChat(client, "%s {default}Vous n'avez vraiment pas de chance.", PREFIX);
									DisarmClient(client);
									CPrintToChat(client, "%s {default}Vous avez perdu {green}20 points d'achat {default}!", PREFIX);
									g_iPlayerStuff[client].POINTS -= 20;
									
									GivePlayerItemAny(client, "weapon_knife_t");
									SetEntityHealth(client, health - 50);
									SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.85);
									
									if (health - 50 <= 0)
										SetEntityHealth(client, 1);
								}
								
								case 14: {
									if (health < 200) {
										CPrintToChat(client, "%s {default}Vous avez gagné {green}15 HP{default}.", PREFIX);
										SetEntityHealth(client, health + 15);
										
										if (health + 15 > 200)
											SetEntityHealth(client, 200);
									}
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
								}
							
								case 15: {
									CPrintToChat(client, "%s {default}Vous avez perdu {green}15 HP{default}.", PREFIX);
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
									SetEntityHealth(client, health - 15);
									
									if (health - 15 <= 0)
										SetEntityHealth(client, 1);
								}
								
								case 16: {
									CPrintToChat(client, "%s {default}Vous avez gagné un {green}pack de grenades{default}.", PREFIX);
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
									if (GetPlayerWeaponSlot(client, 3) == -1)
										GivePlayerItemAny(client, "weapon_hegrenade");
									GivePlayerItemAny(client, "weapon_flashbang");
									GivePlayerItemAny(client, "weapon_smokegrenade");
								}
								
								case 17: {
									if(g_iBonusSpeed[client] != -1) {
										CPrintToChat(client, "%s {default}Vous avez perdu de {green}la vitesse{default}.", PREFIX);
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") - 0.2);
										g_iBonusSpeed[client]--;
									}
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
								}
								
								case 18: {
									if (health < 200) {
										CPrintToChat(client, "%s {default}Vous avez gagné {green}15 HP{default}.", PREFIX);
										SetEntityHealth(client, health + 15);
										
										if (health + 15 > 200)
											SetEntityHealth(client, 200);
									} else
										CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
								}
							
								case 19: {
									if(g_iBonusSpeed[client] != 1) {
										CPrintToChat(client, "%s {default}Vous avez gagné de {green}la vitesse{default}.", PREFIX);
										SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + 0.2);
										g_iBonusSpeed[client]++;
									}
									CPrintToChat(client, "%s {default}Vous pouvez retaper {green}!gift{default}.", PREFIX);
									g_iPlayerStuff[client].GIFT++;
								}
								
								case 20: {
									CPrintToChat(client, "%s {default}Vous avez gagné {green}50 points d'achat {default}!", PREFIX);
									g_iPlayerStuff[client].POINTS += 50;
									
									if (isVipPlus(client) && g_iPlayerStuff[client].POINTS > LIMIT_POINT_VIPPLUS) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT_VIPPLUS;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
									else if (isVip(client) && g_iPlayerStuff[client].POINTS > LIMIT_POINT_VIP) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT_VIP;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
									else if (g_iPlayerStuff[client].POINTS > LIMIT_POINT && (!isVipPlus(client) || !isVip(client))) {
										g_iPlayerStuff[client].POINTS = LIMIT_POINT;
										CPrintToChat(client, "%s Vous avez atteint la limite de points.", PREFIX);
									}
								}
								
								case 21: {
									if(g_iBonusGravity[client] != -1)
									{
										CPrintToChat(client, "%s {default}Vous avez perdu de {green}la gravité {default}!", PREFIX);
										g_iBonusGravity[client]--;
										g_fGravity[client] -= 0.3;
									}
									else CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);									
								}
								
								case 22: {
									switch (GetRandomInt(1, 10)) {
										case 1, 2, 3, 4, 5, 6, 7, 8, 9: {
											CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
										}
										
										case 10: {
											if (GetTeamClientCount(2) > 3 && GetTeamClientCount(3) > 2 && !bajail[client].g_bPlayerGiftLock) {
												char sError[255];
												g_hDatabase = SQL_Connect("autovip", true, STRING(sError));
												if (g_hDatabase != null) {
													char sQuery[252], sSteamid[32];
													int timestamp = GetTime();
														
													GetClientAuthId(client, AuthId_SteamID64, STRING(sSteamid));
													
													Format(STRING(sQuery), "SELECT datefin FROM af_droits WHERE steamid = '%s' AND datefin > %i LIMIT 0,1", sSteamid, timestamp + 3600);
													Handle hQuery = SQL_Query(g_hDatabase, sQuery);

													if (SQL_FetchRow(hQuery)) {
														int iUserID = SQL_FetchInt(hQuery, 1);
														Format(STRING(sQuery), "SELECT * FROM af_logs WHERE membre = '%i' AND detail = 'VIP Gratuit' AND timestamp > '%d' LIMIT 0,1", iUserID, timestamp - 604800);
														hQuery = SQL_Query(g_hDatabase, sQuery);

														if (!SQL_FetchRow(hQuery)) {
															EmitSoundToAll(SOUND_VIPDAY, _, _, _, _, 0.1);
																				
															CPrintToChatAll("%s {lightblue}%N {default}vient de gagné {green}1 journée de VIP{default}.", PREFIX, client);
																			
															Format(STRING(sQuery), "UPDATE af_droits SET datefin = datefin + 86400 WHERE steam_id = '%s'", sSteamid);				
															SQL_Query(g_hDatabase, sQuery);
															Format(STRING(sQuery), "INSERT INTO af_logs VALUES (NULL, '%i', 'VIP Gratuit', '+1 jour', 'Serveur BaJail', '%i', '')", iUserID, timestamp);				
															SQL_Query(g_hDatabase, sQuery);
															}
															else
																CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
													}
													else
														CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);

													if (hQuery != null && CloseHandle(hQuery)) hQuery = null;

													CloseHandle(g_hDatabase);
													g_hDatabase = null;
												}
												else
													CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
											}
											else
												CPrintToChat(client, "%s {default}Vous n'avez rien gagné.", PREFIX);
										}
									}							
								}							
							}
						}

						g_iPlayerStuff[client].GIFT--;
						bajail[client].g_bPlayerGiftLock = true;
					}
					else
						CPrintToChat(client, "%s {default}Vous n'avez plus de !gift.", PREFIX);
				}
				else
					CPrintToChat(client, "%s {default}Vous ne pouvez pas faire de gift en DV.", PREFIX);
			}
			else
				CPrintToChat(client, "%s {default}Vous devez être vivant.", PREFIX);
		}
		else
			CPrintToChat(client, "%s {default}Vous devez être {green}VIP{default}.", PREFIX);
	}

	return Plugin_Handled;
}

public Action Command_Store(int client, int args) {
	if (IsValidClient(client, true))
		if (g_hDatabase != null)
			OpenStore(client);
		else
			CPrintToChat(client, "%s La Base de Données est hors-ligne.", PREFIX);
	else
		CPrintToChat(client, "%s Vous devez être vivant.", PREFIX);
	
	return Plugin_Handled;
}

public Action Command_Points(int client, int args) {
	if (IsValidClient(client)) {
		int maxCredits[MAXPLAYERS + 1];
		
		if(isVipPlus(client))
			maxCredits[client] = 50000;
		else if(isVip(client))
			maxCredits[client] = 50000;
		else
			maxCredits[client] = 50000;
			
		CPrintToChat(client, "%s Vous avez {%s}%i{grey}/%s {default}points.", PREFIX, g_iPlayerStuff[client].POINTS < 50000 ? "green" : "red", g_iPlayerStuff[client].POINTS, maxCredits[client]);
	}
	return Plugin_Handled;
}

public Action Command_HUD(int client, int args) {
	if (IsValidClient(client)) {
		bajail[client].g_bHUDStatus = !bajail[client].g_bHUDStatus;
		CPrintToChat(client, "%s Vous venez d%s {default}votre HUD.", PREFIX, bajail[client].g_bHUDStatus ? "'{green}activer" : "e {darkred}désactiver");
	}
	
	return Plugin_Handled;
}

public Action Command_Blocked(int client, int args) {
	return Plugin_Handled;
}