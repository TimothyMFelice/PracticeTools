

ArrayList g_BinaryOptionEnabledCvars;
ArrayList g_BinaryOptionEnabledValues;
ArrayList g_BinaryOptionDisabledCvars;
ArrayList g_BinaryOptionDisabledValues;

int g_BeamSprite = -1;
ConVar g_PatchGrenadeTrajectoryCvar;
ConVar g_GrenadeTrajectoryClientColorCvar;
ConVar g_RandomGrenadeTrajectoryCvar;
ConVar g_GrenadeTrajectoryCvar;
ConVar g_GrenadeThicknessCvar;
ConVar g_GrenadeTimeCvar;
ConVar g_GrenadeSpecTimeCvar;

ArrayList g_ClientGrenadeThrowTimes[MAXPLAYERS + 1];

public void InitNaderSettings()
{
    g_BinaryOptionEnabledCvars = new ArrayList();
    g_BinaryOptionEnabledValues = new ArrayList();
    g_BinaryOptionDisabledCvars = new ArrayList();
    g_BinaryOptionDisabledValues = new ArrayList();
}


public void LaunchNaderMode() {
    g_InPracticeMode = true;
    g_InNaderMode = true;
    
    ReadNaderSettings();
    
    SetNaderSettings();
    
    MessageToAll("Nader Tool is now enabled.");
}

public void ExitNaderMode() {
    if (!g_InNaderMode) {
        return;
    }
    
    RestoreNadeSettings();
    
    g_InPracticeMode = false;
    g_InNaderMode = false;
    
    MessageToAll("Nader Tool is now disabled.");
}

public void ReadNaderSettings()
{
    ClearNestedArray(g_BinaryOptionEnabledCvars);
    ClearNestedArray(g_BinaryOptionEnabledValues);
    ClearNestedArray(g_BinaryOptionDisabledCvars);
    ClearNestedArray(g_BinaryOptionDisabledValues);
    
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "configs/practicetools.cfg");
    
    KeyValues kv = new KeyValues("nader_settings");
    if (!kv.ImportFromFile(filePath)) {
        LogError("Failed to import keyvalue from pracitcetools config file \"%s\"", filePath);
        delete kv;
        return;
    }
    
    if (kv.JumpToKey("commands")) {
        ArrayList enabledCvars = new ArrayList(CVAR_NAME_LENGTH);
        ArrayList enabledValues = new ArrayList(CVAR_VALUE_LENGTH);
        if (kv.JumpToKey("enabled")) {
            ReadCvarKv(kv, enabledCvars, enabledValues);
            kv.GoBack();
        }
        g_BinaryOptionEnabledCvars.Push(enabledCvars);
        g_BinaryOptionEnabledValues.Push(enabledValues);
        
        ArrayList disabledCvars = new ArrayList(CVAR_NAME_LENGTH);
        ArrayList disabledValues = new ArrayList(CVAR_VALUE_LENGTH);
        if (kv.JumpToKey("disabled")) {
          ReadCvarKv(kv, disabledCvars, disabledValues);
          kv.GoBack();
        }
        g_BinaryOptionDisabledCvars.Push(disabledCvars);
        g_BinaryOptionDisabledValues.Push(disabledValues);
    }
    
    delete kv;
}

public void SetNaderSettings()
{
    for (int i = 0; i < g_BinaryOptionEnabledCvars.Length; i++) {
        ArrayList cvars = g_BinaryOptionEnabledCvars.Get(i);
        ArrayList values = g_BinaryOptionEnabledValues.Get(i);
        ExecuteCvarLists(cvars, values);
        LogMessage("%s is now %s.", cvars, values);
    }
}

public void RestoreNadeSettings()
{
    for (int i = 0; i < g_BinaryOptionDisabledCvars.Length; i++) {
        ArrayList cvars = g_BinaryOptionDisabledCvars.Get(i);
        ArrayList values = g_BinaryOptionDisabledValues.Get(i);
        ExecuteCvarLists(cvars, values);
        LogMessage("%s is now %s.", cvars, values);
    }
}

