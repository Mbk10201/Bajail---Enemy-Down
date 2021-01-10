/*
     __  ___                     
    /  |/  /__  ____  __  _______
   / /|_/ / _ \/ __ \/ / / / ___/
  / /  / /  __/ / / / /_/ (__  ) 
 /_/  /_/\___/_/ /_/\__,_/____/  

*/

public void Frame_SpawnChoice(int client) {
	if (IsValidClient(client, true) && GetClientTeam(client) >= CS_TEAM_T && GetTotalPlayer(3) > 1 && GetTotalPlayer(2) > 1) {
		if (GetClientTeam(client) == CS_TEAM_CT) {
			Menu menu = new Menu(MenuHandler_CaptainChoice);

			menu.SetTitle("Voulez-vous devenir le Chef des Gardiens ?");

			menu.AddItem("oui", "Oui");
			menu.AddItem("non", "Non");
			menu.AddItem("help", "Chef de Secours");

			menu.ExitButton = false;

			int ShowTime = g_iJailsCooldown - (g_iJailTime - 10) > 0 ? g_iJailsCooldown - (g_iJailTime - 10) : 0;

			menu.Display(client, ShowTime);
			
			g_hNadeMenu[client] = CreateTimer(float(ShowTime), ShowNadeMenu, client);
		}
		else {
			Menu menu = new Menu(MenuHandler_GameChoice);
					
			menu.SetTitle("Le Bonus/Malus !");
					
			menu.AddItem("pierre", "Pierre");
			menu.AddItem("feuille", "Feuille");
			menu.AddItem("ciseaux", "Ciseaux");
						
			menu.Display(client, g_iJailsCooldown);
		}
	}
}	

