/*
     ____ _    __
    / __ \ |  / /
   / / / / | / / 
  / /_/ /| |/ /  
 /_____/ |___/   
                
*/

void BuildMenuDv(int client) {
	Menu menu = new Menu(MenuHandler_WantDV);

	menu.SetTitle("Voulez-vous votre Dernière Volonté ?");
	if(bajail[client].g_NoDv) menu.AddItem("Oui", "Oui !", ITEMDRAW_DISABLED);
	else menu.AddItem("Oui", "Oui !");
	menu.AddItem("Non", "Non !");

	menu.ExitButton = false;

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_WantDV(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {		
		char info[64];		
		GetMenuItem(menu, param2, STRING(info));
		
		if (IsValidClient(client, true) && GetTotalPlayer(3) && GetClientTeam(client) == CS_TEAM_T && g_bLRWait) {
			if (StrEqual(info, "Oui")) {
				CPrintToChatAll("%s Le dernier Prisonnier {green}accepte {default}sa Dernière Volonté !", PREFIX);
				DisarmClient(client);
				RemoveEntities();
				SetEntityHealth(client, 100000);
				
				EmitSoundToAll(SOUND_ACCEPTE, _, _, _, _, 0.1);
				
				g_bLRWait = false;
				g_bLastRequest = true;

				g_iTimelimit = 0;

				GenerateDVMenu(client);
				
				LoopClients(i) {
					if (IsValidClient(i, true)) {
						SetEntPropFloat(i, Prop_Data, "m_flGravity", 1.0);
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0); 
						DisarmClient(i);						
						
						if (GetClientTeam(i) == CS_TEAM_CT) {
							ResetClient(i, 1);
							if (g_bDernierCT) {
								switch (GetRandomInt(1,3)) {
									case 1,2: {
										SetEntityModel(i, MODEL_GARDIEN1);
									}
									case 3: {
										SetEntityModel(i, MODEL_GARDIEN2);
									}
								}
							}

							SetEntProp(i, Prop_Send, "m_bHasHelmet", 0); 
							SetEntProp(i, Prop_Send, "m_ArmorValue", 0);
							SetEntityHealth(i, 100);				
						}	
					}
					if (GetTotalPlayer(3) == 1) {
						if (IsValidClient(i) && !IsPlayerAlive(i) && GetClientTeam(i) >= 2) {
							GenerateBetPanel(i);
						}
					}
				}
			}
			else if (StrEqual(info, "Non")) {
				g_indexDV[INDEX_T] = client;
				g_bLRDenied = true;
				g_bLRWait = false;
				CPrintToChatAll("%s Le dernier Prisonnier {darkred}refuse {default}sa Dernière Volonté !", PREFIX);
				
				DisarmClient(g_indexDV[INDEX_T]);
				g_iDVTimer = 0;
				g_iTimelimit += 60;
				if (ReadPosition("dv_no")) {
					TeleportEntity(g_indexDV[INDEX_T], g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
				}
				if (GetTotalPlayer(3) >= 6) {
					CPrintToChatAll("%s Le dernier Prisonnier a volé l'uniforme d'un Gardien !", PREFIX);
					GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_m249");		
					GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_elite");
					GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_hegrenade");
					GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_knife");
					SetEntityHealth(g_indexDV[INDEX_T], 300);
					
					switch (GetRandomInt(1,3)) {
						case 1,2: {
							SetEntityModel(g_indexDV[INDEX_T], MODEL_GARDIEN1);
						}
						case 3: {
							SetEntityModel(g_indexDV[INDEX_T], MODEL_GARDIEN2);
						}
					}
				}
				else if (GetTotalPlayer(3) >= 3) {
					CPrintToChatAll("%s Le dernier Prisonnier a volé l'uniforme d'un Gardien !", PREFIX);
					GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_ak47");
					GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_elite");
					GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_hegrenade");
					GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_knife");
					SetEntityHealth(g_indexDV[INDEX_T], 200);
					
					switch (GetRandomInt(1,3)) {
						case 1,2: {
							SetEntityModel(g_indexDV[INDEX_T], MODEL_GARDIEN1);
						}
						case 3: {
							SetEntityModel(g_indexDV[INDEX_T], MODEL_GARDIEN2);
						}
					}
				}
				else {
					GivePlayerItemAny(client, "weapon_ak47");
					GivePlayerItemAny(client, "weapon_deagle");
					GivePlayerItemAny(client, "weapon_knife_t");					
					SetEntityHealth(client, 100);
				}
				
				SetEntityMoveType(g_indexDV[INDEX_T], MOVETYPE_WALK);
				
				EmitSoundToAll(SOUND_REFUSE, _, _, _, _, 0.1);
			}
		}
	} else if (action == MenuAction_End)
		delete menu;
}

void GenerateDVMenu(int client, int iPage = 1) {
	int iCTCount = GetTotalPlayer(3);

	g_iPage = iPage;

	Panel panel = new Panel(GetMenuStyleHandle(MenuStyle_Radio));

	if (iPage == 1) {
		panel.SetTitle("Choisis une DV !");

		panel.DrawItem("Isoloir", iCTCount > 2 ? (ReadPosition("iso", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Brochette", iCTCount > 2 ? (ReadPosition("brochette", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Roulette", iCTCount < 4 ? (ReadPosition("roulette", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Roulette Chinoise", iCTCount < 4 ? (ReadPosition("roulette_c", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Roulette Russe", iCTCount < 4 ? (ReadPosition("roulette_russe", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Planche Pirate", iCTCount < 4 ? (ReadPosition("planche_pirate", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawItem("Suivant");
		panel.DrawItem("Précedent", ITEMDRAW_DISABLED);
	}
	else if (iPage == 2) {
		panel.SetTitle("Choisis une DV !");

		panel.DrawItem("Combat au Couteau", ReadPosition("couteau", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("Combat au Couteau Aquatique", ReadPosition("cut_aqua", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("Combat au Couteau Interstellaire", ReadPosition("couteau", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("Combat au Couteau Aveuglant", iCTCount < 4 ? (ReadPosition("black_cut", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Basket", iCTCount < 4 ? (ReadPosition("basket", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Lancer de Deagle", ReadPosition("lancer", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawItem("Suivant");
		panel.DrawItem("Précedent");
	}
	else if (iPage == 3) {
		panel.SetTitle("Choisis une DV !");
		
		panel.DrawItem("Unscope AWP", ReadPosition("unscope_awp", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("Unscope Scout", ReadPosition("unscope_scout", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("Scope AWP", ReadPosition("unscope_awp", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("Scope Scout", ReadPosition("unscope_scout", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("Cowboy", ReadPosition("cowboy", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("Aim", ReadPosition("aim", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawItem("Suivant");
		panel.DrawItem("Précedent");
	}
	else if(iPage == 4) {
		panel.SetTitle("Choisis une DV !");
		
		panel.DrawItem("Patate Chaude", iCTCount < 4 ? (ReadPosition("patate_chaude", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Balle au prisonnier", iCTCount < 4 ? (ReadPosition("balle_prisonnier", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Duel sulfateuse", ReadPosition("duel_sulfateuse", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawItem("Suivant");
		panel.DrawItem("Précedent");
	}
	else if (iPage == 5) {
		bool bVIPClient = isVip(client);

		panel.SetTitle("DV VIP");

		panel.DrawItem("Escorte Vip", bVIPClient && iCTCount > 4 ? (ReadPosition("vip", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Cut Vitesse", bVIPClient ? (ReadPosition("couteau_iso", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Cut 3e Personne", bVIPClient ? (ReadPosition("couteau_third", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Grenade Paradise", bVIPClient ? (ReadPosition("grenade", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Guerre pompe", bVIPClient ? (ReadPosition("guerrepompe", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("Chat", bVIPClient ? (ReadPosition("chat", true) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED) : ITEMDRAW_DISABLED);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawItem("Suivant", ITEMDRAW_DISABLED);
		panel.DrawItem("Précedent");
	}

	panel.Send(client, PanelHandler_ChooseDV, MENU_TIME_FOREVER);

	delete panel;

	/*if (!g_iDVTimer) {
		g_iDVTimer = 21;
		g_iTimelimit = 0;
	}*/
}

public Action Command_DV(int client, int args) {
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

	return Plugin_Handled;
}

public int PanelHandler_ChooseDV(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) { 
		if (IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_T && g_bLastRequest && GetTotalPlayer(3)) {
			if (g_iPage == 1) {
				if (param2 == 1) {
					if (ReadPosition("iso")) {
						g_indexDV[INDEX_T] = client;
						RemoveEntities();
						g_bLRPause = true;
						g_iLastRequest.ISOLOIR = 1;
						CPrintToChatAll("☰☰☰ ISOLOIR ☰☰☰");
						PrintHudMessageAll("☰☰☰ ISOLOIR ☰☰☰");
						LoopClients(i) {
							if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) {		
								DisarmClient(i);
								SetEntityHealth(i, 100);
								SetEntityMoveType(i, MOVETYPE_NONE);
								TeleportEntity(i, g_fReadPos[1], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
								bajail[i].g_bLastRequestPlayer = true;
								g_hDVInitialize[i] = CreateTimer(3.0, Timer_DVInitialize, i);
								SetEntityRenderMode(i, RENDER_NORMAL);	
								SetEntityRenderColor(i, 0, 100, 255, 255);
							}
						}
						
						EmitSoundToAll(SOUND_DVSTART, _, _, _, _, 0.1);
						DisarmClient(g_indexDV[INDEX_T]);
						bajail[g_indexDV[INDEX_T]].g_bLastRequestPlayer = true;
						TeleportEntity(g_indexDV[INDEX_T], g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));					
						SetEntityHealth(g_indexDV[INDEX_T], 100);					
						SetEntityMoveType(g_indexDV[INDEX_T], MOVETYPE_NONE);			
						SetEntityRenderMode(g_indexDV[INDEX_T], RENDER_NORMAL);			
						SetEntityRenderColor(g_indexDV[INDEX_T], 255, 30, 0, 255);
						g_hDVInitialize[g_indexDV[INDEX_T]] = CreateTimer(3.0, Timer_DVInitialize, g_indexDV[INDEX_T]);

						g_iDVTimer = 0;
						g_iTimelimit = 90;
					}
					else {
						CPrintToChat(g_indexDV[INDEX_T], "%s Cette DV n'est pas encore configurée.", PREFIX);
						GenerateDVMenu(g_indexDV[INDEX_T]);
					}
				}
				else if (param2 == 2)	{
					if (ReadPosition("brochette")) {
						g_indexDV[INDEX_T] = client;
						RemoveEntities();
						g_bLRPause = false;
						g_iLastRequest.BROCHETTE = 1;					
						CPrintToChatAll("☰☰☰ BROCHETTE ☰☰☰");
						PrintHudMessageAll("☰☰☰ BROCHETTE ☰☰☰");
						LoopClients(i) {
							if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) {
								DisarmClient(i);
								SetEntityMoveType(i, MOVETYPE_NONE);
								TeleportEntity(i, g_fReadPos[1], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
								bajail[i].g_bLastRequestPlayer = true;
								SetEntityHealth(i, 100);
								SetEntityRenderMode(i, RENDER_NORMAL);	
								SetEntityRenderColor(i, 0, 100, 255, 255);
								GivePlayerItemAny(i, "weapon_m4a1_silencer");
								GivePlayerItemAny(i, "weapon_knife");
							}
						}					
						
						EmitSoundToAll(SOUND_DVSTART, _, _, _, _, 0.1);
						DisarmClient(g_indexDV[INDEX_T]);
						bajail[g_indexDV[INDEX_T]].g_bLastRequestPlayer = true;
						TeleportEntity(g_indexDV[INDEX_T], g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));			
						SetEntityRenderMode(g_indexDV[INDEX_T], RENDER_NORMAL);	
						SetEntityRenderColor(g_indexDV[INDEX_T], 255, 30, 0, 255);					
						SetEntityHealth(g_indexDV[INDEX_T], 200);					
						SetEntityMoveType(g_indexDV[INDEX_T], MOVETYPE_NONE);
						GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_awp");
						GivePlayerItemAny(g_indexDV[INDEX_T], "weapon_knife_t");
						g_bWaitBall = true;

						g_iDVTimer = 0;
						g_iTimelimit = 90;
					}
					else {
						CPrintToChat(g_indexDV[INDEX_T], "%s Cette DV n'est pas encore configurée.", PREFIX);
						GenerateDVMenu(g_indexDV[INDEX_T]);
					}
				}
				else if (param2 == 3)
					g_iLastRequest.ROULETTE = 1;
				else if (param2 == 4)
					g_iLastRequest.ROULETTE = 2;
				else if (param2 == 5)
					g_iLastRequest.ROULETTE = 3;
				else if (param2 == 6)
					g_iLastRequest.ROULETTE = 4;

			}
			else if (g_iPage == 2) {
				if (param2 == 1)
					g_iLastRequest.COUTEAU = 1;
				else if (param2 == 2)
					g_iLastRequest.COUTEAU = 5;
				else if (param2 == 3)
					g_iLastRequest.COUTEAU = 6;
				else if (param2 == 4)
					g_iLastRequest.COUTEAU = 4;
				else if (param2 == 5)
					g_iLastRequest.BASKET = 1;
				else if (param2 == 6)
					g_iLastRequest.LANCER = 1;					
			}
			else if(g_iPage == 3) {
				if(param2 == 1)
					g_iLastRequest.UNSCOPE = 1;
				else if(param2 == 2)
					g_iLastRequest.UNSCOPE = 2;
				else if(param2 == 3)
					g_iLastRequest.SCOPE = 1;
				else if(param2 == 4)
					g_iLastRequest.SCOPE = 2;
				else if(param2 == 5)
					g_iLastRequest.COWBOY = 1;
				else if(param2 == 6)
					g_iLastRequest.AIM = 1;					
			}
			else if (g_iPage == 4) {
				if(param2 == 1)
					g_iLastRequest.PATATE = 1;
				else if(param2 == 2)
					g_iLastRequest.BALLE = 1;
				else if(param2 == 3)
					g_iLastRequest.SULFATEUSE = 1;
			}
			else if (g_iPage == 5) {
				if (param2 == 1) {
					if (ReadPosition("vip")) {
						g_indexDV[INDEX_T] = client;
						RemoveEntities();
						g_bLRPause = true;
						g_iLastRequest.VIP = 1;
						int iPlayers[MAXPLAYERS + 1];
						int iPlayersCount;
				
						CPrintToChatAll("☰☰☰ ESCORTE VIP ☰☰☰");
						PrintHudMessageAll("☰☰☰ ESCORTE VIP ☰☰☰");
				
						LoopClients(i) {
							if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) {
								iPlayers[iPlayersCount++] = i;
							}
						}
						
						g_iLastRequest.VIP = 1;
						g_indexDV[INDEX_VIP] = iPlayers[GetRandomInt(0, iPlayersCount-1)];
						
						LoopClients(i) {
							if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) {		
								DisarmClient(i);
								SetEntityHealth(i, 100);
								SetEntityMoveType(i, MOVETYPE_NONE);
								TeleportEntity(i, g_fReadPos[1], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
								bajail[i].g_bLastRequestPlayer = true;
								g_hDVInitialize[i] = CreateTimer(3.0, Timer_DVInitialize, i);
								SetEntityRenderMode(i, RENDER_NORMAL);	
								SetEntityRenderColor(i, 0, 100, 255, 255);
								SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
							}
						}

						SetEntProp(g_indexDV[INDEX_VIP], Prop_Data, "m_takedamage", 2, 1);
						SetEntityModel(g_indexDV[INDEX_VIP], MODEL_VIP);
						SetEntPropString(g_indexDV[INDEX_VIP], Prop_Send, "m_szArmsModel", ARMS_VIP);
						
						CPrintToChatAll("%s %N est le VIP il doit avoir une protection digne de son grade !", PREFIX, g_indexDV[INDEX_VIP]);
	
						SetEntProp(g_indexDV[INDEX_T], Prop_Data, "m_takedamage", 0, 1);
						DisarmClient(g_indexDV[INDEX_T]);
						bajail[g_indexDV[INDEX_T]].g_bLastRequestPlayer = true;
						TeleportEntity(g_indexDV[INDEX_T], g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));					
						SetEntityHealth(g_indexDV[INDEX_T], 100);					
						SetEntityMoveType(g_indexDV[INDEX_T], MOVETYPE_NONE);			
						SetEntityRenderMode(g_indexDV[INDEX_T], RENDER_NORMAL);			
						SetEntityRenderColor(g_indexDV[INDEX_T], 255, 30, 0, 255);
						g_hDVInitialize[g_indexDV[INDEX_T]] = CreateTimer(3.0, Timer_DVInitialize, g_indexDV[INDEX_T]);
						
						EmitSoundToAll(SOUND_DVSTART, _, _, _, _, 0.1);

						g_iDVTimer = 0;
						g_iTimelimit = 45;
					}
				}
				else if (param2 == 2)
					g_iLastRequest.COUTEAU = 2;
				else if (param2 == 3)
					g_iLastRequest.COUTEAU = 3;
				else if (param2 == 4)
					g_iLastRequest.GRENADE = 1;
				else if (param2 == 5)
					g_iLastRequest.POMPE = 1;
				else if (param2 == 6)
					g_iLastRequest.CHAT = 1;
			}
			
			if(g_iDVTimer != 0)
				g_iDVTimer = 0;
				
			if (param2 < 8 && !g_iLastRequest.ISOLOIR && !g_iLastRequest.BROCHETTE && !g_iLastRequest.VIP) {
				ChooseOpponent(client);				
				RemoveEntities();
			}
			else if (!g_iLastRequest.ISOLOIR && !g_iLastRequest.BROCHETTE && !g_iLastRequest.VIP)
				GenerateDVMenu(client, param2 == 8 ? g_iPage + 1 : g_iPage - 1);
		}
	}
}

void ChooseOpponent(int client) {
	if (IsValidClient(client, true)) {
		char sUserID[12], sName[MAX_NAME_LENGTH];

		Menu menu = new Menu(MenuHandler_EnemyChoosen);

		menu.SetTitle("Adversaire :");

		LoopClients(i) {
			if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT) {
				IntToString(GetClientUserId(i), STRING(sUserID));				
				GetClientName(i, STRING(sName));

				menu.AddItem(sUserID, sName);
			}
		}

		menu.ExitButton = false;

		menu.Display(client, MENU_TIME_FOREVER);

		//g_iDVTimer = 21;
	}
}

public int MenuHandler_EnemyChoosen(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {		
		if (IsValidClient(client, true) && GetClientTeam(client) == CS_TEAM_T && g_bLastRequest && GetTotalPlayer(3)) {			
			char info[11];			
			GetMenuItem(menu, param2, STRING(info));

			int enemy = GetClientOfUserId(StringToInt(info));
			
			g_indexDV[INDEX_T] = client;
			g_indexDV[INDEX_CT] = enemy;
			
			if (IsValidClient(g_indexDV[INDEX_CT], true)) {
				float fWaitTime = -1.0;
				if (g_iLastRequest.ROULETTE == 1 && ReadPosition("roulette")) {
					CPrintToChatAll("☰☰☰ ROULETTE ☰☰☰");
					PrintHudMessageAll("☰☰☰ ROULETTE ☰☰☰");
					fWaitTime = 1.0;
				}
				else if (g_iLastRequest.ROULETTE == 2 && ReadPosition("roulette_c")) { 
					CPrintToChatAll("☰☰☰ ROULETTE CHINOISE ☰☰☰");
					PrintHudMessageAll("☰☰☰ ROULETTE CHINOISE ☰☰☰");
					fWaitTime = 1.0;
					
					SetNoRecoil(true);
				}
				else if (g_iLastRequest.ROULETTE == 3 && ReadPosition("roulette_russe")) { 
					CPrintToChatAll("☰☰☰ ROULETTE RUSSE ☰☰☰");
					PrintHudMessageAll("☰☰☰ ROULETTE RUSSE ☰☰☰");
					fWaitTime = 1.0;
				}
				else if (g_iLastRequest.ROULETTE == 4 && ReadPosition("planche_pirate")) { 
					CPrintToChatAll("☰☰☰ PLANCHE PIRATE ☰☰☰");
					PrintHudMessageAll("☰☰☰ PLANCHE PIRATE ☰☰☰");
					fWaitTime = 1.0;
					
					SetNoRecoil(true);
				}
				else if (g_iLastRequest.COUTEAU == 1 && ReadPosition("couteau")) { 
					CPrintToChatAll("☰☰☰ COMBAT AU COUTEAU ☰☰☰");
					PrintHudMessageAll("☰☰☰ COMBAT AU COUTEAU ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.COUTEAU == 2 && ReadPosition("couteau_iso")) { 
					CPrintToChatAll("☰☰☰ COUTEAU AU COUTEAU RAPIDE ☰☰☰");
					PrintHudMessageAll("☰☰☰ COUTEAU AU COUTEAU RAPIDE ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.COUTEAU == 3 && ReadPosition("couteau_third")) { 
					CPrintToChatAll("☰☰☰ COMBAT AU COUTEAU 3ème personne ☰☰☰");
					PrintHudMessageAll("☰☰☰ COMBAT AU COUTEAU 3ème personne ☰☰☰");
					SetThirdperson(g_indexDV[INDEX_T], true);						
					SetThirdperson(g_indexDV[INDEX_CT], true);
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.COUTEAU == 4 && ReadPosition("black_cut")) { 
					CPrintToChatAll("☰☰☰ COMBAT AU COUTEAU AVEUGLANT ☰☰☰");
					PrintHudMessageAll("☰☰☰ COMBAT AU COUTEAU AVEUGLANT ☰☰☰");
					Client_ScreenFade(g_indexDV[INDEX_T], 9999, FFADE_IN|FFADE_PURGE, 9999, 0, 0, 0, 255);
					Client_ScreenFade(g_indexDV[INDEX_CT], 9999, FFADE_IN|FFADE_PURGE, 9999, 0, 0, 0, 255);
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.COUTEAU == 5 && ReadPosition("cut_aqua")) { 
					CPrintToChatAll("☰☰☰ COMBAT AU COUTEAU AQUATIQUE ☰☰☰");
					PrintHudMessageAll("☰☰☰ COMBAT AU COUTEAU AQUATIQUE ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.COUTEAU == 6 && ReadPosition("couteau")) { 
					CPrintToChatAll("☰☰☰ COMBAT AU COUTEAU INTERSTELLAIRE ☰☰☰");
					PrintHudMessageAll("☰☰☰ COMBAT AU COUTEAU INTERSTELLAIRE ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.LANCER && ReadPosition("lancer")) { 
					CPrintToChatAll("☰☰☰ LANCER DE DEAGLE ☰☰☰");
					PrintHudMessageAll("☰☰☰ LANCER DE DEAGLE ☰☰☰");
					fWaitTime = 1.0;
				}
				else if (g_iLastRequest.UNSCOPE == 1 && ReadPosition("unscope_awp")) { 		
					CPrintToChatAll("☰☰☰ UNSCOPE AWP ☰☰☰");
					PrintHudMessageAll("☰☰☰ UNSCOPE AWP ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.UNSCOPE == 2 && ReadPosition("unscope_scout")) { 	
					CPrintToChatAll("☰☰☰ UNSCOPE SCOUT ☰☰☰");
					PrintHudMessageAll("☰☰☰ UNSCOPE SCOUT ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.SCOPE == 1 && ReadPosition("unscope_awp")) {
					CPrintToChatAll("☰☰☰ SCOPE AWP ☰☰☰");
					PrintHudMessageAll("☰☰☰ SCOPE AWP ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.SCOPE == 2 && ReadPosition("unscope_scout")) {
					CPrintToChatAll("☰☰☰ SCOPE SCOUT ☰☰☰");
					PrintHudMessageAll("☰☰☰ SCOPE SCOUT ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.BASKET && ReadPosition("basket")) { 		
					CPrintToChatAll("☰☰☰ BASKET ☰☰☰");
					PrintHudMessageAll("☰☰☰ BASKET ☰☰☰");
					fWaitTime = 1.0;
				}
				else if (g_iLastRequest.COWBOY && ReadPosition("cowboy")) { 		
					CPrintToChatAll("☰☰☰ COWBOY ☰☰☰");
					//PrintHudMessageAll("☰☰☰ COWBOY ☰☰☰");
					g_iCowboy[g_indexDV[INDEX_T]].COWBOY = true;
					g_iCowboy[g_indexDV[INDEX_CT]].COWBOY = true;
					PrintHudMessage(g_indexDV[INDEX_T], "Prépares-toi à dégainer ton arme !");
					PrintHudMessage(g_indexDV[INDEX_CT], "Prépares-toi à dégainer ton arme !");
					g_iCowboyTimer = GetRandomInt(3, 7);
					EmitSoundToClient(g_indexDV[INDEX_T], SOUND_COWBOY, _, _, _, _, 0.1);
					EmitSoundToClient(g_indexDV[INDEX_CT], SOUND_COWBOY, _, _, _, _, 0.1);
					fWaitTime = 0.0;
				}
				else if (g_iLastRequest.GRENADE && ReadPosition("grenade")) { 	
					CPrintToChatAll("☰☰☰ GRENADE PARADISE ☰☰☰");
					PrintHudMessageAll("☰☰☰ GRENADE PARADISE ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.AIM && ReadPosition("aim")) { 		
					CPrintToChatAll("☰☰☰ AIM ☰☰☰");
					PrintHudMessageAll("☰☰☰ AIM ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.POMPE && ReadPosition("guerrepompe")) { 		
					CPrintToChatAll("☰☰☰ GUERRE DE POMPES ☰☰☰");
					PrintHudMessageAll("☰☰☰ GUERRE DE POMPES ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.PATATE && ReadPosition("patate_chaude")) { 		
					CPrintToChatAll("☰☰☰ PATATE CHAUDE ☰☰☰");
					PrintHudMessageAll("☰☰☰ PATATE CHAUDE ☰☰☰");
					fWaitTime = 3.0;
					
					g_hDVTimerPatate = CreateTimer(GetRandomFloat(10.0, 20.0)+fWaitTime, Timer_CheckPatateDv);
				}
				else if (g_iLastRequest.CHAT && ReadPosition("chat")) { 		
					CPrintToChatAll("☰☰☰ CHAT ☰☰☰");
					PrintHudMessageAll("☰☰☰ CHAT ☰☰☰");
					fWaitTime = 3.0;
					
					switch(GetRandomInt(1,2)) {
						case 1:g_bIsChat[g_indexDV[INDEX_T]] = true;
						case 2:g_bIsChat[g_indexDV[INDEX_CT]] = true;
					}
					
					g_fTempsChat = GetRandomFloat(10.0, 30.0);
				} 
				else if (g_iLastRequest.SULFATEUSE && ReadPosition("duel_sulfateuse")) { 		
					CPrintToChatAll("☰☰☰ DUEL SULFATEUSE ☰☰☰");
					PrintHudMessageAll("☰☰☰ DUEL SULFATEUSE ☰☰☰");
					fWaitTime = 3.0;
				}
				else if (g_iLastRequest.BALLE && ReadPosition("balle_prisonnier")) { 		
					CPrintToChatAll("☰☰☰ BALLE AUX PRISONNIERS ☰☰☰");
					PrintHudMessageAll("☰☰☰ BALLE AUX PRISONNIERS ☰☰☰");
					fWaitTime = 3.0;
				}
				
				if (fWaitTime != -1.0) {
					EmitSoundToAll(SOUND_DVSTART, _, _, _, _, 0.1);
						
					TeleportEntity(g_indexDV[INDEX_T], g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
					TeleportEntity(g_indexDV[INDEX_CT], g_fReadPos[1], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
						
					DisarmClient(g_indexDV[INDEX_T]);
					DisarmClient(g_indexDV[INDEX_CT]);
						
					SetEntityRenderMode(g_indexDV[INDEX_T], RENDER_NORMAL);
					SetEntityRenderMode(g_indexDV[INDEX_CT], RENDER_NORMAL); 
					SetEntityRenderColor(g_indexDV[INDEX_T], 255, 30, 0, 255);
					SetEntityRenderColor(g_indexDV[INDEX_CT], 0, 100, 255, 255);
								
					SetEntityMoveType(g_indexDV[INDEX_T], MOVETYPE_NONE);
					SetEntityMoveType(g_indexDV[INDEX_CT], MOVETYPE_NONE);
						
					SetEntityHealth(g_indexDV[INDEX_T], 1000);
					SetEntityHealth(g_indexDV[INDEX_CT], 1000);

					bajail[g_indexDV[INDEX_T]].g_bLastRequestPlayer = true;
					bajail[g_indexDV[INDEX_CT]].g_bLastRequestPlayer = true;
						
					SetEntPropFloat(g_indexDV[INDEX_CT], Prop_Send, "m_flFlashDuration", 0.5);
						
					LoopClients(i) {
						if (IsValidClient(i, true) && GetClientTeam(i) == CS_TEAM_CT && !bajail[i].g_bLastRequestPlayer) {
							TeleportEntity(i, g_fReadPos[2], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
							SetEntityRenderMode(i, RENDER_NONE); 
							SetEntityMoveType(i, MOVETYPE_NONE);
							SetEntPropFloat(i, Prop_Send, "m_flFlashDuration", 3600.0);
						}
					}

					g_hDVInitialize[g_indexDV[INDEX_T]] = CreateTimer(fWaitTime, Timer_DVInitialize, g_indexDV[INDEX_T]);
					g_hDVInitialize[g_indexDV[INDEX_CT]] = CreateTimer(fWaitTime, Timer_DVInitialize, g_indexDV[INDEX_CT]);						

					CPrintToChatAll("%s {darkred}%N {default}a choisi {lightblue}%N {default}!", PREFIX, g_indexDV[INDEX_T], g_indexDV[INDEX_CT]);	
						
					g_bLRPause = true;

					g_iDVTimer = 0;
					g_iTimelimit = 60;
				}
				else {
					g_iLastRequest.ROULETTE = false;
					g_iLastRequest.COUTEAU = false;
					g_iLastRequest.LANCER = false;
					g_iLastRequest.UNSCOPE = false;
					g_iLastRequest.SCOPE = false;
					g_iLastRequest.BASKET = false;
					g_iLastRequest.COWBOY = false;
					g_iLastRequest.GRENADE = false;
					g_iLastRequest.AIM = false;
					g_iLastRequest.POMPE = false;
					g_iLastRequest.CHAT = false;
					g_iLastRequest.PATATE = false;
					CPrintToChat(g_indexDV[INDEX_T], "%s Cette DV n'est pas encore configurée.", PREFIX);
					GenerateDVMenu(g_indexDV[INDEX_T]);
				}
			}
			else {
				CPrintToChat(g_indexDV[INDEX_T], "%s Ce joueur n'est plus disponible.", PREFIX);
				ChooseOpponent(g_indexDV[INDEX_T]);
			}
		}
		else
			CPrintToChat(g_indexDV[INDEX_T], "%s Vous n'êtes pas en dernière volonté.", PREFIX);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action Timer_DVInitialize(Handle timer, any client) {
	if (IsValidClient(client, true)) {
		if (g_iLastRequest.ISOLOIR) {
			SetEntityMoveType(client, MOVETYPE_WALK);
			GivePlayerItemAny(client, "weapon_m249");
			if (client == g_indexDV[INDEX_T])
				SetEntityHealth(client, 200);
			else if (GetClientTeam(client) == CS_TEAM_CT)
				SetEntityHealth(client, 100);
		}
		else if (g_iLastRequest.ROULETTE) {
			SetEntityHealth(client, 100);
			if(g_iLastRequest.ROULETTE != 3) SetEntityMoveType(client, MOVETYPE_WALK);
			else SetEntityMoveType(client, MOVETYPE_NONE);
			if (client == g_indexDV[INDEX_T]) GivePlayerItemAny(client, "weapon_deagle");
			else if (client == g_indexDV[INDEX_CT]) GivePlayerItemAny(client, "weapon_knife");
		}
		else if (g_iLastRequest.COUTEAU) { 
			SetEntityMoveType(client, MOVETYPE_WALK);
			SetEntityHealth(client, 100);
			if(g_iLastRequest.COUTEAU == 2) SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 2.0);
			if(g_iLastRequest.COUTEAU == 6) SetEntityGravity(client, 0.3);
			if (client == g_indexDV[INDEX_T]) GivePlayerItemAny(client, "weapon_knife_t");
			else if (client == g_indexDV[INDEX_CT]) GivePlayerItemAny(client, "weapon_knife");
		}
		else if (g_iLastRequest.LANCER) { 
			SetEntityHealth(client, 100);
			SetEntityMoveType(client, MOVETYPE_WALK);
			GivePlayerItemAny(client, "weapon_deagle");
		}
		else if (g_iLastRequest.UNSCOPE || g_iLastRequest.SCOPE) { 
			SetEntityHealth(client, 100);
			SetEntityMoveType(client, MOVETYPE_WALK);
			if (client == g_indexDV[INDEX_T]) GivePlayerItemAny(client, "weapon_knife_t");
			else if (client == g_indexDV[INDEX_CT]) GivePlayerItemAny(client, "weapon_knife");
			if(g_iLastRequest.UNSCOPE == 1 || g_iLastRequest.SCOPE == 1) GivePlayerItemAny(client, "weapon_awp");
			else GivePlayerItemAny(client, "weapon_ssg08");
			EmitSoundToAll(SOUND_NOSCOPE, _, _, _, _, 0.1);
		}
		else if (g_iLastRequest.BASKET) { 
			SetEntityHealth(client, 100);
			SetEntityMoveType(client, MOVETYPE_WALK);
			GivePlayerItemAny(client, "weapon_deagle");
		}
		else if (g_iLastRequest.COWBOY) { 
			SetEntityHealth(client, 100);
		}
		else if (g_iLastRequest.GRENADE) { 
			SetEntityHealth(client, 100);
			SetEntityMoveType(client, MOVETYPE_WALK);
			GivePlayerItemAny(client, "weapon_hegrenade");
		}
		else if (g_iLastRequest.AIM) { 	
			SetEntityHealth(client, 100);
			SetEntityMoveType(client, MOVETYPE_WALK);
			if (client == g_indexDV[INDEX_T]) GivePlayerItemAny(client, "weapon_knife_t");
			else if (client == g_indexDV[INDEX_CT]) GivePlayerItemAny(client, "weapon_knife");
			GivePlayerItemAny(client, "weapon_ak47");
		}
		else if (g_iLastRequest.VIP) {	
			SetEntityHealth(client, 100);
			SetEntityMoveType(client, MOVETYPE_WALK);
			if (client == g_indexDV[INDEX_T]) {
				GivePlayerItemAny(client, "weapon_ak47");
				GivePlayerItemAny(client, "weapon_deagle");
				GivePlayerItemAny(client, "weapon_knife_t");
			}
			else {
				GivePlayerItemAny(client, "weapon_knife");
			}
		}
		else if (g_iLastRequest.POMPE) { 	
			SetEntityHealth(client, 100);
			SetEntityMoveType(client, MOVETYPE_WALK);
			if (client == g_indexDV[INDEX_T]) GivePlayerItemAny(client, "weapon_knife_t");
			else if (client == g_indexDV[INDEX_CT]) GivePlayerItemAny(client, "weapon_knife");
			GivePlayerItemAny(client, "weapon_sawedoff");
		}
		else if (g_iLastRequest.CHAT) { 	
			SetEntityHealth(client, 100000);
			SetEntityMoveType(client, MOVETYPE_WALK);
			g_hTimerDvChat[client] = CreateTimer(g_fTempsChat, DvChatAction, client);
			if (g_bIsChat[client]) {
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.25);
				if (client == g_indexDV[INDEX_T]) GivePlayerItemAny(client, "weapon_knife_t");
				else if (client == g_indexDV[INDEX_CT]) GivePlayerItemAny(client, "weapon_knife");
				CPrintToChatAll("%s {darkred}%N {default} est le chat !", PREFIX, client);
				
			}
		}
		else if (g_iLastRequest.PATATE) { 	
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntityHealth(client, 100);
			if (client == g_indexDV[INDEX_T]) {
				GivePlayerItemAny(client, "weapon_deagle");
				CPrintToChat(client, "%s Tu viens d'obtenir la patate chaude débarasses-toi en vite !", PREFIX);
				bajail[client].g_bHasPatateChaude = true;
			}
		}
		else if (g_iLastRequest.SULFATEUSE) { 
			SetEntityMoveType(client, MOVETYPE_WALK);			
			SetEntityHealth(client, 100);
			GivePlayerItemAny(client, "weapon_m249");
			if(client == g_indexDV[INDEX_T]) GivePlayerItemAny(client, "weapon_knife_t");
			else GivePlayerItemAny(client, "weapon_knife");
		}
		else if (g_iLastRequest.BALLE) {
			SetEntityMoveType(client, MOVETYPE_WALK);			
			SetEntityHealth(client, 1);
			GivePlayerItemAny(client, "weapon_flashbang");
			SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 5, 4, true);
			SetEntityGravity(client, 0.2);
		}

		g_bLRPause = false;

		g_hDVInitialize[client] = null;
	}
}