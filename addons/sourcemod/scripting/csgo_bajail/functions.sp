/*
     ______                 __  _                 
    / ____/_  ______  _____/ /_(_)___  ____  _____
   / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  ) 
 /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/  
                                                                                                                    
*/

bool IsValidClient(int client, bool bAlive = false) {
	return MaxClients >= client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)) ? true : false;
}

void CheckEverything(int client) {
	if (GetTotalPlayer(3) + GetTotalPlayer(2) == 1) {
		LoopClients(i) {
			if (IsValidClient(i) && g_iPlayerBet[i].AMOUNT) {
				if (g_iPlayerBet[i].TEAM == 3 && GetTotalPlayer(3) == 1 || g_iPlayerBet[i].TEAM == 2 && GetTotalPlayer(2) == 1) {
					g_iPlayerStuff[i].POINTS += g_iPlayerBet[i].AMOUNT * 2;
						
					CPrintToChat(i, "%s Vous avez gagné {green}%d points{default} grâce à votre pari.", PREFIX, g_iPlayerBet[i].AMOUNT * 2);
					g_iPlayerBet[i].AMOUNT = 0;
					
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
				else {
					g_iPlayerBet[i].AMOUNT = 0;
					CPrintToChat(i, "%s Vous n'avez pas parié sur le bon joueur. La prochaine fois !", PREFIX);
				}
			}
		}
	}

	if (IsValidClient(client) && bajail[client].g_bGardienChef && (!g_bQuartierLibre || !g_bQr)) {
		int Captain, CaptainSecours;
		LoopClients(i) {
			if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT && i != client) {
				if (bajail[client].g_bWantsCaptain)
					Captain++;
				else if (bajail[i].g_bWantsCaptainSecours)
					CaptainSecours++;
			}
		}
			
		if (GetTotalPlayer(3) > 1 && GetTotalPlayer(2) > 1) {
			if (Captain) {
				GetChef();
			} else if (CaptainSecours) {
				GetChef(true);
			} else {
				CPrintToChatAll("%s Le Capitaine est mort, les Prisonniers ont {green}Quartier Libre {default} car il n'y a pas de Capitaine de Secours.'", PREFIX);
			}
		}
	}
	
	if (IsValidClient(client) && (!GetTotalPlayer(3) || !GetTotalPlayer(2))) {
		CS_TerminateRound(0.0, CSRoundEnd_GameStart);	
	}
		
	if (IsValidClient(client) && bajail[client].g_bLastRequestPlayer && GetTotalPlayer(3) && GetTotalPlayer(2) && !g_iLastRequest.ISOLOIR && !g_iLastRequest.BROCHETTE && !g_iLastRequest.VIP) {
		g_iLastRequest.ROULETTE = 0;
		g_iLastRequest.COUTEAU = 0;
		g_iLastRequest.LANCER = 0;
		g_iLastRequest.UNSCOPE = 0;
		g_iLastRequest.SCOPE = 0;
		g_iLastRequest.BASKET = 0;
		g_iLastRequest.COWBOY = 0;
		g_iLastRequest.GRENADE = 0;
		g_iLastRequest.AIM = 0;
		g_iLastRequest.POMPE = 0;
		g_iLastRequest.CHAT = 0;
		g_iLastRequest.PATATE = 0;
		g_iLastRequest.BALLE = 0;
		g_iLastRequest.SULFATEUSE = 0;
		g_iCowboyTimer = 0;

		LoopClients(i) {
			if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_T) {
				ResetClient(i);
				GenerateDVMenu(i);
			}
					
			if (IsValidClient(i) && !IsPlayerAlive(i) && GetClientTeam(i) >= 2 && g_iPlayerStuff[i].POINTS >= 50 && GetTotalPlayer(3) == 1 && g_bLastRequest && !g_iLastRequest.BROCHETTE && !g_iLastRequest.ISOLOIR && !g_iLastRequest.VIP) {
				GenerateBetPanel(i);
			}
		}
	}

	if (GetTotalPlayer(2) == 1 && GetTotalPlayer(3) && !g_bLRWait && !g_bLastRequest && !g_bLRDenied) {
		CPrintToChatAll("☰☰☰☰☰☰☰☰☰ DERNIÈRE VOLONTÉ ☰☰☰☰☰☰☰☰☰");
			
		g_bLRWait = true;
					
		EmitSoundToAll(SOUND_DV, _, _, _, _, 0.1);
					
		LoopClients(i) {
			if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_T) {
				ResetClient(i);				
				if (ReadPosition("dv_choice"))
					TeleportEntity(i, g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
				DisarmClient(i);
				SetEntityHealth(i, 100000);
				SetEntityMoveType(i, MOVETYPE_NONE);
				BuildMenuDv(i);
				
				//break;		??
			}
		}

		g_iDVTimer = 21;

		g_iJailsCooldown = 0;
		
		g_bChoixAleatoire = false;
		g_bChoixAleatoireSecours = false;
	}
	
	if (GetTotalPlayer(3) == 1 && g_bCanDct && !g_bDernierCT && !g_bLRWait && !g_bLastRequest && !g_bLRDenied) {
		LoopClients(i) {
			if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) {
				switch (GetRandomInt(1,7)) {
					case 1,2: {
						SetEntityModel(i, MODEL_PRISONNIER1);
					}
					case 3,4: {
						SetEntityModel(i, MODEL_PRISONNIER2);
					}
					case 5: {
						SetEntityModel(i, MODEL_PRISONNIER3);
					}
					case 6: {
						SetEntityModel(i, MODEL_PRISONNIER4);
					}
					case 7: {
						SetEntityModel(i, MODEL_PRISONNIER5);
					}
				}
				int Health = GetClientHealth(i);
				if (isVip(i) || isRooted(i))
					SetEntityHealth(i, Health + 50);
				else
					SetEntityHealth(i, Health + 20);

				if (GetClientHealth(i) > 200)
					SetEntityHealth(i, 200);

				//break;		??
			}
		}
					
		CPrintToChatAll("☰☰☰☰☰☰☰☰☰☰☰ DERNIER CT ☰☰☰☰☰☰☰☰☰☰☰");
		CPrintToChatAll("Le dernier gardien a un skin de prisonnier.");
		CPrintToChatAll("☰☰☰☰☰☰☰☰☰☰☰ DERNIER CT ☰☰☰☰☰☰☰☰☰☰☰");
						
		//EmitSoundToAll(SOUND_DCT, _, _, _, _, 0.1);

		g_iJailsCooldown = 0;
						
		g_bDernierCT = true;
						
		g_bChoixAleatoire = false;
		g_bChoixAleatoireSecours = false;
	}
}

