/*
	 __  ___               _____                        
	/  |/  /___ _____     /__  /  ____  ____  ___  _____
   / /|_/ / __ `/ __ \      / /  / __ \/ __ \/ _ \/ ___/
  / /  / / /_/ / /_/ /     / /__/ /_/ / / / /  __(__  ) 
 /_/  /_/\__,_/ .___/     /____/\____/_/ /_/\___/____/  
			 /_/                                                                                        
	Special Thanks to Franc1sco
*/

public void GetZoneName(int client) {
	if(IsValidClient(client)) {
		if(GetClientTeam(client) == CS_TEAM_SPECTATOR) {
			Format(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), "<font color='%s'>Spectateur</font>", ZONE_NEUTRE);
			return;
		}
		
		char l_sMapZonesClient[256][MAXPLAYERS + 1];
		
		Format(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), "<font color='%s'>Extérieur (NEUTRE)</font>", ZONE_NEUTRE);
		
		if(Zone_getMostRecentActiveZone(client, l_sMapZonesClient[client])) {
			if(Zone_IsClientInZone(client, l_sMapZonesClient[client])) {
				//Exemple nom de zone : Jail (T)|1
				char sTmp[1][256];
				ExplodeString(l_sMapZonesClient[client], "|", sTmp, sizeof(sTmp), sizeof(sTmp[]));
			
				strcopy(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), sTmp[0]);
			
				if(StrContains(g_sMapZonesClient[client], "Armurerie", false) != -1) Format(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), "<font color='%s'>%s%s</font>", (g_bArmuIsCt ? ZONE_CT : ZONE_T), g_sMapZonesClient[client], (g_bArmuIsCt ? " (CT)" : " (T)"));
				else if(StrContains(g_sMapZonesClient[client], "(T)", false) != -1) Format(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), "<font color='%s'>%s</font>", ZONE_T, g_sMapZonesClient[client]);
				else if(StrContains(g_sMapZonesClient[client], "(CT)", false) != -1) Format(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), "<font color='%s'>%s</font>", ZONE_CT, g_sMapZonesClient[client]);
				else if(StrContains(g_sMapZonesClient[client], "(NEUTRE)", false) != -1) Format(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), "<font color='%s'>%s</font>", ZONE_NEUTRE, g_sMapZonesClient[client]);
			} else Format(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), "<font color='%s'>Extérieur (NEUTRE)</font>", ZONE_NEUTRE);
		} else Format(g_sMapZonesClient[client], sizeof(g_sMapZonesClient), "<font color='%s'>Extérieur (NEUTRE)</font>", ZONE_NEUTRE);
	}
}

public bool IsInZone(int client, char[] zone) {
	if(IsValidClient(client)) {
		if(Zone_getMostRecentActiveZone(client, g_sMapZonesClient[client]))
			if(Zone_IsClientInZone(client, g_sMapZonesClient[client]))
				if (StrContains(g_sMapZonesClient[client], zone, false) != -1) return true;
	}
	return false;
}

bool posInBox(float pos[3], float min[3], float max[3]) {
    return (pos[0] >= min[0] && pos[0] <= max[0] && pos[1] >= min[1] && pos[1] <= max[1] && pos[2] >= min[2] && pos[2] <= max[2]);
}