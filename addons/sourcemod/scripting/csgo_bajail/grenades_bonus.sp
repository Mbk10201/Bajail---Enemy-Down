/*
    ______                          __             ____                        
   / ____/_______  ____  ____ _____/ /__  _____   / __ )____  ____  __  _______
  / / __/ ___/ _ \/ __ \/ __ `/ __  / _ \/ ___/  / __  / __ \/ __ \/ / / / ___/
 / /_/ / /  /  __/ / / / /_/ / /_/ /  __(__  )  / /_/ / /_/ / / / / /_/ (__  ) 
 \____/_/   \___/_/ /_/\__,_/\__,_/\___/____/  /_____/\____/_/ /_/\__,_/____/  
                                                                              
	Special Thanks to Steven
*/

#define PREFIX_BONUS			"{green}[Bonus]{default}" 

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)   { 
	int victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsValidClient(victim) && IsValidClient(attacker) && !g_bLastRequest) {
		if (GetTotalPlayer(2) > 1) { 
			if (g_PlayerBonus[attacker].Munition_Incendiaires) { 
				g_PlayerBonus[attacker].Munition_Incendiaires--; 
				IgniteEntity(victim, 2.0); 

				char format[128];
				Format(STRING(format),  "%d Balle%s Incendiaire%s", g_PlayerBonus[attacker].Munition_Incendiaires, (g_PlayerBonus[attacker].Munition_Incendiaires > 1 ? "s" : ""), (g_PlayerBonus[attacker].Munition_Incendiaires > 1 ? "s" : ""));
				PrintHudMessage(attacker, format);
			}
			else if (g_PlayerBonus[attacker].Munition_Aveuglantes && !bajail[victim].g_bClientIsAveugled) { 
				bajail[victim].g_bClientIsAveugled = true; 
				g_PlayerBonus[attacker].Munition_Aveuglantes--; 
				
				Client_ScreenFade(victim, 1, FFADE_IN|FFADE_PURGE, _, 20, 0, 0, 255);
				CreateTimer(MUNITION_AVEUGLANTE_TIME, Timer_RemoveAveuglante, victim, TIMER_FLAG_NO_MAPCHANGE); 
				 
				char format[128];
				Format(STRING(format), "%d Balle%s Aveuglante%s", g_PlayerBonus[attacker].Munition_Aveuglantes, (g_PlayerBonus[attacker].Munition_Aveuglantes > 1 ? "s" : ""), (g_PlayerBonus[attacker].Munition_Aveuglantes > 1 ? "s" : ""));
				PrintHudMessage(attacker, format);			
			}
			else if (g_PlayerBonus[attacker].Munition_Explosives && !bajail[victim].g_bClientIsParalyzed) { 
				bajail[victim].g_bClientIsParalyzed = true; 
				g_PlayerBonus[attacker].Munition_Explosives--;
				
				Client_Shake(victim, _, 35.0, 100.0, MUNITION_EXPLOSIVE_TIME);
				CreateTimer(MUNITION_EXPLOSIVE_TIME, Timer_RemoveExplosive, victim, TIMER_FLAG_NO_MAPCHANGE); 
				 
				char format[128];
				Format(STRING(format),  "%d Balle%s Sonnante%s", g_PlayerBonus[attacker].Munition_Explosives, (g_PlayerBonus[attacker].Munition_Explosives > 1 ? "s" : ""), (g_PlayerBonus[attacker].Munition_Explosives > 1 ? "s" : ""));
				PrintHudMessage(attacker, format);	
			}
			else if (g_PlayerBonus[attacker].Munition_Glacees && !bajail[victim].g_bClientIsFrozen) {
				g_PlayerBonus[attacker].Munition_Glacees--; 
				bajail[victim].g_bClientIsFrozen = true; 
				g_fOldSpeed[victim] = GetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue");  
				SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", MUNITION_GLACE_SLOW_VALUE); 
				CreateTimer(MUNITION_GLACE_SLOW_TIME, Timer_UnFreeze, victim, TIMER_FLAG_NO_MAPCHANGE); 
				SetEntityRenderColor(victim, 0, 128, 255, 192); 
				 
				float vec[3]; 
				GetClientAbsOrigin(victim, vec); 
				vec[2] += 10;	 
				 
				GetClientEyePosition(victim, vec); 
				EmitAmbientSound(SOUND_FREEZE, vec, victim, SNDLEVEL_RAIDSIREN); 
				
				char format[128];
				Format(STRING(format), "%d Balle%s Glacée%s", g_PlayerBonus[attacker].Munition_Glacees, (g_PlayerBonus[attacker].Munition_Glacees > 1 ? "s" : ""), (g_PlayerBonus[attacker].Munition_Glacees > 1 ? "s" : ""));
				PrintHudMessage(attacker, format);	
			}
		}
		
		if(GetClientTeam(attacker) == CS_TEAM_CT) CPrintToChat(victim, "%s {lightblue}Tu as reçus {green}%d {lightblue}dégâts de {darkred}%N{lightblue}.", PREFIX, GetEventInt(event, "dmg_health"), attacker);
		else if(GetClientTeam(attacker) == CS_TEAM_T) CPrintToChat(victim, "%s {lightblue}Tu as reçus {green}%d {lightblue}dégâts.", PREFIX, GetEventInt(event, "dmg_health"));	
	}
	if (IsValidClient(victim) && IsValidClient(attacker)) {
		if(g_hTimerDvChat[attacker] != null && g_iLastRequest.CHAT) {
			g_bIsChat[victim] = true;
			g_bIsChat[attacker] = false;
			
			SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 1.25);
			SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			DisarmClient(attacker);
			if (GetClientTeam(victim) == CS_TEAM_CT)GivePlayerItemAny(victim, "weapon_knife");
			else if (GetClientTeam(victim) == CS_TEAM_T)GivePlayerItemAny(victim, "weapon_knife_t");
			
			CPrintToChatAll("%s {darkred}%N {default}vient d'être le chat", PREFIX, victim);
		} else if(g_bQr && GetClientTeam(attacker) == CS_TEAM_T) {
			bajail[attacker].g_NoDv = false;
		}
	}
} 