public Action Command_LastGrenade(int client, int args) {
    if (!g_InPracticeMode || !g_InNaderMode) {
        return Plugin_Handled;
    }

    int index = g_GrenadeHistoryPositions[client].Length - 1;
    if (index >= 0) {
        g_GrenadeHistoryIndex[client] = index;
        TeleportToGrenadeHistoryPosition(client, index);
        
        char finalMsg[1024];
        Format(finalMsg, sizeof(finalMsg), "Teleporting back to position %d in grenade history.", index + 1);
        Message(client, finalMsg);
    }
    else
    {
        Message(client, "No grenade thrown yet.");
    }

    return Plugin_Handled;
}

public Action Command_BackGrenade(int client, int args) {
    if (!g_InPracticeMode) {
        return Plugin_Handled;
    }

    char argString[64];
    if (args >= 1 && GetCmdArg(1, argString, sizeof(argString))) {
        int index = StringToInt(argString) - 1;
        if (index >= 0 && index < g_GrenadeHistoryPositions[client].Length) {
            g_GrenadeHistoryIndex[client] = index;
            TeleportToGrenadeHistoryPosition(client, g_GrenadeHistoryIndex[client]);
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Teleporting back to position %d in grenade history.", g_GrenadeHistoryIndex[client] + 1);
            Message(client, finalMsg);
        } else {
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Your grenade history only goes from 1 to %d.", g_GrenadeHistoryPositions[client].Length);
            Message(client, finalMsg);
        }
        return Plugin_Handled;
    }

    if (g_GrenadeHistoryPositions[client].Length > 0) {
        g_GrenadeHistoryIndex[client]--;
        if (g_GrenadeHistoryIndex[client] < 0)
            g_GrenadeHistoryIndex[client] = 0;

        TeleportToGrenadeHistoryPosition(client, g_GrenadeHistoryIndex[client]);
        
        char finalMsg[1024];
        Format(finalMsg, sizeof(finalMsg), "Teleporting back to position %d in grenade history.", g_GrenadeHistoryIndex[client] + 1);
        Message(client, finalMsg);
    }

    return Plugin_Handled;
}

public Action Command_ForwardGrenade(int client, int args) {
    if (!g_InPracticeMode) {
        return Plugin_Handled;
    }
        
    char argString[64];
    if (args >= 1 && GetCmdArg(1, argString, sizeof(argString))) {
        int index = StringToInt(argString) - 1;
        if (index >= 0 && index < g_GrenadeHistoryPositions[client].Length) {
            g_GrenadeHistoryIndex[client] = index;
            TeleportToGrenadeHistoryPosition(client, g_GrenadeHistoryIndex[client]);
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Teleporting forward to position %d in grenade history.", g_GrenadeHistoryIndex[client] + 1);
            Message(client, finalMsg);
        } else {
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Your grenade history only goes from 1 to %d.", g_GrenadeHistoryPositions[client].Length);
            Message(client, finalMsg);
        }
        return Plugin_Handled;
    }


    if (g_GrenadeHistoryPositions[client].Length > 0) {
        int max = g_GrenadeHistoryPositions[client].Length;
        g_GrenadeHistoryIndex[client]++;
        if (g_GrenadeHistoryIndex[client] >= max)
            g_GrenadeHistoryIndex[client] = max - 1;
            
        TeleportToGrenadeHistoryPosition(client, g_GrenadeHistoryIndex[client]);
        
        char finalMsg[1024];
        Format(finalMsg, sizeof(finalMsg), "Teleporting forward to position %d in grenade history.", g_GrenadeHistoryIndex[client] + 1);
        Message(client, finalMsg);
    }

    return Plugin_Handled;
}

public Action Command_ThrowGrenade(int client, int args) {
    if (!g_InPracticeMode | !g_InNaderMode) {
        return Plugin_Handled;
    }
    Message(client, "Command_ThrowGrenade");
    char finalMsg[1024];
    Format(finalMsg, sizeof(finalMsg), "LastGrenadeType: %s", g_LastGrenadeType[client]);
    Message(client, finalMsg);
    
    if (IsGrenade(g_LastGrenadeType[client])) {
        Message(client, "Throwing your last nade.");
        ThrowGrenade(client, g_LastGrenadeType[client], g_LastGrenadeOrigin[client], g_LastGrenadeVelocity[client]);
    } else {
        Message(client, "No grenade thrown yet.");
    }
    
    return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] className) {
    if (!IsValidEntity(entity)) {
        return; 
    }
    
    GrenadeType type = GrenadeFromProjectileName(className, entity);
    if (type == GrenadeType_None) {
        return;
    }
 
    SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
    
    //if (type != GrenadeType_Molotov && type != GrenadeType_Incendiary && type != GrenadeType_HE) {
        //SDKHook(entity, SDKHook_StartTouch, OnTouch);
    //}
}