void GenerateBetPanel(int client) {
	Panel panel = new Panel(GetMenuStyleHandle(MenuStyle_Radio));

	panel.SetTitle("Voulez-vous parier ?");

	panel.DrawText("");
	panel.DrawText("Prisonnier");
	panel.DrawItem("5 points", g_iPlayerStuff[client].POINTS >= 5 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	panel.DrawItem("10 points", g_iPlayerStuff[client].POINTS >= 10 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	panel.DrawItem("50 points", g_iPlayerStuff[client].POINTS >= 50 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	panel.DrawText("");
	panel.DrawText("Gardien");
	panel.DrawItem("5 points", g_iPlayerStuff[client].POINTS >= 5 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	panel.DrawItem("10 points", g_iPlayerStuff[client].POINTS >= 10 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	panel.DrawItem("50 points", g_iPlayerStuff[client].POINTS >= 50 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	panel.Send(client, PanelHandler_Betting, 10);

	delete panel;
}

public int PanelHandler_Betting(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		if (GetTotalPlayer(3) == 1 && GetTotalPlayer(2) == 1 && g_bLastRequest && g_iDVTimer) {
			if (param2 == 1) {
				if (g_iPlayerStuff[client].POINTS >= 5) {
					g_iPlayerStuff[client].POINTS -= 5;
							
					g_iPlayerBet[client].AMOUNT = 5;
					g_iPlayerBet[client].TEAM = 2;
					CPrintToChat(client, "%s Vous avez misé {lime}5 {default}points sur le {darkred}Prisonnier{default}.", PREFIX);
				}
				else
					CPrintToChat(client, "%s Vous n'avez pas assez de points.", PREFIX);
			}
			else if (param2 == 2) {
				if (g_iPlayerStuff[client].POINTS >= 10) {
					g_iPlayerStuff[client].POINTS -= 10;
							
					g_iPlayerBet[client].AMOUNT = 10;
					g_iPlayerBet[client].TEAM = 2;
					CPrintToChat(client, "%s Vous avez misé {lime}10 {default}points sur le {darkred}Prisonnier{default}.", PREFIX);
				}
				else
					CPrintToChat(client, "%s Vous n'avez pas assez de points.", PREFIX);
			}
			else if (param2 == 3) {
				if (g_iPlayerStuff[client].POINTS >= 50) {
					g_iPlayerStuff[client].POINTS -= 50;
							
					g_iPlayerBet[client].AMOUNT = 50;
					g_iPlayerBet[client].TEAM = 2;
					CPrintToChat(client, "%s Vous avez misé {lime}50 {default}points sur le {darkred}Prisonnier{default}.", PREFIX);
				}
				else
					CPrintToChat(client, "%s Vous n'avez pas assez de points.", PREFIX);
			}
			else if (param2 == 4) {
				if (g_iPlayerStuff[client].POINTS >= 5) {
					g_iPlayerStuff[client].POINTS -= 5;
							
					g_iPlayerBet[client].AMOUNT = 5;
					g_iPlayerBet[client].TEAM = 3;
					CPrintToChat(client, "%s Vous avez misé {lime}5 {default}points sur le {lightblue}Gardien{default}.", PREFIX);
				}
				else
					CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
			}
			else if (param2 == 5) {
				if (g_iPlayerStuff[client].POINTS >= 10) {
					g_iPlayerStuff[client].POINTS -= 10;
							
					g_iPlayerBet[client].AMOUNT = 10;
					g_iPlayerBet[client].TEAM = 3;
					CPrintToChat(client, "%s Vous avez misé {lime}10 {default}points sur le {lightblue}Gardien{default}.", PREFIX);
				}
				else
					CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
			}
			else if (param2 == 6) {
				if (g_iPlayerStuff[client].POINTS >= 50) {
					g_iPlayerStuff[client].POINTS -= 50;
							
					g_iPlayerBet[client].AMOUNT = 50;
					g_iPlayerBet[client].TEAM = 3;
					CPrintToChat(client, "%s Vous avez misé {lime}50 {default}points sur le {lightblue}Gardien{default}.", PREFIX);
				}
				else
					CPrintToChat(client, "%s Vous n'avez pas assez de points. Vous pouvez en acheter dans la {green}Boutique{default} ou en {green}jouant sur le serveur.{default}", PREFIX);
			}
		}
		else
			CPrintToChat(client, "%s Vous avez parié trop tard.", PREFIX);
	}
}

public int MenuHandler_CaptainChoice(Menu menu, MenuAction action, int client, int param2) { 
	if (action == MenuAction_Select) {
		char choice[16];
		menu.GetItem(param2, STRING(choice));
		
		if (StrEqual(choice, "oui")) {
			if (g_iJailsCooldown > (g_iJailTime - 10) && GetTotalPlayer(3) > 1 && GetTotalPlayer(2) > 1) {
				if (IsPlayerAlive(client)) {
					bajail[client].g_bWantsCaptain = true;
					g_bChoixAleatoire = true;
					
					g_iChefCount++;
				}
				else
					CPrintToChat(client, "%s Vous ne pouvez pas devenir Capitaine en étant mort !", PREFIX);
			}
		}
		else if (StrEqual(choice, "help")) {
			if (g_iJailsCooldown > (g_iJailTime - 10) && GetTotalPlayer(3) > 1 && GetTotalPlayer(2) > 1) {
				if (IsPlayerAlive(client)) {
					bajail[client].g_bWantsCaptainSecours = true;
					g_bChoixAleatoireSecours = true;
					
					g_iChefSecoursCount++;
				}
				else
					CPrintToChat(client, "%s Vous ne pouvez pas devenir Capitaine en étant mort !", PREFIX);
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int MenuHandler_GameChoice(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) {
		char choice[16];
		menu.GetItem(param2, STRING(choice));
		
		if (StrEqual(choice, "pierre")) {
			if (GetTotalPlayer(2) > 1 && GetTotalPlayer(3) > 1 && GetClientTeam(client) == CS_TEAM_T) {
				if (g_iJailsCooldown) {
					if (IsPlayerAlive(client)) {
						g_iGameChoice[client] = 1;
						CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Vous avez choisi la {green}Pierre {default}!");
					}
					else
						CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Vous ne pouvez pas participer en étant mort !");
				}
				else
					CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Les cellules sont déjà ouvertes !");
			}
		}
		else if (StrEqual(choice, "feuille")) {
			if (GetTotalPlayer(2) > 1 && GetTotalPlayer(3) > 1 && GetClientTeam(client) == CS_TEAM_T) {
				if (g_iJailsCooldown) {
					if (IsPlayerAlive(client)) {
						g_iGameChoice[client] = 2;
						CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Vous avez choisi la {green}Feuille {default}!", PREFIX);
					}
					else
						CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Vous ne pouvez pas participer en étant mort !", PREFIX);
				}
				else
					CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Les cellules sont déjà ouvertes !", PREFIX);
			}
		}
		else if (StrEqual(choice, "ciseaux")) {
			if (GetTotalPlayer(2) > 1 && GetTotalPlayer(3) > 1 && GetClientTeam(client) == CS_TEAM_T) {
				if (g_iJailsCooldown) {
					if (IsPlayerAlive(client)) {
						g_iGameChoice[client] = 3;
						CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Vous avez choisi les {green}Ciseaux {default}!", PREFIX);
					}
					else
						CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Vous ne pouvez pas participer en étant mort !", PREFIX);
				}
				else
					CPrintToChat(client, "{lightred}[Bonus/Malus] {default}Les cellules sont déjà ouvertes !", PREFIX);
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}