void CheckTheGame() {
	if (GetTotalPlayer(3) > 1 && GetTotalPlayer(2) > 1) {
		LoopClients(i) {
			if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_T && g_iGameChoice[i]) {
				CPrintToChat(i, "{lightred}[Game] {default}L'Ordinateur a choisi la {green}Pierre {default}!");
					
				int Health = GetClientHealth(i);

				if (g_iGameAnswer == g_iGameChoice[i])
					CPrintToChat(i, "{lightred}[Game] {default}Vous n'avez rien gagné !");
				else if (g_iGameAnswer == g_iGameChoice[i] - 1 || g_iGameAnswer == 3 && g_iGameChoice[i] == 1) {
					switch (GetRandomInt(1, 6)) {
						case 1: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez gagné {green}15 HP{default}.");											
							if (Health + 15 > 200)
								SetEntityHealth(i, 200);
							else
								SetEntityHealth(i, Health + 15);
						}
									
						case 2: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez gagné une {green}fumigène{default}.");
							GivePlayerItemAny(i, "weapon_smokegrenade");
						}
									
						case 3: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez perdu de {green}la vitesse{default}.");
							if(g_iBonusSpeed[i] != -1) {
									SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue") - 0.2);
									g_iBonusSpeed[i]--;
								}
						}
							
						case 4: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez gagné un {green}pack de grenades{default}.");
							if (GetPlayerWeaponSlot(i, 3) == -1)
								GivePlayerItemAny(i, "weapon_hegrenade");
							GivePlayerItemAny(i, "weapon_smokegrenade");
						}
									
						case 5: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez gagné {green}50 points d'achat {default}!");
							g_iPlayerStuff[i].POINTS += 50;
				
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
									
						case 6: {
							if(g_iBonusGravity[i] != 1) {
								g_iBonusGravity[i]++;
								CPrintToChat(i, "{lightred}[Game] {default}Vous avez gagné de {green}la gravité {default}!");
								g_fGravity[i] += 0.3;
							}
							else CPrintToChat(i, "{lightred}[Game] {default}Vous n'avez rien gagné !");					
						}
					}
				} else if (g_iGameAnswer == g_iGameChoice[i] + 1 || g_iGameAnswer == 1 && g_iGameChoice[i] == 3) {
					switch (GetRandomInt(1, 5)) {
						case 1: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez perdu {green}15 HP{default}.");
							SetEntityHealth(i, Health - 15);
										
							if (Health <= 0)
								SetEntityHealth(i, 1);
						}
									
						case 2: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez gagné de {green}la vitesse{default}.");
							if(g_iBonusSpeed[i] != 1) {
								SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue") + 0.2);
								g_iBonusSpeed[i]++;
							}
						}
							
						case 3: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez êtes {green}désarmé{default}.");
							DisarmClient(i);
							GivePlayerItemAny(i, "weapon_knife_t");
						}
									
						case 4: {
							CPrintToChat(i, "{lightred}[Game] {default}Vous avez perdu {green}50 points d'achat {default}!");
							g_iPlayerStuff[i].POINTS -= 50;
										
							if (g_iPlayerStuff[i].POINTS < 0)
								g_iPlayerStuff[i].POINTS = 0;
						}
									
						case 5: {
							if(g_iBonusGravity[i] != -1) {
								g_iBonusGravity[i]--;
								CPrintToChat(i, "{lightred}[Game] {default}Vous avez perdu de {green}la gravité {default}!");
								g_fGravity[i] -= 0.3;
							}
							else CPrintToChat(i, "{lightred}[Game] {default}Vous n'avez rien gagné !");					
						}
					}
				}
			}
		}
	}
}

