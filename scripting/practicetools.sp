#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "S1oth"
#define PLUGIN_VERSION "0.01"

#define OPTION_NAME_LENGTH 128
#define CVAR_NAME_LENGTH 64
#define CVAR_VALUE_LENGTH 128

#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <smlib>
#include <sourcemod>

#pragma newdecls required

bool g_InPracticeMode = false;
bool g_InNaderMode = false;

#define ALIAS_LENGTH 64
#define COMMAND_LENGTH 64
ArrayList g_ChatAliases;
ArrayList g_ChatAliasesCommands;

#define CLASS_LENGTH 64

enum ClientColor {
    ClientColor_Yellow = 0,
    ClientColor_Purple = 1,
    ClientColor_Green = 2,
    ClientColor_Blue = 3,
    ClientColor_Orange = 4,
};

int g_ClientColors[MAXPLAYERS + 1][4];

int g_GrenadeHistoryIndex[MAXPLAYERS + 1];
ArrayList g_GrenadeHistoryPositions[MAXPLAYERS + 1];
ArrayList g_GrenadeHistoryAngles[MAXPLAYERS + 1];

#include "practicetools/chat_utilities.sp"
#include "practicetools/practicetools_menu.sp"
#include "practicetools/nader_utilities.sp"
#include "practicetools/nader.sp"
#include "practicetools/utilities.sp"


public Plugin myinfo = 
{
    name = "CS:GO Practice Tools",
    author = PLUGIN_AUTHOR,
    description = "Tools to help with practicing",
    version = PLUGIN_VERSION,
    url = "https://github.com/TimothyMFelice"
};

public void OnPluginStart()
{
    g_InPracticeMode = false;
    g_InNaderMode = false;
    
    InitNaderSettings();
    
    // Setup Commands
    {
        LoadTranslations("PracticeMenu.phrases");
        RegAdminCmd("sm_practicetools", Command_SetupPracticeTools, ADMFLAG_CHANGEMAP, "Display Menu For Practice Setup");
        AddChatAlias(".practicetools", "sm_practicetools");
        RegAdminCmd("sm_practice", Command_SetupPracticeTools, ADMFLAG_CHANGEMAP, "Display Menu For Practice Setup");
        AddChatAlias(".practice", "sm_practice");
        RegAdminCmd("sm_prac", Command_SetupPracticeTools, ADMFLAG_CHANGEMAP, "Display Menu For Practice Setup");
        AddChatAlias(".prac", "sm_prac");
        RegAdminCmd("sm_pt", Command_SetupPracticeTools, ADMFLAG_CHANGEMAP, "Display Menu For Practice Setup");
        AddChatAlias(".pt", "sm_pt");
    }
    
    // Exit Commands
    {
        RegAdminCmd("sm_exitpracticetools", Command_ExitPracticeTools, ADMFLAG_CHANGEMAP, "Exits Practice Tools");
        AddChatAlias(".exitpracticetools", "sm_exitpracticetools");
        RegAdminCmd("sm_exitpractice", Command_ExitPracticeTools, ADMFLAG_CHANGEMAP, "Exits Practice Tools");
        AddChatAlias(".exitpractice", "sm_exitpractice");
        RegAdminCmd("sm_exitprac", Command_ExitPracticeTools, ADMFLAG_CHANGEMAP, "Exits Practice Tools");
        AddChatAlias(".exitprac", "sm_exitprac");
        RegAdminCmd("sm_ept", Command_ExitPracticeTools, ADMFLAG_CHANGEMAP, "Exits Practice Tools");
        AddChatAlias(".ept", "sm_ept");
    }
    
    // Nader Commands
    {
        RegConsoleCmd("sm_lastgrenade", Command_LastGrenade);
        AddChatAlias(".lastgrenade", "sm_lastgrenade");
        RegConsoleCmd("sm_last", Command_LastGrenade);
        AddChatAlias(".last", "sm_last");
        RegConsoleCmd("sm_lg", Command_LastGrenade);
        AddChatAlias(".lg", "sm_lg");
        
        RegConsoleCmd("sm_backgrenade", Command_BackGrenade);
        AddChatAlias(".backgrenade", "sm_backgrenade");
        RegConsoleCmd("sm_back", Command_BackGrenade);
        AddChatAlias(".back", "sm_back");
        RegConsoleCmd("sm_bg", Command_BackGrenade);
        AddChatAlias(".bg", "sm_b");
        
        RegConsoleCmd("sm_previousgrenade", Command_BackGrenade);
        AddChatAlias(".previousgrenade", "sm_previousgrenade");
        RegConsoleCmd("sm_previous", Command_BackGrenade);
        AddChatAlias(".previous", "sm_previous");
        RegConsoleCmd("sm_pg", Command_BackGrenade);
        AddChatAlias(".pg", "sm_pg");
        
        RegConsoleCmd("sm_forwardgrenade", Command_ForwardGrenade);
        AddChatAlias(".forwardgrenade", "sm_forwardgrenade");
        RegConsoleCmd("sm_forward", Command_ForwardGrenade);
        AddChatAlias(".forward", "sm_forward");
        RegConsoleCmd("sm_f", Command_ForwardGrenade);
        AddChatAlias(".f", "sm_f");
        
        RegConsoleCmd("sm_nextgrenade", Command_ForwardGrenade);
        AddChatAlias(".nextgrenade", "sm_nextgrenade");
        RegConsoleCmd("sm_next", Command_ForwardGrenade);
        AddChatAlias(".next", "sm_next");
        RegConsoleCmd("sm_ng", Command_ForwardGrenade);
        AddChatAlias(".ng", "sm_ng");
        
        //RegConsoleCmd("sm_throwgrenade", Command_ThrowGrenade);
        //AddChatAlias(".throwgrenade", "sm_throwgrenade");
        //RegConsoleCmd("sm_throw", Command_ThrowGrenade);
        //AddChatAlias(".throw", "sm_throw");
        //RegConsoleCmd("sm_rethrow", Command_ThrowGrenade);
        //AddChatAlias(".rethrow", "sm_rethrow");
        //RegConsoleCmd("sm_rt", Command_ThrowGrenade);
        //AddChatAlias(".rt", "sm_rt");
    }
    
    // Cvars
    g_PatchGrenadeTrajectoryCvar = CreateConVar("sm_patch_grenade_trajectory_cvar", "1", "Whether the plugin patches sv_grenade_trajectory with its own grenade trails");
    g_GrenadeTrajectoryClientColorCvar = CreateConVar("sm_grenade_trajectory_use_player_color", "0", "Whether to use client colors when drawing grenade trajectories");
    g_RandomGrenadeTrajectoryCvar = CreateConVar("sm_grenade_trajectory_random_color", "0", "Whether to randomize all grenade trajectory colors");
    
    g_GrenadeTrajectoryCvar = GetCvar("sv_grenade_trajectory");
    g_GrenadeThicknessCvar = GetCvar("sv_grenade_trajectory_thickness");
    g_GrenadeTimeCvar = GetCvar("sv_grenade_trajectory_time");
    g_GrenadeSpecTimeCvar = GetCvar("sv_grenade_trajectory_time_spectator");
    
    for (int i = 0; i <= MAXPLAYERS; i++) {
        g_GrenadeHistoryPositions[i] = new ArrayList(3);
        g_GrenadeHistoryAngles[i] = new ArrayList(3);
        g_ClientGrenadeThrowTimes[i] = new ArrayList(2);
        g_ClientColors[i][0] = 0;
        g_ClientColors[i][1] = 255;
        g_ClientColors[i][2] = 0;
        g_ClientColors[i][3] = 255;
    }
    
    g_ChatAliases = new ArrayList(ALIAS_LENGTH);
    g_ChatAliasesCommands = new ArrayList(COMMAND_LENGTH);
    
    HookEvent("weapon_fire", Event_WeaponFired);
    HookEvent("smokegrenade_detonate", Event_SmokeDetonate);
}

