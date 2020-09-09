#define COMMAND_LENGTH 64
#define CHATCMD_LENGTH 64

public void Commands_OnPluginStart()
{
    // Practice Tools Commands
    {
        RegAdminCmd("sm_practicetools", Command_PracticeTools, ADMFLAG_CHANGEMAP, "Launchs Practice Tools.");
        RegChatCmd(".practicetools", "sm_practicetools");
        RegChatCmd(".practice", "sm_practicetools");
        RegChatCmd(".prac", "sm_practicetools");
        
        RegAdminCmd("sm_exitpracticetools", Command_ExitPracticeTools, ADMFLAG_CHANGEMAP, "Exit Practice Tools.");
        RegChatCmd(".exitpracticetools", "sm_exitpracticetools");
        RegChatCmd(".exitpractice", "sm_exitpracticetools");
        RegChatCmd(".exit", "sm_exitpracticetools");
    }
    
    // Nader Commands
    {
        RegConsoleCmd("sm_lastgrenade", Command_LastGrenade);
        RegChatCmd(".lastgrenade", "sm_lastgrenade");
        RegChatCmd(".last", "sm_lastgrenade");
        
        RegConsoleCmd("sm_backgrenade", Command_BackGrenade);
        RegChatCmd(".backgrenade", "sm_backgrenade");
        RegChatCmd(".back", "sm_backgrenade");
        
        RegConsoleCmd("sm_forwardgrenade", Command_ForwardGrenade);
        RegChatCmd(".forwardgrenade", "sm_forwardgrenade");
        RegChatCmd(".forward", "sm_forwardgrenade");
        
        RegConsoleCmd("sm_throwgrenade", Command_ThrowGrenade);
        RegChatCmd(".throwgrenade", "sm_throwgrenade");
        RegChatCmd(".throw", "sm_throwgrenade");
        
        RegConsoleCmd("sm_rethrowgrenade", Command_ThrowGrenade);
        RegChatCmd(".rethrowgrenade", "sm_rethrowgrenade");
        RegChatCmd(".rethrow", "sm_rethrowgrenade");
        
        
        RegConsoleCmd("sm_noflash", Command_NoFlash);
        RegChatCmd(".noflash", "sm_noflash");
    }
   
    // Bonus Commands   
    {
    }
}

public Action Command_PracticeTools(int client, int args) {
    StartPracticeTools(client);
    return Plugin_Handled;
}

public Action Command_ExitPracticeTools(int client, int args) {
    ExitPracticeTools();
    return Plugin_Handled;
}

public Action Command_LastGrenade(int client, int args) {
    LastGrenadePosition(client);
    return Plugin_Handled;
}

public Action Command_BackGrenade(int client, int args) {
    BackGrenadePosition(client, args);
    return Plugin_Handled;
}

public Action Command_ForwardGrenade(int client, int args) {
    ForwardGrenadePosition(client, args);
    return Plugin_Handled;
}

public Action Command_ThrowGrenade(int client, int args) {
    ThrowLastGrenade(client, args);
    return Plugin_Handled;
}

public Action Command_NoFlash(int client, int args) {
    NoFlash(client, args);
    return Plugin_Handled;
}