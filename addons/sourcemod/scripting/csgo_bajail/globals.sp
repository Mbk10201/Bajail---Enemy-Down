/*
    ________      __          __    
   / ____/ /___  / /_  ____ _/ /____
  / / __/ / __ \/ __ \/ __ `/ / ___/
 / /_/ / / /_/ / /_/ / /_/ / (__  ) 
 \____/_/\____/_.___/\__,_/_/____/  

*/

#define STRING(%1) %1, sizeof(%1)
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++)

#define PREFIX					"{lightred}[Enemy-Down]{default}"

#define PLUGIN_NAME "CS-GO : Ba-Jail"
#define PLUGIN_DESC	"CS-GO : Ba-Jail"
#define PLUGIN_AUTHOR	"MBK"
#define PLUGIN_VERSION	"2.0"
#define PLUGIN_URL	"www.enemy-down.eu"

#define WEB_URL     "www.enemy-down.eu"
#define DISCORD_URL "https://discord.gg/RSrQutCtt8"

#define SOUND_TIMEWARNING 		"/enemy-down/jail/time_warning.mp3"
#define SOUND_JIHAD 			"/enemy-down/jail/jihad.mp3"
#define SOUND_VIPDAY 			"/enemy-down/jail/vip_day.mp3"
#define SOUND_OPENCT 			"/enemy-down/jail/openct.mp3"
#define SOUND_OPENT 			"/enemy-down/jail/opent.mp3"
#define SOUND_QL	 			"/enemy-down/jail/ql.mp3"
#define SOUND_QR	 			"/enemy-down/jail/qr.mp3"
#define SOUND_DCT 				"/enemy-down/jail/dctbis.mp3"
#define SOUND_TAZER				"/enemy-down/jail/taser.mp3"
#define SOUND_DV 				"/enemy-down/jail/dvdispo.mp3"
#define SOUND_DVSTART 			"/enemy-down/jail/dvstart.wav"
#define SOUND_REFUSE 			"/enemy-down/jail/dvno.mp3"
#define SOUND_ACCEPTE 			"/enemy-down/jail/dvok.mp3"
#define SOUND_NOSCOPE 			"/enemy-down/jail/noscope.mp3"
#define SOUND_COWBOY 			"/enemy-down/jail/cowboy.mp3"
#define SOUND_PANPAN 			"/enemy-down/jail/pan.mp3"
#define SOUND_TP				"/enemy-down/jail/flashtp.mp3"
#define SOUND_EXPLODE			"/enemy-down/jail/explode_8.mp3"
#define SOUND_THUNDER			"/enemy-down/jail/explode_9.wav"
#define SOUND_FREEZE			"physics/glass/glass_impact_bullet4.wav" 
#define SOUND_CTBAN				"buttons/button10.wav"
#define SOUND_PLAINTE			"buttons/blip1.wav"
#define SOUND_LUMIERE			"items/flashlight1.wav"

#define MODEL_GARDIEN1 			"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl"
#define MODEL_GARDIEN2 			"models/player/custom_player/kuristaja/jailbreak/guard2/guard2.mdl"
#define MODEL_CHEF1 			"models/player/custom_player/kuristaja/jailbreak/guard3/guard3.mdl"
#define MODEL_CHEF2 			"models/player/custom_player/kuristaja/jailbreak/guard5/guard5.mdl"
#define MODEL_PRISONNIER1 		"models/player/custom_player/kuristaja/jailbreak/prisoner2/prisoner2.mdl"
#define MODEL_PRISONNIER2 		"models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.mdl"
#define MODEL_PRISONNIER3 		"models/player/custom_player/kuristaja/jailbreak/prisoner4/prisoner4.mdl"
#define MODEL_PRISONNIER4 		"models/player/custom_player/kuristaja/jailbreak/prisoner6/prisoner6.mdl"
#define MODEL_PRISONNIER5 		"models/player/custom_player/kuristaja/jailbreak/prisoner7/prisoner7.mdl"
#define MODEL_VIP		 		"models/player/custom_player/kuristaja/putin/putin.mdl"
#define ARMS_GARDIEN1 			"models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl"
#define ARMS_GARDIEN2 			"models/player/custom_player/kuristaja/jailbreak/guard2/guard2_arms.mdl"
#define ARMS_CHEF1	 			"models/player/custom_player/kuristaja/jailbreak/guard3/guard3_arms.mdl"
#define ARMS_CHEF2	 			"models/player/custom_player/kuristaja/jailbreak/guard5/guard5_arms.mdl"
#define ARMS_PRISONNIER1 		"models/player/custom_player/kuristaja/jailbreak/prisoner2/prisoner2_arms.mdl"
#define ARMS_PRISONNIER2 		"models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3_arms.mdl"
#define ARMS_PRISONNIER3 		"models/player/custom_player/kuristaja/jailbreak/prisoner4/prisoner4_arms.mdl"
#define ARMS_PRISONNIER4 		"models/player/custom_player/kuristaja/jailbreak/prisoner6/prisoner6_arms.mdl"
#define ARMS_PRISONNIER5 		"models/player/custom_player/kuristaja/jailbreak/prisoner7/prisoner7_arms.mdl"
#define ARMS_VIP				"models/player/custom_player/kuristaja/putin/putin_arms.mdl"

