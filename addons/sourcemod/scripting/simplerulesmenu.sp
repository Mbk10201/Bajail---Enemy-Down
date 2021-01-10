#include <sourcemod>
#include <cstrike>

new Handle:g_RulesMenu = INVALID_HANDLE

new Handle:sm_rulesmenu_join = INVALID_HANDLE;
new Handle:sm_rulesmenu_announce_player = INVALID_HANDLE;
new Handle:sm_rulesmenu_announce_admin = INVALID_HANDLE;

#define VERSION "1.1"

public Plugin:myinfo =
{
	name = "Simple Rules Menu",
	author = "The.Hardstyle.Bro^_^",
	description = "Showing the rules to player.",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};


 
public OnPluginStart()
{
	// Exec CFG
	AutoExecConfig(true, "simplerulesmenu");
	
	// Version cvar
	CreateConVar("sm_rulesmenu_version", VERSION, "Defines the version of the Rules Menu installed on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Cvars
	sm_rulesmenu_join = CreateConVar("sm_rulesmenu_join", "1", "Enables/disables if a player joins the server to show the rules.");
	sm_rulesmenu_announce_player = CreateConVar("sm_rulesmenu_announce_player", "1", "Announce if a player is checking the rules with a message in chat.");
	sm_rulesmenu_announce_admin = CreateConVar("sm_rulesmenu_announce_admin", "1", "Announce if an admin is using the showrules command with a message in chat.");
	
	// Console command
	RegConsoleCmd("sm_rules", Command_Rules);
	RegAdminCmd("sm_showrules", Command_ShowRules, ADMFLAG_KICK, "sm_showrules <player> to show the rules");
	
	// Translations init
	LoadTranslations("common.phrases");
	LoadTranslations("simplerules.phrases");
}
 
public OnMapStart()
{
	g_RulesMenu = BuildRulesMenu();
}
 
public OnMapEnd()
{
	if (g_RulesMenu != INVALID_HANDLE)
	{
		CloseHandle(g_RulesMenu);
		g_RulesMenu = INVALID_HANDLE;
	}
}
 
Handle:BuildRulesMenu()
{
	/* Open the file */
	new Handle:file = OpenFile("addons/sourcemod/configs/rules.ini", "rt");
	if (file == INVALID_HANDLE)
	{
		return INVALID_HANDLE;
	}
 
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Rules);
	new String:rule[255];
	while (!IsEndOfFile(file) && ReadFileLine(file, rule, sizeof(rule)))
	{
		/* Add it to the menu */
		AddMenuItem(menu, rule, rule);
	}
	/* Make sure we close the file! */
	CloseHandle(file);
 
	/* Finally, set the title */
	SetMenuTitle(menu, "Règlement :");
 
	return menu;
}

 public OnClientAuthorized(client,const String:auth[])
{
	if (IsFakeClient(client)) 
	{
	return;
	}
	
	if(GetConVarBool(sm_rulesmenu_join))
	{
		DisplayMenu(g_RulesMenu, client, MENU_TIME_FOREVER);
	}
}

public Menu_Rules(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{

	}
}
 

public Action:Command_Rules(client, args)
{
	if (g_RulesMenu == INVALID_HANDLE)
	{
		PrintToConsole(client, "The rules.ini in the sourcemod config directory file was not found!");
		return Plugin_Handled;
	}	
 
	DisplayMenu(g_RulesMenu, client, MENU_TIME_FOREVER);
	if(GetConVarBool(sm_rulesmenu_announce_player))
	{
		PrintToChatAll("\x04[Rules] \x03%t", "lit le règlement", client);
	}
	
 	PrintToChat(client, "\x04[Rules] \x03%t", "a bien lu le règlement");
	
	return Plugin_Handled;
}

public Action:Command_ShowRules(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[STAFF] Pour faire lire les règles utilisez : sm_showrules <#userid|name>");
		return Plugin_Handled;
	}

	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	new len = BreakString(Arguments, arg, sizeof(arg));
	
	if (len == -1)
	{
		/* Safely null terminate */
		len = 0;
		Arguments[0] = '\0';
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
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
		
		new rules_self = 0;
		
		for (new i = 0; i < target_count; i++)
		{
			/* Swap everyone else first */
			if (target_list[i] == client)
			{
				rules_self = client;
			}
			else
			{
				DisplayMenu(g_RulesMenu, target_list[i], MENU_TIME_FOREVER);
				if(GetConVarBool(sm_rulesmenu_announce_admin))
				{
					PrintToChatAll("\x04[Rules] \x03%t", "lit le règlement", client, target_list[i]);
				}
 				PrintToChat(target_list[i], "\x04[Rules] \x03%t", "a bien lu le règlement");
				LogAction(client, -1, "\"%L\" used sm_showrules to player: \"%L\" ", client, target_list[i]);
			}
		}
		
		if (rules_self)
		{
			DisplayMenu(g_RulesMenu, client, MENU_TIME_FOREVER);
			if(GetConVarBool(sm_rulesmenu_announce_admin))
			{
				PrintToChatAll("\x04[Rules] \x03%t", "lit le règlement", client);
			}
 			PrintToChat(client, "\x04[Rules] \x03%t", "a bien lu le règlement");
			LogAction(client, -1, "\"%L\" used sm_showrules on his self.", client);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}

	return Plugin_Handled;
}

