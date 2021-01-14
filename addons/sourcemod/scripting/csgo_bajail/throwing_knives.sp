/*
   ________                       _                __ __       _                
  /_  __/ /_  _________ _      __(_)___  ____ _   / //_/____  (_)   _____  _____
   / / / __ \/ ___/ __ \ | /| / / / __ \/ __ `/  / ,<  / __ \/ / | / / _ \/ ___/
  / / / / / / /  / /_/ / |/ |/ / / / / / /_/ /  / /| |/ / / / /| |/ /  __(__  ) 
 /_/ /_/ /_/_/   \____/|__/|__/_/_/ /_/\__, /  /_/ |_/_/ /_/_/ |___/\___/____/  
                                      /____/                                    
	Special Thanks to Bacardi & meng
*/

#define KNIFEHIT_SOUND 		"weapons/knife/knife_hit3.wav"

EngineVersion game;
Handle g_hTimerDelay[MAXPLAYERS+1];
bool g_bHeadshot[MAXPLAYERS+1];
#define DMG_HEADSHOT		(1 << 30)

// SDKHooks_TakeDamage seems not activate this callback, but player knife slash does
public Action ontakedamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	int dmgtype = game == Engine_CSS ? DMG_BULLET|DMG_NEVERGIB:DMG_SLASH|DMG_NEVERGIB;

	if (0 < inflictor <= MaxClients && inflictor == attacker && damagetype == dmgtype) {
		g_bHeadshot[attacker] = false; // no headshot when slash

		TrashTimer(g_hTimerDelay[attacker]);
	}
}


public Action player_death(Event event, const char[] name, bool dontBroadcast)
{
	char weapon[20];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (StrContains(weapon, "knife", false) != -1 || StrContains(weapon, "bayonet", false) != -1) {
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if (StrEqual(weapon, "knife", false) || StrEqual(weapon, "bayonet", false)) {
			SetEventBool(event, "headshot", g_bHeadshot[attacker]);
			g_bHeadshot[attacker] = false;
		}
	}

	return Plugin_Continue;
}

public Action weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	char weapon[20];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if ( StrContains(weapon, "knife", false) == -1 && StrContains(weapon, "bayonet", false) == -1)
		return;
		
	if (!g_iKnives[client] && !g_iLastRequest[THROWING])
		return;
		
	g_hTimerDelay[client] = CreateTimer(0.0, CreateKnife, client);
}