public int OnEntitySpawned(int entity) {
    RequestFrame(DelayedOnEntitySpawned, entity);
    RequestFrame(GetGrenadeParameters, entity);
}

public int DelayedOnEntitySpawned(int entity) {
    if (!IsValidEdict(entity)) {
        return;
    }
    
    char className[CLASS_LENGTH];
    GetEdictClassname(entity, className, sizeof(className));
    
    if (IsGrenadeProjectile(className)) {
        int client = Entity_GetOwner(entity);
        if (IsPlayer(client) && g_InPracticeMode && GrenadeFromProjectileName(className) == GrenadeType_Smoke)
        {
            int index = g_ClientGrenadeThrowTimes[client].Push(EntIndexToEntRef(entity));
            g_ClientGrenadeThrowTimes[client].Set(index, view_as<int>(GetEngineTime()), 1);
        }
        
        if (IsValidEntity(entity)) {
            if (g_GrenadeTrajectoryCvar.IntValue != 0 && g_PatchGrenadeTrajectoryCvar.IntValue != 0) {
                for (int i = 1; i <= MaxClients; i++) {
                    if (!IsClientConnected(i) || !IsClientInGame(i)) {
                        continue;
                    }
                    
                    //if (GetSetting(client, UserSetting_NoGrenadeTrajectory)) {
                    //    continue;
                    //}
                    
                    float time = (GetClientTeam(i) == CS_TEAM_SPECTATOR) ? g_GrenadeSpecTimeCvar.FloatValue : g_GrenadeTimeCvar.FloatValue;
                    
                    int colors[4];
                    if (g_RandomGrenadeTrajectoryCvar.IntValue > 0) {
                        colors[0] = GetRandomInt(0, 255);
                        colors[1] = GetRandomInt(0, 255);
                        colors[2] = GetRandomInt(0, 255);
                        colors[3] = 255;
                    } else if (g_GrenadeTrajectoryClientColorCvar.IntValue > 0 && IsPlayer(client)) {
                        colors = g_ClientColors[client];
                    } else {
                        colors = g_ClientColors[0];
                    }
                    
                    g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
                    TE_SetupBeamFollow(entity, g_BeamSprite, 0, time, g_GrenadeThicknessCvar.FloatValue * 5, g_GrenadeThicknessCvar.FloatValue * 5, 1, colors);
                    TE_SendToClient(i);
                }
            }
            
            //if (GrenadeFromProjectileName(className) == GrenadeType_Flash && g_TestingFlash[client]) {
            //    float delay = g_TestFlashTeleportDelayCvar.FloatValue;
            //    if (delay <= 0.0) {
            //        delay = 0.1;
            //    }

            //    CreateTimer(delay, Timer_TeleportClient, GetClientSerial(client));
            //}
        }
    }
}

public Action Event_SmokeDetonate(Event event, const char[] name, bool dontBroadcast) {
    if (!g_InPracticeMode) {
        return;
    }
    GrenadeDetonateTimerHelper(event, "smoke grenade");
}

public void GrenadeDetonateTimerHelper(Event event, const char[] grenadeName) {
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    int entity = event.GetInt("entityid");

    if (IsPlayer(client)) {
        for (int i = 0; i < g_ClientGrenadeThrowTimes[client].Length; i++) {
            int ref = g_ClientGrenadeThrowTimes[client].Get(i, 0);
            if (EntRefToEntIndex(ref) == entity) {
                float dt = GetEngineTime() - view_as<float>(g_ClientGrenadeThrowTimes[client].Get(i, 1));
                g_ClientGrenadeThrowTimes[client].Erase(i);
                //if (GetSetting(client, UserSetting_ShowAirtime)) {
                //Message(client, "Airtime of %s: %.1f seconds", grenadeName, dt);
                char finalMsg[1024];
                Format(finalMsg, sizeof(finalMsg), "Airtime of %s: %.1f seconds", grenadeName, dt);
                Message(client, finalMsg);
                //}
                break;
            }
        }
    }
}