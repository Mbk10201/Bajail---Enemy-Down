/*
	_____ __                
   / ___// /_____  ________ 
   \__ \/ __/ __ \/ ___/ _ \
  ___/ / /_/ /_/ / /  /  __/
 /____/\__/\____/_/   \___/ 
                           
*/

void OpenStore(int client) {
	bool bVIPClient = isVip(client);
	char sBuffer[64];

	char iStoreItemsItem[32][16], iStoreItemsName[32][32];
	int iStoreItemsPrice[32];
	bool iStoreItemsVIP[32];

	if (GetClientTeam(client) == CS_TEAM_T) {
		iStoreItemsItem[0] = "gift"; iStoreItemsName[0] = "[VIP] !gift"; iStoreItemsPrice[0] = 250; iStoreItemsVIP[0] = true;
		iStoreItemsItem[1] = "usp"; iStoreItemsName[1] = "USP"; iStoreItemsPrice[1] = 500; iStoreItemsVIP[1] = false;
		iStoreItemsItem[2] = "deagle"; iStoreItemsName[2] = "[VIP] Deagle"; iStoreItemsPrice[2] = 750; iStoreItemsVIP[2] = true;
		iStoreItemsItem[3] = "jailvip"; iStoreItemsName[3] = "[VIP] Jail VIP"; iStoreItemsPrice[3] = 750; iStoreItemsVIP[3] = true;
		iStoreItemsItem[4] = "hp"; iStoreItemsName[4] = "+15 HP"; iStoreItemsPrice[4] = 150; iStoreItemsVIP[4] = false;
		iStoreItemsItem[5] = "speed"; iStoreItemsName[5] = "Vitesse"; iStoreItemsPrice[5] = 500; iStoreItemsVIP[5] = false;
	}
	else if (GetClientTeam(client) == CS_TEAM_CT) {
		iStoreItemsItem[0] = "gift"; iStoreItemsName[0] = "[VIP] !gift"; iStoreItemsPrice[0] = 250; iStoreItemsVIP[0] = true;
		iStoreItemsItem[1] = "tazer"; iStoreItemsName[1] = "!tazer"; iStoreItemsPrice[1] = 150; iStoreItemsVIP[1] = false;
		iStoreItemsItem[2] = "hp"; iStoreItemsName[2] = "+15 HP"; iStoreItemsPrice[2] = 150; iStoreItemsVIP[2] = false;
		iStoreItemsItem[3] = "speed"; iStoreItemsName[3] = "Vitesse"; iStoreItemsPrice[3] = 500; iStoreItemsVIP[3] = false;
	}

	Menu menu = new Menu(MenuHandler_Store);

	menu.SetTitle("Boutique%s :", bVIPClient ? " (-20%)" : "");

	for (int i = 0; i < (GetClientTeam(client) == CS_TEAM_T ? 6 : 3); i++) {
		Format(STRING(sBuffer), "%s (%i pts)", iStoreItemsName[i], bVIPClient ? RoundToFloor(iStoreItemsPrice[i] * 0.8) : iStoreItemsPrice[i]);
		menu.AddItem(iStoreItemsItem[i], sBuffer, (bVIPClient && iStoreItemsPrice[i] || !iStoreItemsVIP[i]) && g_iPlayerStuff[client].POINTS >= (bVIPClient ? RoundToFloor(iStoreItemsPrice[i] * 0.8) : iStoreItemsPrice[i]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);	
}

public int MenuHandler_Store(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		char info[32]; 
		GetMenuItem(menu, param2, STRING(info));	
		
		if (IsValidClient(client, true)) {
			if (g_hDatabase != null) {
				if (GetTotalPlayer(2) > 1) {
					int Health = GetClientHealth(client);
					bool bVIPClient = isVip(client);

					char iStoreItemsItem[32][16];
					int iStoreItemsPrice[32];

					iStoreItemsItem[0] = "gift"; iStoreItemsPrice[0] = 250;
					iStoreItemsItem[1] = "tazer"; iStoreItemsPrice[1] = 150;
					iStoreItemsItem[2] = "usp"; iStoreItemsPrice[2] = 500;
					iStoreItemsItem[3] = "deagle"; iStoreItemsPrice[3] = 750;
					iStoreItemsItem[4] = "jailvip"; iStoreItemsPrice[4] = 750;
					iStoreItemsItem[5] = "hp"; iStoreItemsPrice[5] = 150;
					iStoreItemsItem[6] = "speed"; iStoreItemsPrice[6] = 500;
					
					if (g_iPlayerStuff[client].POINTS >= 100 || bVIPClient && g_iPlayerStuff[client].POINTS >= 80)
						OpenStore(client);
					
					if (StrEqual(info, iStoreItemsItem[0])) {
						if (!bajail[client].g_bReceptDone && GetClientTeam(client) == CS_TEAM_T || g_iJailsCooldown && GetClientTeam(client) == CS_TEAM_CT) {
							if (g_iPlayerStuff[client].POINTS >= RoundToFloor(iStoreItemsPrice[0] * (bVIPClient ? 0.8 : 1.0))) {
								g_iPlayerStuff[client].POINTS -= RoundToFloor(iStoreItemsPrice[0] * (bVIPClient ? 0.8 : 1.0));
								
								g_iPlayerStuff[client].GIFT++;
								CPrintToChat(client, "%s Vous venez d'acheter {green}un gift supplémentaire{default}.", PREFIX);
							}
							else
								CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
						}
						else {
							if (GetClientTeam(client) == CS_TEAM_T)			CPrintToChat(client, "%s Vous n'êtes plus dans votre cellule fermée.", PREFIX);
							else if (GetClientTeam(client) == CS_TEAM_CT)	CPrintToChat(client, "%s Les cellules doivent être fermées.", PREFIX);
						}
					}
					else if (StrEqual(info, iStoreItemsItem[1])) {
						if (g_iJailsCooldown) {
							if (g_iPlayerStuff[client].TAZER < 5) {
								if (g_iPlayerStuff[client].POINTS >= RoundToFloor(iStoreItemsPrice[1] * (bVIPClient ? 0.8 : 1.0))) {
									g_iPlayerStuff[client].POINTS -= RoundToFloor(iStoreItemsPrice[1] * (bVIPClient ? 0.8 : 1.0));
									
									g_iPlayerStuff[client].TAZER++;
									if (g_iPlayerStuff[client].TAZER == 1) GivePlayerItemAny(client, "weapon_taser");
									CPrintToChat(client, "%s Vous venez d'acheter {green}un taser supplémentaire{default}.", PREFIX);
								}
								else
									CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
							}
							else
								CPrintToChat(client, "%s Vous avez déjà assez de tasers.", PREFIX);
						}
						else
							CPrintToChat(client, "%s Les cellules doivent être fermées.", PREFIX);
					}
					else if (StrEqual(info, iStoreItemsItem[2])) {
						if (!bajail[client].g_bReceptDone) {
							if (!bajail[client].g_bGotUSP) {
								if (g_iPlayerStuff[client].POINTS >= RoundToFloor(iStoreItemsPrice[2] * (bVIPClient ? 0.8 : 1.0))) {
									g_iPlayerStuff[client].POINTS -= RoundToFloor(iStoreItemsPrice[2] * (bVIPClient ? 0.8 : 1.0));
									
									bajail[client].g_bGotUSP = true;
									
									GivePlayerItemAny(client, "weapon_usp_silencer");
									
									CPrintToChat(client, "%s Vous venez d'acheter {green}un USP{default}.", PREFIX);
								}
								else
									CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
							}
							else
								CPrintToChat(client, "%s Vous avez déjà acheté ou gagné un USP.", PREFIX);
						}
						else
							CPrintToChat(client, "%s Vous n'êtes plus dans votre cellule fermée.", PREFIX);
					}
					else if (StrEqual(info, iStoreItemsItem[3])) {
						if (!bajail[client].g_bReceptDone) {
							if (!bajail[client].g_bGotDeagle) {
								if (g_iPlayerStuff[client].POINTS >= RoundToFloor(iStoreItemsPrice[3] * (bVIPClient ? 0.8 : 1.0))) {
									g_iPlayerStuff[client].POINTS -= RoundToFloor(iStoreItemsPrice[3] * (bVIPClient ? 0.8 : 1.0));
									
									bajail[client].g_bGotDeagle = true;
									
									GivePlayerItemAny(client, "weapon_deagle");
									
									CPrintToChat(client, "%s Vous venez d'acheter {green}un Deagle{default}.", PREFIX);
								}
								else {
									CPrintToChat(client, "%s Vous n'avez pas assez de points.", PREFIX);
								}
							}
							else {
								CPrintToChat(client, "%s Vous avez déjà acheté un Deagle.", PREFIX);
							}
						}
						else {
							CPrintToChat(client, "%s Vous n'êtes plus dans votre cellule fermée.", PREFIX);
						}
					}
					else if (StrEqual(info, iStoreItemsItem[4])) {
						if (ReadPosition("jail_vip")) {
							if (!bajail[client].g_bReceptDone) {
								if (!bajail[client].g_bJailVIP) {
									if (g_iPlayerStuff[client].POINTS >= RoundToFloor(iStoreItemsPrice[4] * (bVIPClient ? 0.8 : 1.0))) {
										g_iPlayerStuff[client].POINTS -= RoundToFloor(iStoreItemsPrice[4] * (bVIPClient ? 0.8 : 1.0));	

										bajail[client].g_bJailVIP = true;
										
										TeleportEntity(client, g_fReadPos[0], NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
										
										CPrintToChat(client, "%s Vous avez été téléporté dans {green}la cellule VIP{default}.", PREFIX);
									}
									else
										CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
								}
								else
									CPrintToChat(client, "%s Vous vous êtes déjà téléporté.", PREFIX);
							}
							else
								CPrintToChat(client, "%s Vous n'êtes plus dans votre cellule fermée.", PREFIX);
						}
						else
							CPrintToChat(client, "%s Il n'y a pas de cellule VIP sur cette map.", PREFIX);
					}
					else if (StrEqual(info, iStoreItemsItem[5])) {
						if (!bajail[client].g_bReceptDone && GetClientTeam(client) == CS_TEAM_T || g_iJailsCooldown && GetClientTeam(client) == CS_TEAM_CT) {
							if (g_iPlayerStuff[client].POINTS >= RoundToFloor(iStoreItemsPrice[5] * (bVIPClient ? 0.8 : 1.0))) {
								if (Health < 200) {
									g_iPlayerStuff[client].POINTS -= RoundToFloor(iStoreItemsPrice[5] * (bVIPClient ? 0.8 : 1.0));	
									
									SetEntityHealth(client, Health + 15);
									CPrintToChat(client, "%s Vous venez d'acheter {green}un bonus de vie{default}.", PREFIX);
									
									if (Health + 15 > 200)
										SetEntityHealth(client, 200);
								}
								else
									CPrintToChat(client, "%s Vous avez trop de vie.", PREFIX);
							}
							else
								CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
						}
						else {
							if (GetClientTeam(client) == CS_TEAM_T)			CPrintToChat(client, "%s Vous n'êtes plus dans votre cellule fermée.", PREFIX);
							else if (GetClientTeam(client) == CS_TEAM_CT)	CPrintToChat(client, "%s Les cellules doivent être fermées.", PREFIX);
						}
					}
					else if (StrEqual(info, iStoreItemsItem[6])) {
						if (!bajail[client].g_bReceptDone && GetClientTeam(client) == CS_TEAM_T || g_iJailsCooldown && GetClientTeam(client) == CS_TEAM_CT) {
							if (g_iPlayerStuff[client].POINTS >= RoundToFloor(iStoreItemsPrice[6] * (bVIPClient ? 0.8 : 1.0))) {
								if(g_iBonusSpeed[client] != 1) {
									g_iPlayerStuff[client].POINTS -= RoundToFloor(iStoreItemsPrice[6] * (bVIPClient ? 0.8 : 1.0));
									
									g_iBonusSpeed[client] = 1;
									
									SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.3);
									CPrintToChat(client, "%s Vous venez d'acheter {green}un bonus de vitesse{default}.", PREFIX);
								}
								else
									CPrintToChat(client, "%s Vous êtes déjà rapide.", PREFIX);
							}
							else
								CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
						}
						else {
							if (GetClientTeam(client) == CS_TEAM_T)			CPrintToChat(client, "%s Vous n'êtes plus dans votre cellule fermée.", PREFIX);
							else if (GetClientTeam(client) == CS_TEAM_CT)	CPrintToChat(client, "%s Les cellules doivent être fermées.", PREFIX);
						}
					}
				}
				else
					CPrintToChat(client, "%s Le nombre de Prisonniers en vie n'est pas suffisant.", PREFIX);
			}
			else
				CPrintToChat(client, "%s La Base de Données est hors-ligne.", PREFIX);
		}
		else
			CPrintToChat(client, "%s Vous devez être en vie.", PREFIX);
	}
	else if (action == MenuAction_End)
		delete menu;
}