void ResetClient(int client, int bBonusOnly = 0) {
	if (!bBonusOnly) {
		g_iCowboy[client].COWBOY = false;
		g_iCowboy[client].USE = 0;
		g_iCowboy[client].CROUCH = 0;
		g_iCowboy[client].MRB = 0;
		g_iCowboy[client].LOCK = false;
		g_iCowboy[client].WIN = false;

		g_iPlayerBet[client].TEAM = 0;
		g_iPlayerBet[client].AMOUNT = 0;

		g_iGameChoice[client] = 0;
		g_iRendLock[client] = 0;
		g_iPlayerStuff[client].REND = 0;
		g_iPlayerStuff[client].TAZER = 0;
		g_iPlayerStuff[client].RW = 0;
		g_iPlayerStuff[client].GIFT = 0;
		g_iKillsCount[client] = 0;
		g_iKilledBy[client] = -1;
		g_iPlayerSmoke[client] = -1;
		g_iPlayerSkin[client] = 0;
		g_iBonusSpeed[client] = 0;
		g_iBonusGravity[client] = 0;
		
		bajail[client].g_bExploding = false;
		bajail[client].g_bTazed = false;
		bajail[client].g_bRending = false;
		bajail[client].g_bReceptDone = false;
		bajail[client].g_bLastRequestPlayer = false;
		bajail[client].g_bNeedClass = false;
		bajail[client].g_bGardienChef = false;
		bajail[client].g_bPlayerDied = false;
		bajail[client].g_bFreezeCooldown = false;
		bajail[client].g_bJailVIP = false;
		bajail[client].g_bGotUSP = false;
		bajail[client].g_bGotDeagle = false;
		bajail[client].g_bArmoryLeft = false;
		bajail[client].g_bPlayerGiftLock = false;
		bajail[client].g_bDropLock = false;
		bajail[client].g_bRendLock = false;
		bajail[client].g_bDisconnecting = false;
		bajail[client].g_bClickLocker = false;
		bajail[client].g_bIsKamikaze = false;
		bajail[client].g_bHasPatateChaude = false;
		g_bIsChat[client] = false;
		
		g_fTazerCount[client] = 0.0;
		g_fGravity[client] = 1.0;

		TrashTimer(g_hNadeMenu[client]);		
		TrashTimer(g_hTazerTimer[client]);
		TrashTimer(g_hTimerRendLock[client]);
		TrashTimer(g_hTimerFreekill[client]);
		TrashTimer(g_hDVInitialize[client]);
		TrashTimer(g_hFreeTimer[client]);
		TrashTimer(g_hTimerDvChat[client]);
		
		TrashTimer(g_hDVTimerPatate);
		
		if (bajail[client].g_bWantsCaptain) {
			bajail[client].g_bWantsCaptain = false;
			g_iChefCount--;
		
			if (!g_iChefCount)
				g_bChoixAleatoire = false;
		}
		
		if (bajail[client].g_bWantsCaptainSecours) {
			bajail[client].g_bWantsCaptainSecours = false;
			g_iChefSecoursCount--;
		
			if (!g_iChefSecoursCount)
				g_bChoixAleatoireSecours = false;
		}

		ClientCommand(client, "r_screenoverlay 0");

		SetThirdperson(client, false);

		SetEntityMoveType(client, MOVETYPE_WALK);
		
		SetEntityGravity(client, 1.0);		
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntPropFloat(client, Prop_Data, "m_flGravity", 1.0);
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.5);
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
		
		Client_ScreenFade(client, -1, FFADE_IN|FFADE_PURGE, _, 0, 0, 0, 0);
		SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 0, 4, true);
	}

	bajail[client].g_bClientIsFrozen = false; 
	bajail[client].g_bClientIsAveugled = false; 
	bajail[client].g_bClientIsParalyzed = false; 
	 
	g_PlayerBonus[client].Speed = false; 
	g_PlayerBonus[client].Gravity = false; 
	g_PlayerBonus[client].Invisibility = false; 
	g_PlayerBonus[client].Infirmier = false; 
	g_PlayerBonus[client].Regene = false; 
	g_PlayerBonus[client].Munition_Glacees = 0; 
	g_PlayerBonus[client].Munition_Incendiaires = 0; 
	g_PlayerBonus[client].Munition_Explosives = 0; 
	g_PlayerBonus[client].Munition_Aveuglantes = 0;

	TrashTimer(g_hTimerRegen[client], true);
	TrashTimer(g_hTimerInfirmier[client], true);

	if (bBonusOnly != 2) {
		TrashTimer(g_hTimerInvisibility[client], true);
		TrashTimer(g_hTimerInvisibilityBcn[client], true);
		SetInvisibility(client, true);
	}
}

void Rending(int client) {
	float fPosition[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPosition);
	TeleportEntity(client, fPosition, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));

	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	fClientPos[2] += 10;
										
	SetEntityMoveType(client, MOVETYPE_NONE);
	g_hFreeTimer[client] = CreateTimer(7.0, Timer_Unfreeze, client);
	DisarmClient(client);
	CPrintToChat(client, "%s Vous vous êtes rendu, vous êtes désarmé et immobilisé !", PREFIX);
	LoopClients(i)
		if (IsValidClient(i) && i != client)
			CPrintToChat(i, "%s Le joueur {darkred}%N {default}vient de se rendre !", PREFIX, client);
										
	SetEntityRenderColor(client, 0, 190, 0, 255);
		
	TE_SetupBeamRingPoint(fClientPos, 10.0, 150.0, g_iBeamSprite2, g_iBeamSprite, 0, 15, 0.6, 15.0, 0.0, {128, 128, 0, 255}, 10, 0);
	TE_SendToAll();

	g_iPlayerStuff[client].REND--;
	bajail[client].g_bRending = true;
	bajail[client].g_NoDv = true;
	g_iPlayerStuff[client].GIFT = 0;
	
	char format[128];
	Format(STRING(format), "Rend%s restant%s: %i", (g_iPlayerStuff[client].REND > 1 ? "s" : ""),(g_iPlayerStuff[client].REND > 1 ? "s" : ""), g_iPlayerStuff[client].REND);
	PrintHudMessage(client, format);
}

bool Tazing(int client) {
	int target = GetClientAimTarget(client, true);
	
	if (!IsValidClient(target, true) || GetClientTeam(target) != 2 || bajail[target].g_bRending || bajail[target].g_bTazed)	
		return false;

	if (!IsInZone(client, "(T)")) {
		float fTargetPos[3], fClientPos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", fTargetPos);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fClientPos);
		float fDistance = GetVectorDistance(fTargetPos, fClientPos);

		if (fDistance <= 160) {
			if (!bajail[target].g_bExploding) {
				bajail[target].g_bTazed = true;
				DisarmClient(target, false);
				g_fTazerCount[target] = 7.0;
				g_iPlayerStuff[client].TAZER--;

				EmitSoundToAll(SOUND_TAZER, _, _, _, _, 0.1);
											
				fClientPos[2] += 45;
				fTargetPos[2] += 45;
								
				TE_SetupBeamPoints(fClientPos, fTargetPos, g_iLightingSprite, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, COLOR_TAZER, 3);
				TE_SendToAll();
											
				SetEntityMoveType(target, MOVETYPE_NONE);

				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 })); 
											
				CPrintToChat(client, "%s Vous avez tasé et désarmé {orange}%N{default}.", PREFIX, target);
											
				g_hTazerTimer[target] = CreateTimer(0.1, Timer_TazerRefresh, target, TIMER_REPEAT);

				if (g_iPlayerStuff[client].TAZER) 
				{
					char format[128];
					Format(STRING(format),  "Taser%s restant%s: %i", (g_iPlayerStuff[client].TAZER > 1 ? "s" : ""),(g_iPlayerStuff[client].TAZER > 1 ? "s" : ""), g_iPlayerStuff[client].TAZER);
					PrintHudMessage(client, format);
				}
				return true;
			}
			else
				CPrintToChat(client, "%s Le Prisonnier va bientôt exploser !", PREFIX);
		}
	}
	else
		CPrintToChat(client, "%s Le Prisonnier est en Zone T.", PREFIX);

	return false;
}