public Action CreateKnife(Handle timer, any client)
{
	g_hTimerDelay[client] = null;

	int slot_knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	int knife = CreateEntityByName("smokegrenade_projectile");

	if (knife == -1 || !DispatchSpawn(knife))
		return;

	// owner
	int team = GetClientTeam(client);
	SetEntPropEnt(knife, Prop_Send, "m_hOwnerEntity", client);
	SetEntPropEnt(knife, Prop_Send, "m_hThrower", client);
	SetEntProp(knife, Prop_Send, "m_iTeamNum", team);

	// player knife model
	char model[PLATFORM_MAX_PATH];
	if (slot_knife != -1) {
		GetEntPropString(slot_knife, Prop_Data, "m_ModelName", model, sizeof(model));
		if (ReplaceString(model, sizeof(model), "v_knife_", "w_knife_", true) != 1)
			model[0] = '\0';
		else if (game == Engine_CSGO && ReplaceString(model, sizeof(model), ".mdl", "_dropped.mdl", true) != 1)
			model[0] = '\0';
	}

	if (!FileExists(model, true))
		Format(model, sizeof(model), "%s", game == Engine_CSS ? "models/weapons/w_knife_t.mdl": team == CS_TEAM_T ? "models/weapons/w_knife_default_t_dropped.mdl":"models/weapons/w_knife_default_ct_dropped.mdl");
	
	// model and size
	SetEntProp(knife, Prop_Send, "m_nModelIndex", PrecacheModel(model));
	SetEntPropFloat(knife, Prop_Send, "m_flModelScale", 1.0);

	// knive elasticity
	SetEntPropFloat(knife, Prop_Send, "m_flElasticity", 0.2);
	// gravity
	SetEntPropFloat(knife, Prop_Data, "m_flGravity", 1.0);

	// Player origin and angle
	float origin[3], angle[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angle);

	// simple noblock fix. prevent throw if it will spawn inside another client
	if (IsClientIndex(!GetTraceHullEntityIndex(origin, client)))
		return;

	// knive int spawn position and angle is same as player's
	float pos[3];
	GetAngleVectors(angle, pos, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(pos, 50.0);
	AddVectors(pos, origin, pos);

	// knive flying direction and speed/power
	float player_velocity[3], velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", player_velocity);
	GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(velocity, 2250.0);
	AddVectors(velocity, player_velocity, velocity);

	// spin knive
	float spin[] = {4000.0, 0.0, 0.0};
	SetEntPropVector(knife, Prop_Data, "m_vecAngVelocity", spin);

	// Stop grenade detonate and Kill knive after 1 - 30 sec
	SetEntProp(knife, Prop_Data, "m_nNextThinkTick", -1);
	char buffer[25];
	Format(buffer, sizeof(buffer), "!self,Kill,,%0.1f,-1", 1.5);
	DispatchKeyValue(knife, "OnUser1", buffer);
	AcceptEntityInput(knife, "FireUser1");

	// Throw knive!
	TeleportEntity(knife, pos, angle, velocity);
	SDKHookEx(knife, SDKHook_Touch, KnifeHit);

	if (g_iKnives[client]) g_iKnives[client]--;
	if (!g_iLastRequest[THROWING]) 
	{
		char format[128];
		Format(STRING(format), "Couteau%s de Lancer: %i", (g_iKnives[client] > 1 ? "x" : ""), g_iKnives[client]);
		PrintHudMessage(client, format);	
	}
}

int GetTraceHullEntityIndex(float pos[3], int xindex)
{
	TR_TraceHullFilter(pos, pos, view_as<float>({-24.0, -24.0, -24.0}), view_as<float>({24.0, 24.0, 24.0}), MASK_SHOT, THFilter, xindex);
	return TR_GetEntityIndex();
}

public bool THFilter(int entity, int contentsMask, any data)
{
	return IsClientIndex(entity) && entity != data;
}

bool IsClientIndex(int index)
{
	return index && index <= MaxClients;
}

public Action KnifeHit(int knife, int victim)
{
	if (0 < victim <= MaxClients) {
		SetVariantString("csblood");
		AcceptEntityInput(knife, "DispatchEffect");
		AcceptEntityInput(knife, "Kill");

		int attacker = GetEntPropEnt(knife, Prop_Send, "m_hThrower");
		int inflictor = GetPlayerWeaponSlot(attacker, CS_SLOT_KNIFE);

		if (inflictor == -1)
			inflictor = attacker;

		float victimeye[3];
		GetClientEyePosition(victim, victimeye);

		float damagePosition[3];
		float damageForce[3];

		GetEntPropVector(knife, Prop_Data, "m_vecOrigin", damagePosition);
		GetEntPropVector(knife, Prop_Data, "m_vecVelocity", damageForce);

		if (GetVectorLength(damageForce) == 0.0) // knife movement stop
			return;

		// Headshot - shitty way check it, clienteyeposition almost player back...
		float distance = GetVectorDistance(damagePosition, victimeye);
		g_bHeadshot[attacker] = distance <= 20.0;

		// damage values and type
		float damage[2];
		damage[0] = 34.0;
		damage[1] = 68.0;
		int dmgtype = game == Engine_CSS ? DMG_BULLET|DMG_NEVERGIB:DMG_SLASH|DMG_NEVERGIB;
		//int dmgtype = game == DMG_BULLET|DMG_NEVERGIB;

		if (g_bHeadshot[attacker])
			dmgtype |= DMG_HEADSHOT;

		// create damage
		SDKHooks_TakeDamage(victim, inflictor, attacker,
		g_bHeadshot[attacker] ? damage[1]:damage[0],
		dmgtype, knife, damageForce, damagePosition);

		EmitAmbientSound(KNIFEHIT_SOUND, damagePosition, victim, SNDLEVEL_NORMAL, _, 0.8);

		// blood effect
		int color[] = {255, 0, 0, 255};
		float dir[3];

		TE_SetupBloodSprite(damagePosition, dir, color, 1, PrecacheDecal("sprites/blood.vmt"), PrecacheDecal("sprites/blood.vmt"));
		TE_SendToAll(0.0);

		// ragdoll effect
		int ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");
		if (ragdoll != -1) {
			ScaleVector(damageForce, 50.0);
			damageForce[2] = FloatAbs(damageForce[2]); // push up!
			SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", damageForce);
			SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", damageForce);
		}
	}
}