public Action Timer_Unfreeze(Handle timer, any client) {
	if (IsValidClient(client, true) && bajail[client].g_bRending) {
		SetEntityMoveType(client, MOVETYPE_WALK);	
		GivePlayerItemAny(client, "weapon_knife_t");
		bajail[client].g_bRending = false;
		SetEntityRenderColor(client, 255, 255, 255, 255);
		g_hFreeTimer[client] = null;
	}
}

public Action Timer_RemoveAveuglante(Handle timer, any client) {
	if (IsValidClient(client)) {
		bajail[client].g_bClientIsAveugled = false;
		Client_ScreenFade(client, 1, FFADE_IN|FFADE_PURGE, _, 0, 0, 0, 0);
	} 
}

public Action Timer_RemoveExplosive(Handle timer, any client) { 
	if (IsValidClient(client)) bajail[client].g_bClientIsParalyzed = false; 
}

public Action Timer_UnFreeze(Handle timer, any client) { 
	if (IsValidClient(client, true)) { 
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fOldSpeed[client]); 
		SetEntityRenderColor(client, 255, 255, 255, 255); 
		bajail[client].g_bClientIsFrozen = false; 
	}
} 

public Action Event_GrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(GetEventInt(event,"userid")); 
	if (IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_CT && !g_bLastRequest) 
	{ 
		if (g_PlayerBonus[client].Speed) { 
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") - BONUS_SPEED); 
			CPrintToChat(client, "%s Vous perdez votre Bonus de Vitesse.", PREFIX_BONUS); 
			ResetClient(client, 1); 
		}
		else if (g_PlayerBonus[client].Gravity) { 
			SetEntityGravity(client, 1.0);		 
			CPrintToChat(client, "%s Vous perdez votre Bonus de Gravité.", PREFIX_BONUS); 
			ResetClient(client, 1); 
		}
		else if (g_PlayerBonus[client].Invisibility) { 
			CPrintToChat(client, "%s Vous êtes invisible pendant {green}%d secondes{default}.", PREFIX_BONUS, RoundToFloor(BONUS_INVIBILITY_TIME));
			SetInvisibility(client); 
			g_hTimerInvisibility[client] = CreateTimer(BONUS_INVIBILITY_TIME, Timer_InvisibilityDone, client, TIMER_FLAG_NO_MAPCHANGE); 
			g_hTimerInvisibilityBcn[client] = CreateTimer(0.5, Timer_InvisibilityBeacon, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE); 
			ResetClient(client, 2); 
		}
		else if (g_PlayerBonus[client].Regene) {
			CPrintToChat(client, "%s Vous perdez votre Bonus de Régénération.", PREFIX_BONUS); 
			ResetClient(client, 1); 
		}
		else if (g_PlayerBonus[client].Infirmier) { 
			CPrintToChat(client, "%s Vous perdez votre Bonus d'Infirmier.", PREFIX_BONUS); 
			ResetClient(client, 1); 
		}
	} 
}