void RWing(int client) {
	int entity = GetClientAimTarget(client, false);

	if (entity == INVALID_ENT_REFERENCE || !IsValidEdict(entity) || !IsValidEntity(entity) || IsInZone(client, "(T)"))
		return;

	char Classname[32];
	GetEdictClassname(entity, STRING(Classname));
						
	if (StrContains(Classname, "weapon_", false) != -1) {
		char entityName[64];
		Entity_GetName(entity, STRING(entityName));
		if (StrContains(entityName, "evil_deagle", false) == -1) {
			float fEntityPos[3], fClientPos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fEntityPos);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fClientPos);
			float fDistance = GetVectorDistance(fEntityPos, fClientPos);
								
			if (fDistance <= 160) {
				RemoveEdict(entity);
				g_iPlayerStuff[client].RW--;
				
				char format[128];
				Format(STRING(format),  "RW%s restant%s: %i", (g_iPlayerStuff[client].RW > 1 ? "s" : ""),(g_iPlayerStuff[client].RW > 1 ? "s" : ""), g_iPlayerStuff[client].RW);
				PrintHudMessage(client, format);
				CPrintToChat(client, "%s Vous avez supprimé l'arme au sol.", PREFIX);
			}
		}
	}
}

void Detonate(int client) {
	int ExplosionIndex = CreateEntityByName("env_explosion");
	if (ExplosionIndex != -1) {
		SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 16384);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", 700);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", 350);

		DispatchSpawn(ExplosionIndex);
		ActivateEntity(ExplosionIndex);
		
		float playerEyes[3];
		GetClientEyePosition(client, playerEyes);
		int clientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");

		TeleportEntity(ExplosionIndex, playerEyes, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", clientTeam);

		EmitAmbientSound(SOUND_EXPLODE, NULL_VECTOR, client);
		
		AcceptEntityInput(ExplosionIndex, "Explode");
		
		AcceptEntityInput(ExplosionIndex, "Kill");
	}
}

void DisarmClient(int client, bool RemoveC4 = true) {
	int iWeapon = -1;
	if(RemoveC4) {
		for (int i = CS_SLOT_PRIMARY; i <= MAX_WEAPON_SLOTS; i++) {
			while ((iWeapon = GetPlayerWeaponSlot(client, i)) != -1) {
				RemovePlayerItem(client, iWeapon);
				RemoveEdict(iWeapon);
			}
		}
	}
	else {
		for (int i = CS_SLOT_PRIMARY; i <= 3; i++) {
			while ((iWeapon = GetPlayerWeaponSlot(client, i)) != -1) {
				RemovePlayerItem(client, iWeapon);
				RemoveEdict(iWeapon);
			}
		}
	}
}

void ResetMap() { 
	g_iLastRequest.ISOLOIR = 0;
	g_iLastRequest.BROCHETTE = 0;
	g_iLastRequest.ROULETTE = 0;
	g_iLastRequest.COUTEAU = 0;
	g_iLastRequest.LANCER = 0;
	g_iLastRequest.UNSCOPE = 0;
	g_iLastRequest.SCOPE = 0;
	g_iLastRequest.BASKET = 0;
	g_iLastRequest.COWBOY = 0;
	g_iLastRequest.GRENADE = 0;
	g_iLastRequest.AIM = 0;
	g_iLastRequest.VIP = 0;
	g_iLastRequest.POMPE = 0;
	g_iLastRequest.CHAT = 0;
	g_iLastRequest.PATATE = 0;
	g_iLastRequest.BALLE = 0;
	g_iLastRequest.SULFATEUSE = 0;
		
	g_iGameAnswer = 0;
	g_iChefCount = 0;
	g_iChefSecoursCount = 0;
	g_iDVTimer = 0;
	g_iCowboyTimer = 0;
	g_iEvilBeamCD = 10;
	g_iJailsCooldown = g_iJailTime;
	g_iTimelimit = 600;
	
	g_iMin = 0;
	g_iSec = 0;
	
	if(g_iCdrQr) g_iCdrQr--;

	g_bWaitBall = false;
	g_bLastRequest = false;
	g_bLRWait = false;
	g_bLRDenied = false;
	g_bLRPause = false;
	g_bNoChef = false;
	g_bDernierCT = false;
	g_bQuartierLibre = false;
	g_bChoixAleatoire = false;
	g_bChoixAleatoireSecours = false;
	g_bRoundEnded = false;
	g_bEvilBonus = false;
	g_bEvilSpawned = false;
	g_bArmuIsCt = true;
	g_bQr = false;
	
	SetNoRecoil(false);

	TrashTimer(g_hCheckChef);
	TrashTimer(g_hArmurerieCt);
	TrashTimer(g_hGlobalTimer, true);
}

