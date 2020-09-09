#define MESSAGE_PREFIX "[\x05PracticeTools\x01]"

static char _colorNames[][] = {"{NORMAL}", "{DARK_RED}", "{PINK}", "{GREEN}", "{YELLOW}", "{LIGHT_GREEN}", "{LIGHT_RED}", "{GRAY}", "{ORANGE}", "{LIGHT_BLUE}", "{DARK_BLUE}", "{PURPLE}"};
static char _colorCodes[][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0B", "\x0C", "\x0E"};

ArrayList g_ChatCmds;
ArrayList g_ChatCmdServerCmds;

public void ChatUtil_OnPluginStart() {
    g_ChatCmds = new ArrayList(CHATCMD_LENGTH);
    g_ChatCmdServerCmds = new ArrayList(COMMAND_LENGTH);
}

public void RegChatCmd(const char[] ChatCmd, const char[] ServerCmd)
{
    if (g_ChatCmds.FindString(ChatCmd) == -1) {
        g_ChatCmds.PushString(ChatCmd);
        g_ChatCmdServerCmds.PushString(ServerCmd);
    }
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs) {
    if (!IsPlayer(client))
        return;
        
    char chatCommand[COMMAND_LENGTH];
    char chatArgs[255];
    int index = SplitString(sArgs, " ", chatCommand, sizeof(chatCommand));

    if (index == -1) {
        strcopy(chatCommand, sizeof(chatCommand), sArgs);
    } else if (index < strlen(sArgs)) {
        strcopy(chatArgs, sizeof(chatArgs), sArgs[index]);
    }
    
    if (chatCommand[0]) {
        char alias[CHATCMD_LENGTH];
        char cmd[COMMAND_LENGTH];
        for (int i = 0; i < GetArraySize(g_ChatCmds); i++) {
            g_ChatCmds.GetString(i, alias, sizeof(alias));
            g_ChatCmdServerCmds.GetString(i, cmd, sizeof(cmd));
    
            if (CheckChatAlias(alias, cmd, chatCommand, chatArgs, client)) {
                break;
            }
        }
    }
}

public bool CheckChatAlias(const char[] alias, const char[] command, const char[] chatCommand, const char[] chatArgs, int client) {
    if (StrEqual(chatCommand, alias, false)) {
        ReplySource replySource = GetCmdReplySource();
        SetCmdReplySource(SM_REPLY_TO_CHAT);
        
        char fakeCommand[256];
        Format(fakeCommand, sizeof(fakeCommand), "%s %s", command, chatArgs);
        FakeClientCommand(client, fakeCommand);
        
        SetCmdReplySource(replySource);
        return true;
    }
    return false;
}

public void Message(int client, const char[] format) {
    if (client != 0 && (!IsClientConnected(client) || !IsClientInGame(client)))
        return;
        
    SetGlobalTransTarget(client);
    
    char prefix[64] = MESSAGE_PREFIX;
    
    char finalMsg[1024];
    if (StrEqual(prefix, ""))
        Format(finalMsg, sizeof(finalMsg), " %s", format);
    else
        Format(finalMsg, sizeof(finalMsg), "%s %s", prefix, format);
        
    if (client == 0) {
        Colorize(finalMsg, sizeof(finalMsg), false);
        PrintToConsole(client, finalMsg);
    } else if (IsClientInGame(client)) {
        Colorize(finalMsg, sizeof(finalMsg), false);
        PrintToChat(client, finalMsg);
    }
}

public void MessageToServer(const char[] format) {
    char prefix[64] = MESSAGE_PREFIX;
    
    char finalMsg[1024];
    Format(finalMsg, sizeof(finalMsg), "%s %s", prefix, format);
    Colorize(finalMsg, sizeof(finalMsg), false);
    
    PrintToServer(finalMsg);
}

public void MessageToAll(const char[] format) {
    char prefix[64] = MESSAGE_PREFIX;
    
    for (int i = 0; i <= MaxClients; i++) {
        if (i != 0 && (!IsClientConnected(i) || !IsClientInGame(i)))
            continue;
            
        SetGlobalTransTarget(i);
        
        char finalMsg[1024];
        Format(finalMsg, sizeof(finalMsg), "%s %s", prefix, format);

        if (i != 0) {
            Colorize(finalMsg, sizeof(finalMsg), false);
            PrintToChat(i, finalMsg);
        } else {
            Colorize(finalMsg, sizeof(finalMsg), false);
            PrintToConsole(i, finalMsg);
        }
    }
}

public void Colorize(char[] msg, int size, bool stripColor) {
    for (int i = 0; i < sizeof(_colorNames); i++) {
        if (stripColor)
            ReplaceString(msg, size, _colorNames[i], "\x01");
        else
            ReplaceString(msg, size, _colorNames[i], _colorCodes[i]);
    }
}