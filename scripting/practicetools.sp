#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "S1oth"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required


bool g_InPracticeMode;
bool g_InNaderMode;

#include "practicetools/commands.sp"
#include "practicetools/chat_utilities.sp"
#include "practicetools/nader.sp"
#include "practicetools/utilities.sp"
#include "practicetools/practicetools_menu.sp"


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
    InitGlobalVariables();
    
    ChatUtil_OnPluginStart();
    Commands_OnPluginStart();
    PracticeToolsMenu_OnPluginStart();
    Nader_OnPluginStart();
}

public void InitGlobalVariables() {
    g_InPracticeMode = false;
    g_InNaderMode = false;
}

public void OnClientConnected(int client) {
    MessageToAll("Client Connected");
}