void PerformSmite(int target) {	
	float clientpos[3];
	GetClientAbsOrigin(target, clientpos);
	clientpos[2] -= 26;
	
	int randomx = GetRandomInt(-500, 500);
	int randomy = GetRandomInt(-500, 500);
	
	float startpos[3];
	startpos[0] = clientpos[0] + randomx;
	startpos[1] = clientpos[1] + randomy;
	startpos[2] = clientpos[2] + 800;
	
	int color[4] = {255, 255, 255, 255};
	float dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupBeamPoints(startpos, clientpos, g_iLightingSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
	
	TE_SetupSparks(clientpos, dir, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(clientpos, dir, false);
	TE_SendToAll();
	
	TE_SetupSmoke(clientpos, g_iSmokeSprite, 5.0, 10);
	TE_SendToAll();
	
	EmitAmbientSound(SOUND_THUNDER, startpos, target, SNDLEVEL_RAIDSIREN);
	
	ForcePlayerSuicide(target);
}

public void Change_Tag(int client) {
	SteamWorks_GetUserGroupStatus(client, 103582791449026401);
	SteamWorks_GetUserGroupStatus(client, 103582791455019392);
	
	if(IsValidClient(client, true) || IsValidClient(client, false)) {
		if (isMe(client)) CS_SetClientClanTag(client, "«Fondateur»");
		else if (isResp(client)) CS_SetClientClanTag(client, "«Responsable»");
		else if (isModo(client)) CS_SetClientClanTag(client, "«Modérateur»");
		else if (isAdmin(client)) CS_SetClientClanTag(client, "«Admin»");
		else if (isVipPlus(client)) CS_SetClientClanTag(client, "«Vìㄕ+ツ»");
		else if (isVip(client)) CS_SetClientClanTag(client, "«Vìㄕツ»");
		else if (bajail[client].g_bisMembre) CS_SetClientClanTag(client, "«Membre»");
		else if (bajail[client].g_bIsFan) CS_SetClientClanTag(client, "- Habitué -");
		else if (!IsPlayerAlive(client) && GetClientTeam(client) != CS_TEAM_SPECTATOR) CS_SetClientClanTag(client, "* Mort *");
		else if (GetClientTeam(client) == CS_TEAM_T) CS_SetClientClanTag(client, "Détenu |");
		else if (GetClientTeam(client) == CS_TEAM_CT && bajail[client].g_bGardienChef) CS_SetClientClanTag(client, "Capitaine |");
		else if (GetClientTeam(client) == CS_TEAM_CT) CS_SetClientClanTag(client, "Gardien |");
		else CS_SetClientClanTag(client, "* Spectateur *");
	}
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool isMember, bool isOfficer)
{
	int client = GetUserAuthID(authid);
	if (client == -1)
		return;

	if (isMember) {
		if (groupAccountID == 103582791468757721) {
			bajail[client].g_bisMembre = true;	//Groupe E-D
		}
		else if (groupAccountID == 103582791468757721) {
			bajail[client].g_bIsFan = true;	//Groupe E-D
		}
	}
	else {
		
		if (groupAccountID == 103582791468757721) {
			bajail[client].g_bisMembre = false;	//Groupe E-D
		}
		else if (groupAccountID == 103582791468757721) {
			bajail[client].g_bIsFan = false;	//Groupe E-D
		}
	}
}

int GetUserAuthID(int authid) {
	LoopClients(i) {
		if (!IsValidClient(i))
			continue;
		
		char authstring[50];
		GetClientAuthId(i, AuthId_Steam3, STRING(authstring));	
		
		char authstring2[50];
		IntToString(authid, STRING(authstring2));
		
		if(StrContains(authstring, authstring2) != -1) {
			return i;
		}
	}

	return -1;
}

void RemoveEntities() { 
	char sEntity[64];
	for (int i = MaxClients; i < GetMaxEntities(); i++) {
		if (i != INVALID_ENT_REFERENCE && IsValidEdict(i) && IsValidEntity(i)) {
			GetEdictClassname(i, STRING(sEntity));
			if (StrEqual(sEntity, "func_physbox") || (StrContains(sEntity, "weapon_") != -1 || StrContains(sEntity, "item_") != -1) && GetEntDataEnt2(i, FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity")) == -1)
				RemoveEdict(i);
		}
	}
}

public void DvSearch(int client) {
	if (g_iLastRequest.BROCHETTE)Format(STRING(g_sDvRunning), "Brochette");
	else if (g_iLastRequest.ISOLOIR)Format(STRING(g_sDvRunning), "Isoloir");
	else if (g_iLastRequest.ROULETTE == 1)Format(STRING(g_sDvRunning), "Roulette Normal");
	else if (g_iLastRequest.ROULETTE == 2)Format(STRING(g_sDvRunning), "Roulette Chinoise");
	else if (g_iLastRequest.ROULETTE == 3)Format(STRING(g_sDvRunning), "Roulette Russe");
	else if (g_iLastRequest.ROULETTE == 4)Format(STRING(g_sDvRunning), "Planche Pirate");
	
	else if (g_iLastRequest.COUTEAU == 1)Format(STRING(g_sDvRunning), "Combat au Couteau");
	else if (g_iLastRequest.COUTEAU == 4)Format(STRING(g_sDvRunning), "Combat au Couteau Aveuglant");
	else if (g_iLastRequest.COUTEAU == 5)Format(STRING(g_sDvRunning), "Combat au Couteau Aquatique");
	else if (g_iLastRequest.COUTEAU == 6)Format(STRING(g_sDvRunning), "Combat au Couteau Interstellaire");
	else if (g_iLastRequest.BASKET)Format(STRING(g_sDvRunning), "Basket");
	else if (g_iLastRequest.LANCER)Format(STRING(g_sDvRunning), "Lancer De Deagle");
	
	else if (g_iLastRequest.UNSCOPE == 1)Format(STRING(g_sDvRunning), "Duel Unscop Awp");
	else if (g_iLastRequest.UNSCOPE == 2)Format(STRING(g_sDvRunning), "Duel Unscop Scout");
	else if (g_iLastRequest.SCOPE == 1)Format(STRING(g_sDvRunning), "Duel Scop Awp");
	else if (g_iLastRequest.SCOPE == 2)Format(STRING(g_sDvRunning), "Duel Scop Scout");
	else if (g_iLastRequest.AIM)Format(STRING(g_sDvRunning), "Aim");
	else if (g_iLastRequest.COWBOY)Format(STRING(g_sDvRunning), "Cowboy");
	
	else if (g_iLastRequest.PATATE)Format(STRING(g_sDvRunning), "Patate chaude");
	else if (g_iLastRequest.BALLE)Format(STRING(g_sDvRunning), "Balle aux prisonniers");
	else if (g_iLastRequest.SULFATEUSE)Format(STRING(g_sDvRunning), "Duel Sulfateuse");
	
	else if (g_iLastRequest.VIP)Format(STRING(g_sDvRunning), "Escorte VIP");
	else if (g_iLastRequest.COUTEAU == 2)Format(STRING(g_sDvRunning), "Cut Vitesse");
	else if (g_iLastRequest.COUTEAU == 3)Format(STRING(g_sDvRunning), "Cut 3rd");
	else if (g_iLastRequest.GRENADE)Format(STRING(g_sDvRunning), "Grenade Paradise");
	else if (g_iLastRequest.POMPE)Format(STRING(g_sDvRunning), "Guerre De Pompes");
	else if (g_iLastRequest.CHAT)Format(STRING(g_sDvRunning), "Chat");
	
	else if (g_bLRDenied)Format(STRING(g_sDvRunning), "Rébellion");
	else Format(STRING(g_sDvRunning), "Dv inconnue");
}

public void StopFlash(int client) {
	SetEntDataFloat(client, g_iFlashAlpha, 0.5);
	SetEntDataFloat(client, g_iFlashDuration, 0.0);
	ClientCommand(client, "dsp_player 0.0");
}

int GetTotalPlayer(int team, bool alive = true) {
	int Total = 0;
	
	LoopClients(i) {
		if(!IsValidClient(i, false))
			continue;
		
		if(!IsPlayerAlive(i) && alive)
			continue;
		
		if(GetClientTeam(i) != team)
			continue;
		
		Total++;
	}
	
	return Total;
}

void TrashTimer(Handle & hTimer, bool bIsRepeat = false) {
	if (hTimer != null) {
		if (bIsRepeat) KillTimer(hTimer);
		else delete hTimer;
		hTimer = null;
	}
}

void GivePlayerItemAny(int client, const char sWeapon[32]) {
	char entityName[32];
	entityName = sWeapon;

	ReplaceString(STRING(entityName), "weapon_", "");
	ReplaceString(STRING(entityName), "_t", "");
	ReplaceString(STRING(entityName), "_ct", "");
	g_sCanUseUnlock[client] = entityName;
	GivePlayerItem(client, sWeapon);
	g_sCanUseUnlock[client] = "none";
}

void SetThirdperson(int client, bool bThirdPerson) {
	static ConVar m_hAllowTP = null;
	if (m_hAllowTP == null)
		m_hAllowTP = FindConVar("sv_allow_thirdperson");

	m_hAllowTP.SetInt(1);

	if (bThirdPerson)
		ClientCommand(client, "thirdperson");
	else
		ClientCommand(client, "firstperson");
}

void SetInvisibility(int client, bool bVisible = false)  { 
	if (IsValidClient(client, true) || client != INVALID_ENT_REFERENCE && IsValidEdict(client) && IsValidEntity(client)) { 
		if (bVisible) {
			SetEntityRenderMode(client, RENDER_NORMAL);
			if (g_iPlayerSmoke[client] != INVALID_ENT_REFERENCE && IsValidEdict(g_iPlayerSmoke[client]) && IsValidEntity(g_iPlayerSmoke[client])) {
				RemoveEdict(g_iPlayerSmoke[client]);
				g_iPlayerSmoke[client] = -1;
			}
		}
		else if (g_iPlayerSmoke[client] == -1) {
			SetEntityRenderMode(client, RENDER_NONE);
			g_iPlayerSmoke[client] = CreateEntityByName("env_smokestack"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "BaseSpread", "0"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "SpreadSpeed", "0"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "Speed", "500"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "StartSize", "5"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "EndSize", "8"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "Rate", "50"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "JetLength", "120"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "SmokeMaterial", SMOKE_PARTICLE); 
			DispatchKeyValue(g_iPlayerSmoke[client], "twist", "3"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "rendercolor", "140 140 255"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "renderamt", "1"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "roll", "5"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "InitialState", "1"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "angles", "0 0 0"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "WindSpeed", "0"); 
			DispatchKeyValue(g_iPlayerSmoke[client], "WindAngle", "0");
			float fOrigin[3];
			GetClientAbsOrigin(client, fOrigin);
			fOrigin[2] -= 20.0;
			TeleportEntity(g_iPlayerSmoke[client], fOrigin, NULL_VECTOR, NULL_VECTOR); 
			DispatchSpawn(g_iPlayerSmoke[client]); 
			AcceptEntityInput(g_iPlayerSmoke[client], "TurnOn"); 
			SetVariantString("!activator"); 
			AcceptEntityInput(g_iPlayerSmoke[client], "SetParent", client, g_iPlayerSmoke[client]);
		}
	} 
}

void CreateConfig() {
	KeyValues kv = new KeyValues("Positions");
	kv.ExportToFile(g_sMapConfigPath);
	delete kv;
}

void SavePosition(const char sLastRequest[512], float fPositionT[3], float fPositionCT[3], float fPositionSpec[3]) {
	KeyValues kv = new KeyValues("Positions");
	kv.ImportFromFile(g_sMapConfigPath);

	kv.JumpToKey(sLastRequest, true);
	kv.SetVector("positionT", fPositionT);
	kv.SetVector("positionCT", fPositionCT);
	kv.SetVector("positionSpec", fPositionSpec);
	kv.GoBack();

	kv.ExportToFile(g_sMapConfigPath);
	delete kv;
}

bool ReadPosition(const char sLastRequest[512], bool bReadOnly = false) {
	bool bExists = false;
	KeyValues kv = new KeyValues("Positions");
	kv.ImportFromFile(g_sMapConfigPath);

	if (kv.JumpToKey(sLastRequest, false)) {
		if (!bReadOnly) {
			kv.GetVector("positionT", g_fReadPos[0]);
			kv.GetVector("positionCT", g_fReadPos[1]);
			kv.GetVector("positionSpec", g_fReadPos[2]);
			if (StrContains(sLastRequest, "button") == -1) {
				g_fReadPos[0][2] += 0.5;
				g_fReadPos[1][2] += 0.5;
				g_fReadPos[2][2] += 0.5;
			}
		}
		bExists = true;
	}
	else
		bExists = false;

	delete kv;

	return bExists;
}

void SaveJailtime(int iJailTime) {
	KeyValues kv = new KeyValues("JailTime");

	kv.JumpToKey("time", true);
	kv.SetNum("value", iJailTime);
	kv.GoBack();

	kv.ExportToFile(g_sMapTimePath);
	delete kv;

	g_iJailTime = iJailTime;
}

bool ReadJailtime() {
	bool bExists = false;
	KeyValues kv = new KeyValues("JailTime");
	if (kv.ImportFromFile(g_sMapTimePath)) {
		kv.JumpToKey("time", false);
		g_iJailTime = kv.GetNum("value");
		bExists = true;
	}
	else
		bExists = false;

	delete kv;

	return bExists;
}

public int ReadJailReasons() {
	char imFile[PLATFORM_MAX_PATH];
	char line[192];
	int i = 0;
	int totalLines = 0;
	
	BuildPath(Path_SM, imFile, sizeof(imFile), "configs/enemy-down/jailreasons.cfg");
	
	Handle file = OpenFile(imFile, "rt");
	
	if(file != INVALID_HANDLE) {
		while (!IsEndOfFile(file)) {
			if (!ReadFileLine(file, line, sizeof(line))) {
				break;
			}
			
			TrimString(line);
			if( strlen(line) > 0 ) {
				FormatEx(g_sPhrases[i],192, "%s", line);
				totalLines++;
			}
			
			i++;

			if( i >= sizeof(g_sPhrases)) {
				LogError("Attempted to add more than the maximum allowed phrases from file");
				break;
			}
		}
				
		CloseHandle(file);
	}
	else {
		LogError("[SM] no file found for phrases (configs/franug_days_jail.ini)");
	}
	
	return totalLines;
}

void SetNoRecoil(bool Enabled = false) 
{
	if(!Enabled) 
	{
		FindConVar("weapon_accuracy_nospread").SetInt(0);
		FindConVar("weapon_recoil_decay1_exp").SetInt(3);
		FindConVar("weapon_recoil_decay2_exp").SetInt(8);
		FindConVar("weapon_recoil_decay2_lin").SetInt(18);
		FindConVar("weapon_recoil_cooldown").SetInt(0);
		FindConVar("weapon_recoil_scale").SetInt(2);
		FindConVar("weapon_air_spread_scale").SetInt(1);
		FindConVar("weapon_recoil_suppression_shots").SetInt(4);
	} 
	else 
	{
		FindConVar("weapon_accuracy_nospread").SetInt(0);
		FindConVar("weapon_recoil_decay1_exp").SetInt(99999);
		FindConVar("weapon_recoil_decay2_exp").SetInt(99999);
		FindConVar("weapon_recoil_decay2_lin").SetInt(99999);
		FindConVar("weapon_recoil_cooldown").SetInt(0);
		FindConVar("weapon_recoil_scale").SetInt(0);
		FindConVar("weapon_air_spread_scale").SetInt(0);
		FindConVar("weapon_recoil_suppression_shots").SetInt(500);
	}
}

void ReBalance(bool bAlive = false) {
	int iCountCT = bAlive ? GetTotalPlayer(3) : GetTeamClientCount(3);
	int iCountT = bAlive ? GetTotalPlayer(2) : GetTeamClientCount(2);

	if (iCountCT == 0 || iCountT == 0)
		return;

	if (1.0 > float(iCountT) / float(iCountCT) || float(iCountT) / float(iCountCT) > 1.5) 
	{
		if (iCountCT > iCountT) 
		{
			while(float(iCountT + 1) / float(iCountCT - 1) <= 1.5) 
			{
				SwitchRandom(3, bAlive ? true : false);
				iCountT++;
				iCountCT--;
			}
		}
		else
		{
			while(float(iCountT - 1) / float(iCountCT + 1) >= 1.5) 
			{
				SwitchRandom(2, bAlive ? true : false);
				iCountT--;
				iCountCT++;
			}
		}
	}
}

void SwitchRandom(int iTeam, bool bAlive) { 
	int Players[MAXPLAYERS + 1];
	int PlayersCount;
	 
	LoopClients(i)
		 if (IsValidClient(i, (bAlive ? true : false)) && GetClientTeam(i) == iTeam && (!bajail[i].g_bGardienChef && iTeam == 3 || !bajail[i].g_bReceptDone && iTeam == 2))
			  Players[PlayersCount++] = i;
	
	if (PlayersCount) {
		int client = Players[GetRandomInt(0, PlayersCount - 1)];	
		
		CS_SwitchTeam(client, iTeam == 2 ? 3 : 2);
		RequestFrame(Frame_Respawn, client);
		PrintHudMessage(client, "Vous avez été auto-assigné.");
	}
}

stock bool PrintKeyHintText(int client, const char[] format, any ...) {
    Handle userMessage = StartMessageOne("KeyHintText", client);
    if (userMessage == INVALID_HANDLE) {
        return false;
    }

    char buffer[1024];
    SetGlobalTransTarget(client);
    VFormat(STRING(buffer), format, 3);
    
    if (GetUserMessageType() == UM_Protobuf) {
        PbAddString(userMessage, "hints", buffer);
    }
    else {
        BfWriteByte(userMessage, 1);
        BfWriteString(userMessage, buffer);
    }
    
    EndMessage();
    return true;
}  

public Action EntrerOuPas(Handle timer) {
    char entName[64];
    float entPos[3];
    int ballIndex = EntRefToEntIndex(ballRef);
    if(ballIndex == -1 || !IsValidEntity(ballIndex)) {
        for(int i = MaxClients; i <= 2048; i++) {
            if(IsValidEntity(i)) {
                GetEntPropString(i, Prop_Send, "m_iName", entName, sizeof(entName));
                if(StrContains(entName, "ballon") != -1) {
                    ballRef = EntIndexToEntRef(i);
                    ballIndex = i;
                    break;
                }
            }
        }
    }
    if(ballIndex != -1 && IsValidEntity(ballIndex)) {
        GetEntPropVector(ballIndex, Prop_Send, "m_vecOrigin", entPos);
        if(posInBox(entPos, GOAL_POST1_MIN, GOAL_POST1_MAX) || posInBox(entPos, GOAL_POST2_MIN, GOAL_POST2_MAX)) {
            TeleportEntity(ballIndex, Middle_Stadium, NULL_VECTOR, NULL_VECTOR);
        }
    }
}

public Action DvChatAction(Handle timer, any client) {
	char sWeapon[64];
	if(IsValidClient(client))
		GetClientWeapon(client, STRING(sWeapon));
	
	if(StrContains(sWeapon, "knife", false) != -1) {
		DisarmClient(client);
		SetEntityHealth(client, 100);
		if (ReadPosition("dv_choice"))
			TeleportEntity(client, g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
		SetEntityMoveType(client, MOVETYPE_NONE);
	}
	else {
		DisarmClient(client);
		GivePlayerItemAny(client, "weapon_ak47");
		GivePlayerItemAny(client, "weapon_deagle");
		GivePlayerItemAny(client, "weapon_knife");
		CPrintToChatAll("%s L'âme du chat est suspendu au milieu de la map", PREFIX);
	}
	
	g_hTimerDvChat[client] = null;
}

public Action Timer_CheckPatateDv(Handle Timer) {
	if(Timer == null)
		return Plugin_Handled;
	
	char sName[64];
	LoopClients(i) {
		if(IsValidClient(i) && bajail[i].g_bHasPatateChaude && (i == g_indexDV[INDEX_T] || i == g_indexDV[INDEX_CT])) {
			GetClientName(i, STRING(sName));
			ForcePlayerSuicide(i);
		}
	}
	
	CPrintToChatAll("%s %s la patate chaude lui a explosé en plein visage !", PREFIX, sName);
	
	return Plugin_Continue;
}

public Action Timer_ArmurerieIsT(Handle Timer) {
	g_bArmuIsCt = false;
	g_hArmurerieCt = null;
}

public Action Timer_Pub(Handle timer) 
{
	CPrintToChatAll("{darkred}▬▬▬▬▬▬▬▬▬▬{lightgreen}ANNONCE{darkred}▬▬▬▬▬▬▬▬▬▬");
	switch (GetRandomInt(1, 6)) 
	{
		case 1:CPrintToChatAll("{yellow}◾️ {default} Tapez {green}!boutique {default}pour accéder à la boutique");
		case 2:CPrintToChatAll("{yellow}◾️ {default} Tapez {green}!plainte {default}pour déposer une plainte");
		case 3:CPrintToChatAll("{yellow}◾️ {default} Adresse de notre forum : {lime}%s", WEB_URL);
		case 4:CPrintToChatAll("{yellow}◾️ {default} Adresse de notre Discord : {lightblue}%s", DISCORD_URL);
		case 5:CPrintToChatAll("{yellow}◾️ {default} Nous recrutons venez sur notre forum pour plus d'informations");
		case 6:CPrintToChatAll("{yellow}◾️ {default} Un serveur Rôleplay est en développement, passez sur notre Discord ! {lightblue}%s", DISCORD_URL);		
	}
	CPrintToChatAll("{darkred}▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");				
}

/******************
* 
*    Droits Serveur
* 
******************/

stock bool isModoTest(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1) return true;
	else return false;
}

stock bool isModo(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM6) return true;
	else return false;
}

stock bool isAdmin(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_GENERIC) return true;
	else return false;
}

stock bool isRooted(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) return true;
	else return false;
}

stock bool isResp(int client) {  
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM2) return true;
	else return false;
}