public Action Event_FlashDetonate(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_iLastRequest.BALLE) {
		StopFlash(client);
		GivePlayerItemAny(client, "weapon_flashbang");
	}
}

public Action Event_Blind(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_iLastRequest.BALLE)
		StopFlash(client);
}

public Action ShowNadeMenu(Handle timer, any client) { 
	if (IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_CT && g_iJailsCooldown) {
		Menu menu = new Menu(MenuHandler_GrenadeChoosen);

		menu.SetTitle("Choisissez un Bonus :");
		char sBuffer[64]; 
		bool bVIPClient = isVip(client);
		 
		Format(STRING(sBuffer), "Grenade de Vitesse (+%.1f)", BONUS_SPEED);
		menu.AddItem("bonus_speed", sBuffer);
		 
		Format(STRING(sBuffer), "Grenade de Gravité (%.1f)", BONUS_GRAVITY); 
		menu.AddItem("bonus_gravity", sBuffer);
		 
		Format(STRING(sBuffer), "Grenade d'Invisibilité (%d secs)", RoundToFloor(BONUS_INVIBILITY_TIME)); 
		menu.AddItem("bonus_invisibilite", sBuffer);
		 
		Format(STRING(sBuffer), "Bonus de Vie (+%dHP)", BONUS_HP_ADD); 
		menu.AddItem("bonus_vie", sBuffer);
		 
		Format(STRING(sBuffer), "Grenade de Régénération (+%dHP/sec)", BONUS_REGENE_VALUE); 
		menu.AddItem("bonus_regen", sBuffer);
		
		Format(STRING(sBuffer), "Grenades de Téléportation (%d)", BONUS_TELEPORT); 
		menu.AddItem("bonus_teleport", sBuffer);
		 
		Format(STRING(sBuffer), "[VIP] Grenade d'Infirmier (+%dHP/sec pour vos alliés)", BONUS_INFIRMIER_AMOUNT); 
		menu.AddItem("bonus_infirmier", sBuffer, bVIPClient ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		 
		Format(STRING(sBuffer), "[VIP] Munitions Glacées (%d balles)", BONUS_MUNITIONS_GLACE); 
		menu.AddItem("bonus_glace", sBuffer, bVIPClient ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		 
		Format(STRING(sBuffer), "[VIP] Munitions Incendiaires (%d balles)", BONUS_MUNITIONS_INCENDIAIRE); 
		menu.AddItem("bonus_incendiaire", sBuffer, bVIPClient ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

		Format(STRING(sBuffer), "[VIP] Munitions Aveuglantes (%d balles)", BONUS_MUNITIONS_AVEUGLANTES); 
		menu.AddItem("bonus_aveuglante", sBuffer, bVIPClient ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

		Format(STRING(sBuffer), "[VIP] Munitions Sonnantes (%d balles)", BONUS_MUNITIONS_EXPLOSIVES); 
		menu.AddItem("bonus_explosive", sBuffer, bVIPClient ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		 
		menu.ExitButton = false;

		menu.Display(client, g_iJailsCooldown);
	}

	g_hNadeMenu[client] = null;
}

public int MenuHandler_GrenadeChoosen(Menu menu, MenuAction action, int client, int param2) { 
	if (action == MenuAction_Select && IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_CT) { 
		if (!g_iJailsCooldown) {
			CPrintToChat(client, "%s Trop tard, les cellules sont ouvertes.", PREFIX_BONUS); 
		}
		else { 
			switch (param2) { 				 
				/*=================== 
					Bonus de Speed  
				=====================*/ 
				case 0: { 
					if (GetPlayerWeaponSlot(client, 3) == -1) 
						GivePlayerItemAny(client, "weapon_hegrenade");
					float Current_Speed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", BONUS_SPEED + Current_Speed);
					CPrintToChat(client, "%s Bonus de Vitesse activé !", PREFIX_BONUS);
					g_PlayerBonus[client].Speed = true;
				}

				/*=================== 
					Bonus de Gravité 
				=====================*/ 
				case 1: { 
					if (GetPlayerWeaponSlot(client, 3) == -1) 
						GivePlayerItemAny(client, "weapon_hegrenade");						 
					SetEntityGravity(client, BONUS_GRAVITY);						 
					CPrintToChat(client, "%s Bonus de Gravité activé !", PREFIX_BONUS); 
					g_PlayerBonus[client].Gravity = true;
					g_fGravity[client] = 0.0;
				} 

				/*=================== 
					Bonus d'invisibilité 
				=====================*/ 
				case 2: { 
					if (GetPlayerWeaponSlot(client, 3) == -1) 
						GivePlayerItemAny(client, "weapon_hegrenade");						 
					CPrintToChat(client, "%s Vous serez invisible à l'explosion de votre Grenade !", PREFIX_BONUS); 
					g_PlayerBonus[client].Invisibility = true; 
				}

				/*=================== 
					Bonus de vie 
				=====================*/ 
				case 3: { 
					SetEntityHealth(client, GetClientHealth(client) + BONUS_HP_ADD); 
					CPrintToChat(client, "%s Vous gagnez {green}%dHP{default} !", PREFIX_BONUS, BONUS_HP_ADD);						
					if (GetClientHealth(client) > 200)
						SetEntityHealth(client, 200);
				} 
					 
				/*=================== 
					Bonus de regen 
				=====================*/ 
				case 4: { 
					if (GetPlayerWeaponSlot(client, 3) == -1) 
						GivePlayerItemAny(client, "weapon_hegrenade"); 
					g_hTimerRegen[client] = CreateTimer(BONUS_REGENE_TIMER, Timer_Regen, client, TIMER_REPEAT);
					CPrintToChat(client, "%s Bonus de Régénération activé !", PREFIX_BONUS);
					g_PlayerBonus[client].Regene = true;
				} 
					
				/*=================== 
					Grenade de TP 
				=====================*/ 
				case 5: { 
					if (!bajail[client].g_bFlashBonus)
						GivePlayerItemAny(client, "weapon_flashbang"); 
					GivePlayerItemAny(client, "weapon_flashbang"); 
					bajail[client].g_bFlashBonus = true;
					CPrintToChat(client, "%s Lancez une Flashbang pour être téléporté !", PREFIX_BONUS);
				} 
				/*=================== 
					Infirmier 
				=====================*/ 
				case 6: { 
					if (GetPlayerWeaponSlot(client, 3) == -1) 
						GivePlayerItemAny(client, "weapon_hegrenade"); 
							 
					g_hTimerInfirmier[client] = CreateTimer(BONUS_INFIRMIER_TIMER, Timer_Infirmier, client, TIMER_REPEAT); 
					CPrintToChat(client, "%s Bonus d'Infirmier activé !", PREFIX_BONUS); 
					g_PlayerBonus[client].Infirmier = true; 
				} 
				/*=================== 
					Balles glacées 
				=====================*/ 
				case 7: { 
					g_PlayerBonus[client].Munition_Glacees = BONUS_MUNITIONS_GLACE; 
					CPrintToChat(client, "%s Vous disposez de {lightblue}%d Balles Glacées {default}!", PREFIX_BONUS, BONUS_MUNITIONS_GLACE); 
				} 
				/*=================== 
					Balles Incendiaires 
				=====================*/ 
				case 8: { 
					g_PlayerBonus[client].Munition_Incendiaires = BONUS_MUNITIONS_INCENDIAIRE; 
					CPrintToChat(client, "%s Vous disposez de {lightblue}%d Balles Incendiaires {default}!", PREFIX_BONUS, BONUS_MUNITIONS_INCENDIAIRE); 
				}
				/*=================== 
					Balles Flashante 
				=====================*/ 
				case 9: { 
					g_PlayerBonus[client].Munition_Aveuglantes = BONUS_MUNITIONS_AVEUGLANTES; 
					CPrintToChat(client, "%s Vous disposez de {lightblue}%d Balles Aveuglantes {default}!", PREFIX_BONUS, BONUS_MUNITIONS_AVEUGLANTES); 
				}
				/*=================== 
					Balles Explosives 
				=====================*/ 
				case 10: { 
					g_PlayerBonus[client].Munition_Explosives = BONUS_MUNITIONS_EXPLOSIVES; 
					CPrintToChat(client, "%s Vous disposez de {lightblue}%d Balles Sonnantes {default}!", PREFIX_BONUS, BONUS_MUNITIONS_EXPLOSIVES); 
				}
			} 
		} 		 
	}
	else if (action == MenuAction_End)
		delete menu; 
}

public Action Timer_Infirmier(Handle timer, any client) {
	if (IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_CT) {
		bool bHeal = false;
		float entorigin[3], clientent[3], distance;
		LoopClients(i) {
			if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT && i != client) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entorigin);
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
				distance = GetVectorDistance(entorigin, clientent);
				if (distance <= BONUS_INFIRMIER_RADIUS) {
					int Health = GetClientHealth(i); 
					int Total = Health + BONUS_INFIRMIER_AMOUNT; 
					if (Health < BONUS_INFIRMIER_MAXIMUM) { 
						BeamRing(client, i); 
						SetEntityHealth(i, (Total > BONUS_INFIRMIER_MAXIMUM ? BONUS_INFIRMIER_MAXIMUM : Total)); 
						
						char format[128];
						Format(STRING(format),"%N vous soigne", client); 
						PrintHudMessage(i, format);	

						bHeal = true; 
					} 
				}
			} 
		} 
		if (bHeal) {
			float fOrigin[3]; 
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin); 
			fOrigin[2] += 3.0; 
			TE_SetupBeamRingPoint(fOrigin, 40.0, 48.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 7.0, 1.0, {0, 255, 51, 255}, 7, 0); 
			TE_SendToAll(); 
		} 
	}
}

void BeamRing(int client, int target) { 
	float fOrigin[3], fOrigin2[3]; 
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", fOrigin); 
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin2); 
	 
	fOrigin2[2] += 3.0; 
	fOrigin[2] += 3.0; 
	TE_SetupBeamRingPoint(fOrigin, 15.0, 30.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 7.0, 1.0, {0, 153, 0, 255}, 7, 0); 
	TE_SendToAll(); 
	 
	 
	TE_SetupBeamPoints(fOrigin2, fOrigin, g_iLightingSprite, 0, 1, 0, 0.2, 20.0, 0.0, 2, 5.0, {0, 153, 0, 255}, 3); 
				 
	TE_SendToAll(); 	 
}