public void OnPluginEnd()
{
    ExitPracticeToolsMode();
}

public void OnClientConnected(int client) {
    g_GrenadeHistoryIndex[client] = -1;
    ClearArray(g_GrenadeHistoryPositions[client]);
    ClearArray(g_GrenadeHistoryAngles[client]);
    ClearArray(g_ClientGrenadeThrowTimes[client]);
}

public void OnMapStart()
{
    g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public void OnMapEnd() {
    ExitPracticeToolsMode();
}

public Action Command_SetupPracticeTools(int client, int args)
{
    StartPracticeToolsMode(client);
    return Plugin_Handled;
}

public Action Command_ExitPracticeTools(int client, int args)
{
    ExitPracticeToolsMode();
    return Plugin_Handled;
}

public void StartPracticeToolsMode(int client)
{
    if (!g_InPracticeMode)
        GivePracticeMenu(client);
}

public void ExitPracticeToolsMode()
{
    if (g_InPracticeMode)
    {
        if (g_InNaderMode)
        {
            ExitNaderMode();
            return;
        }
    }
}

public void QueryClientColor(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
    int color = StringToInt(cvarValue);
    GetColor(view_as<ClientColor>(color), g_ClientColors[client]);
}

public void GetColor(ClientColor c, int array[4]) {
    int r, g, b;
    switch (c) {
        case ClientColor_Yellow: {
            r = 229;
            g = 224;
            b = 44;
        }
        case ClientColor_Purple: {
            r = 150;
            g = 45;
            b = 225;
        }
        case ClientColor_Green: {
            r = 23;
            g = 255;
            b = 102;
        }
        case ClientColor_Blue: {
            r = 112;
            g = 191;
            b = 255;
        }
        case ClientColor_Orange: {
            r = 227;
            g = 152;
            b = 33;
        }
        default: {
            r = 23;
            g = 255;
            b = 102;
        }
    }
    array[0] = r;
    array[1] = g;
    array[2] = b;
    array[3] = 255;
}

public Action Event_WeaponFired(Event event, const char[] name, bool dontBroadcast) {
    if (!g_InPracticeMode) {
        return;
    }

    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    char weapon[CLASS_LENGTH];
    event.GetString("weapon", weapon, sizeof(weapon));

    if (IsGrenadeWeapon(weapon) && IsPlayer(client) && g_InNaderMode) {
        AddGrenadeToHistory(client);
    }
}