stock bool isVicePre(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM3) return true;
	else return false;
}

stock bool isVip(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM4 || GetUserFlagBits(client) & ADMFLAG_CUSTOM5) return true;
	else return false;
}

stock bool isVipPlus(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM5) return true;
	else return false;
}

stock bool isTresorier(int client) {
	char idSteam[64];
	GetClientAuthId(client, AuthId_Steam2, STRING(idSteam));
	if(StrContains(idSteam, "1:60522526") != -1)
		return true;
	return false;
}

stock bool isMe(int client) {
	char idSteam[64];
	GetClientAuthId(client, AuthId_Steam2, STRING(idSteam));
	if(StrContains(idSteam, "1:512215951") != -1 
	||StrContains(idSteam, "0:68792182") != -1)
		return true;
	return false;
}

stock bool isMappeur(int client) {
	char idSteam[64];
	GetClientAuthId(client, AuthId_Steam2, STRING(idSteam));
	if(StrContains(idSteam, "1:84219135") != -1)
		return true;
	return false;
}

stock void PrintHudMessage(int client, const char[] typemessage)
{
	if (IsValidClient(client, true))
	{
		SetHudTextParams(-1.0, -0.4, 1.0, 255, 255, 255, 255, 0, 0.00, 0.3, 0.4);
		ShowHudText(client, -1, typemessage);
	}	
}	

stock void PrintHudMessageAll(const char[] typemessage)
{
	LoopClients(i) 
	{
		if (IsValidClient(i, true))
		{
			SetHudTextParams(-1.0, -0.4, 1.0, 255, 255, 255, 255, 0, 0.00, 0.3, 0.4);
			ShowHudText(i, -1, typemessage);
		}
	}		
}	