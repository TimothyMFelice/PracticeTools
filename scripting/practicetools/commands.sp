#define COMMAND_LENGTH 64
#define CHATCMD_LENGTH 64

public void Commands_OnPluginStart()
{
    // Practice Tools Commands
    {
        RegAdminCmd("sm_practicetools", Command_PracticeTools, ADMFLAG_CHANGEMAP, "Launchs Pratice Tools.");
        RegChatCmd(".practicetools", "sm_practicetools");
        RegChatCmd(".practice", "sm_practicetools");
        RegChatCmd(".prac", "sm_practicetools");
    }
}

public Action Command_PracticeTools(int client, int args) {
    StartPracticeTools(client);
    return Plugin_Handled;
}