#define SMOKE_PARTICLE 			"particle/fire.vmt"

#define MAXENTITIES 			2048 

#define HIDE_RADAR_CSGO 1<<12

#define COLOR_TAZER 			{0, 0, 128, 255}
#define COLOR_GRENADE_T 		{255, 75, 75, 255}
#define COLOR_GRENADE_CT 		{75, 75, 255, 255}

#define BONUS_SPEED						0.2 
#define BONUS_GRAVITY					0.75 
#define BONUS_INVIBILITY_TIME			4.0 
#define BONUS_HP_ADD					15 
#define BONUS_TELEPORT					2 
#define BONUS_REGENE_VALUE				3 
#define BONUS_REGENE_TIMER				1.0 
#define BONUS_REGEN_MAX					100 
#define BONUS_INFIRMIER_RADIUS		 	200.0 
#define BONUS_INFIRMIER_TIMER			1.0 
#define BONUS_INFIRMIER_AMOUNT			5 
#define BONUS_INFIRMIER_MAXIMUM			110 
#define BONUS_MUNITIONS_GLACE			10 
#define BONUS_MUNITIONS_INCENDIAIRE	 	10
#define BONUS_MUNITIONS_EXPLOSIVES		5
#define BONUS_MUNITIONS_AVEUGLANTES		5

#define MUNITION_GLACE_SLOW_TIME		1.5 
#define MUNITION_GLACE_SLOW_VALUE		0.5
#define MUNITION_EXPLOSIVE_TIME			3.0 
#define MUNITION_AVEUGLANTE_TIME		1.0 

#define INDEX_T 0
#define INDEX_CT 1
#define INDEX_VIP 2

#define LIMIT_POINT_VIPPLUS 50000
#define LIMIT_POINT_VIP 50000
#define LIMIT_POINT 50000

#define ZONE_NEUTRE "#848484"
#define ZONE_CT "#0000FF"
#define ZONE_T "#FF0000"

#define Middle_Stadium view_as<float>({-2764.00, -1024.00, 80.00})
#define GOAL_POST1_MIN view_as<float>({-2865.986816, -228.250336, 60.00})
#define GOAL_POST1_MAX view_as<float>({-2660.006348, -173.291168, 120.00})
#define GOAL_POST2_MIN view_as<float>({-2867.968750, -1874.708740, 60.00})
#define GOAL_POST2_MAX view_as<float>({-2662.000244, -1819.318726, 120.00})

enum struct DVLIST { 
	int ISOLOIR;
	int BROCHETTE;
	int ROULETTE;
	int COUTEAU;
	int LANCER;
	int UNSCOPE;
	int SCOPE;
	int BASKET;
	int COWBOY;
	int GRENADE;
	int AIM;
	int VIP;
	int POMPE;
	int CHAT;
	int PATATE;
	int BALLE;
	int SULFATEUSE;
}

DVLIST g_iLastRequest;

enum struct COWBOYVAR { 
	bool COWBOY;
	int USE;
	int CROUCH;
	int MRB;
	bool LOCK;
	bool WIN;
} 

COWBOYVAR g_iCowboy[MAXPLAYERS+1];

enum struct STUFF { 
	int REND;
	int TAZER;
	int RW;
	int GIFT;
	int POINTS;
} 

STUFF g_iPlayerStuff[MAXPLAYERS+1];

enum struct BETTING { 
	int TEAM;
	int AMOUNT;
} 

BETTING g_iPlayerBet[MAXPLAYERS+1];

enum struct SAVEPOS { 
	int STATUS;
	bool LOCK;
} 

SAVEPOS g_iSavePos[MAXPLAYERS+1];

// GRENADES BONUS //

enum struct BONUS_LIST { 
	bool Speed;
	bool Gravity;
	bool Invisibility;
	bool Infirmier;
	bool Regene;
	int Munition_Glacees;
	int Munition_Incendiaires;
	int Munition_Explosives;
	int Munition_Aveuglantes;
} 

BONUS_LIST g_PlayerBonus[MAXPLAYERS+1];

