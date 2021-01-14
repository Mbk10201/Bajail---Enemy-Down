#include <sourcemod>
#include <cstrike>

KeyValues rules_kv;

public Plugin myinfo =
{
	name = "[CSGO] Bajail - Rules",
	author = "MbK",
	description = "Règlement du bajail",
	version = "1.0",
	url = "https://github.com/Benito1020"
};
 
public void OnPluginStart()
{
	// Console command
	RegConsoleCmd("sm_rules", Command_Rules);
	RegAdminCmd("sm_showrules", Command_ShowRules, ADMFLAG_KICK, "sm_showrules <player> to show the rules");
	
	rules_kv = new KeyValues("Rules");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/enemy-down/reglement.cfg");
	
	if(!rules_kv.ImportFromFile(sPath))
	{
		delete rules_kv;
		PrintToServer("%s NOT FOUND", sPath);
		SetFailState("Fichier %s introuvable / existe pas !", sPath);
	}
}

public void OnPluginEnd()
{
	if(rules_kv != null)
		delete rules_kv;
}		

public Action Command_Rules(int client, int args)
{
	if(IsPlayerAlive(client))
	{
		ShowMenu(client);
	}	
}	

public Action Command_ShowRules(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[STAFF] Pour faire lire les règles utilisez : sm_showrules <#userid|name>");
		return Plugin_Handled;
	}

	char Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	char arg[65];
	int len = BreakString(Arguments, arg, sizeof(arg));
	
	if (len == -1)
	{
		/* Safely null terminate */
		len = 0;
		Arguments[0] = '\0';
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		
		int rules_self = 0;
		
		for (int i = 0; i < target_count; i++)
		{
			/* Swap everyone else first */
			if (target_list[i] == client)
			{
				rules_self = client;
			}
			else
			{
				ShowMenu(target_list[i]);
				PrintToChatAll("\x04[Règlement] %N lit le règlement.", target_list[i]);
			}
		}
		
		if (rules_self)
		{
			ShowMenu(client);
			PrintToChatAll("\x04[Règlement] %N lit le règlement.", client);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}

	return Plugin_Handled;
}

Menu ShowMenu(int client)
{
	Menu menu = new Menu(Handle_MenuRules);
	menu.SetTitle("Règlement");
	
	char maxitems[32];
	rules_kv.GetString("maxitem", maxitems, sizeof(maxitems));
	
	for(int i = 1; i <= StringToInt(maxitems); i++)
	{	
		char tmp[8];
		IntToString(i, tmp, sizeof(tmp));
		if(rules_kv.JumpToKey(tmp))
		{		
			char title[32];
			
			rules_kv.GetString("title", title, sizeof(title));
			menu.AddItem(tmp, title);	
			rules_kv.GoBack();
		}	
	}	
	
	rules_kv.Rewind();
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int Handle_MenuRules(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
				
		rules_kv.GoBack();
		if(rules_kv.JumpToKey(info))
		{
			Menu sub = new Menu(Handle_MenuRules);
			char title[32], maxsubmenu[8];
			
			rules_kv.GetString("title", title, sizeof(title));	
			rules_kv.GetString("maxsubmenu", maxsubmenu, sizeof(maxsubmenu));
			
			
			Format(title, sizeof(title), "%s", title);
			sub.SetTitle(title);	
			
			int maxsub = StringToInt(maxsubmenu);
			
			for(int i = 1; i <= maxsub; i++)
			{	
				char tmp[8];
				IntToString(i, tmp, sizeof(tmp));
				
				if(rules_kv.JumpToKey(tmp))
				{
					char subtitle[128];
					rules_kv.GetString("subtitle", subtitle, sizeof(subtitle));
					
					sub.AddItem("", subtitle, ITEMDRAW_DISABLED);
					rules_kv.GoBack();
				}	
			}	
			
			if(maxsub == 0)
				sub.AddItem("", "Aucune donnée trouvée !", ITEMDRAW_DISABLED);
			
			rules_kv.Rewind();
			
			sub.ExitButton = true;
			sub.ExitBackButton = true;
			sub.Display(client, MENU_TIME_FOREVER);
		}	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_ExitBack)
			ShowMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int Handle_SubMenuRules(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		ShowMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}