public Action Timer_Regen(Handle timer, any client) { 
	if (IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_CT) { 
		int Total = GetClientHealth(client) + BONUS_REGENE_VALUE;
		SetEntityHealth(client, (Total > BONUS_REGEN_MAX ? BONUS_REGEN_MAX : Total));
	}
}

public Action Timer_InvisibilityDone(Handle timer, any client) { 
	if (IsValidClient(client, true)) { 
		CPrintToChat(client, "%s Vous n'êtes plus invisible !", PREFIX_BONUS); 
		SetInvisibility(client, true);		 
	} 

	TrashTimer(g_hTimerInvisibility[client], true);
	TrashTimer(g_hTimerInvisibilityBcn[client], true);
}

public Action Timer_InvisibilityBeacon(Handle timer, any client) { 
	if (IsValidClient(client, true)) { 
		float fVec[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", fVec);
		fVec[2] += 3;
		TE_SetupBeamRingPoint(fVec, 10.0, 50.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, 10.0, 0.5, { 0, 191, 255, 255 }, 10, 0);
		TE_SendToAll();
	}
	else
		TrashTimer(g_hTimerInvisibilityBcn[client], true);
}

public Action Timer_FlashbangTeleport(Handle timer, any entity) { 
	if (entity == INVALID_ENT_REFERENCE || !IsValidEdict(entity) || !IsValidEntity(entity) || entity == 70)
		return;

	float fPosition[3], fPositionTop[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fPosition);
	fPosition[2] += 1.0;
	fPositionTop = fPosition;
	fPositionTop[2] += 65.0;

	int client = GetEntDataEnt2(entity, FindSendPropInfo("CBaseGrenade", "m_hThrower"));

	RemoveEdict(entity);

	if (!IsValidClient(client, true) && GetClientTeam(client) != 3 && (g_bLastRequest || !bajail[client].g_bFlashBonus || !isVip(client)))
		return;
	
	Handle hTrace = TR_TraceHullFilterEx(fPosition, fPositionTop, view_as<float>({ -24.0, -24.0, 0.0 }), view_as<float>({ 24.0, 24.0, 64.0 }), MASK_PLAYERSOLID, TraceEntityFilterPlayers);
	if (!TR_DidHit(hTrace)) {
		fPosition[2] -= 1.0;
		TeleportEntity(client, fPosition, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
		if (isVip(client)) CPrintToChat(client, "{green}[VIP] {default}Vous venez d'être téléporté par votre Flashbang.");
		else if (bajail[client].g_bFlashBonus) CPrintToChat(client, "{green}[Bonus] {default}Vous venez d'être téléporté par votre Flashbang.");
		EmitAmbientSound(SOUND_TP, NULL_VECTOR, client);
	}
	else {
		GivePlayerItemAny(client, "weapon_flashbang");
		if (isVip(client)) CPrintToChat(client, "{green}[VIP] {default}Votre Flashbang vous a été restituée.");
		else if (bajail[client].g_bFlashBonus) CPrintToChat(client, "{green}[Bonus] {default}Votre Flashbang vous a été restituée.");
	}
	CloseHandle(hTrace);
}

public bool TraceEntityFilterPlayers(int entity, int contentsMask) {
	return 0 < entity <= MaxClients && IsClientInGame(entity) ? true : false;
}