int g_indexDV[3];
int g_iMin;
int g_iSec;
int g_iPhraseCpt;
int g_iJailTime;
int g_iJailsCooldown;
int g_iGameAnswer;
int g_iChefCount;
int g_iChefSecoursCount;
int g_iDVTimer;
int g_iCowboyTimer;
int g_iTimelimit;
int g_iPage;
int g_iEvilBeamCD;
int g_iBeamSprite;
int g_iBeamSprite2;
int g_iBeamSprite3;
int g_iHaloSprite;
int g_iLightingSprite;
int g_iSmokeSprite;
int ballRef;
int g_iGameChoice[MAXPLAYERS+1] = 				{ 0, ... };
int g_iRendLock[MAXPLAYERS+1] = 				{ 0, ... };
int g_iRendCounter[MAXPLAYERS+1] = 				{ 0, ... };
int g_iKillsCount[MAXPLAYERS+1] =				{ 0, ... };
int g_iKilledBy[MAXPLAYERS+1] =					{ -1, ... };
int g_iPlayerTeam[MAXPLAYERS+1] = 				{ 0, ... };
int g_iPlayerSmoke[MAXPLAYERS+1] = 				{ -1, ... };
int g_iPlayerSkin[MAXPLAYERS+1] = 				{ -1, ... };
int g_iBonusSpeed[MAXPLAYERS + 1];
int g_iBonusGravity[MAXPLAYERS + 1];
int g_iPlainte[MAXPLAYERS+1] = 0;
int g_iJour[MAXPLAYERS+1];
int g_iCdrQr;
int g_iFlashAlpha = -1;
int g_iFlashDuration = -1;

bool g_bIsChat[MAXPLAYERS+1];
bool g_bPlaying;
bool g_bWaitBall;
bool g_bLastRequest;
bool g_bLRWait;
bool g_bLRDenied;
bool g_bLRPause;
bool g_bNoChef;
bool g_bDernierCT;
bool g_bQuartierLibre;
bool g_bChoixAleatoire;
bool g_bChoixAleatoireSecours;
bool g_bRoundEnded;
bool g_bCanDct;
bool g_bEvilBonus;
bool g_bEvilSpawned;

enum struct Variable_Data {
	bool g_bHasPatateChaude;
	bool g_bExploding;
	bool g_bTazed;
	bool g_bRending;
	bool g_bReceptDone;
	bool g_bWantsCaptain;
	bool g_bWantsCaptainSecours;
	bool g_bLastRequestPlayer;
	bool g_bNeedClass;
	bool g_bGardienChef;
	bool g_bPlayerDied;
	bool g_bFreezeCooldown;
	bool g_bJailVIP;
	bool g_bGotUSP;
	bool g_bGotDeagle;
	bool g_bLoaded;
	bool g_bArmoryLeft;
	bool g_bPlayerGiftLock;
	bool g_bDropLock;
	bool g_bFlashBonus;
	bool g_bRendLock;
	bool g_bDisconnecting;
	bool g_bHUDStatus;
	bool g_bClickLocker;
	bool g_bBadGrenade;
	bool g_bClientIsAveugled;
	bool g_bClientIsFrozen;
	bool g_bClientIsParalyzed;
	bool g_bIsKamikaze;
	bool g_NoDv;
	bool g_bisMembre;
	bool g_bIsFan;
}

Variable_Data bajail[MAXPLAYERS + 1];

bool g_bArmuIsCt = true;
bool g_bQr;

char g_sBlockCMD[][] = { 
	"explode"/*, "kill"*/, "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback",
	"sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition",
	"reportingin", "getout", "negative", "enemydown" };
char g_sMapConfigPath[PLATFORM_MAX_PATH];
char g_sMapTimePath[PLATFORM_MAX_PATH];
char g_sCanUseUnlock[MAXPLAYERS+1][32];
char g_sDvRunning[64];
char g_sMap[128];
char g_sMapZonesClient[MAXPLAYERS+1][256];
char g_sPhrases[256][192];

float g_fDeathPosition[MAXPLAYERS+1][3];
float g_fSavePos[MAXPLAYERS+1][3][3];
float g_fReadPos[3][3];
float g_fTazerCount[MAXPLAYERS+1] = 			{ 0.0, ... };
float g_fGravity[MAXPLAYERS+1] = 				{ 0.0, ... };
float g_fOldSpeed[MAXPLAYERS+1] = 				{ 1.0, ... }; 
float g_fCentreStade[3] =  {-2764.00, -1024.00, 80.00};
float g_fTempsChat;

Handle g_hGlobalTimer;
Handle g_hCheckChef;
Handle g_hArmurerieCt;
Handle g_hDatabase;

Handle g_hDVTimerPatate;
Handle g_hNadeMenu[MAXPLAYERS+1] = 				{ null, ... };
Handle g_hTazerTimer[MAXPLAYERS+1] = 			{ null, ... };
Handle g_hFreeTimer[MAXPLAYERS+1] = 			{ null, ... };
Handle g_hDVInitialize[MAXPLAYERS+1] = 			{ null, ... };
Handle g_hTimerHUD[MAXPLAYERS+1] = 				{ null, ... };
Handle g_hTimerRendLock[MAXPLAYERS+1] =			{ null, ... };
Handle g_hTimerFreekill[MAXPLAYERS+1] =			{ null, ... };
Handle g_hTimerDvChat[MAXPLAYERS+1] =			{ null, ... };
Handle g_hTimerInvisibilityBcn[MAXPLAYERS+1] = 	{ null, ... }; 
Handle g_hTimerInvisibility[MAXPLAYERS+1] = 	{ null, ... }; 
Handle g_hTimerRegen[MAXPLAYERS+1] = 			{ null, ... }; 
Handle g_hTimerInfirmier[MAXPLAYERS+1] = 		{ null, ... };