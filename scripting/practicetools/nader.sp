#define CVAR_NAME_LENGTH 64
#define CVAR_VALUE_LENGTH 128

#define CLASS_LENGTH 64

ArrayList g_NaderStartCvars;
ArrayList g_NaderStartValues;
ArrayList g_NaderEndCvars;
ArrayList g_NaderEndValues;

int g_GrenadeHistoryIndex[MAXPLAYERS + 1];
ArrayList g_GrenadeHistoryPositions[MAXPLAYERS + 1];
ArrayList g_GrenadeHistoryAngles[MAXPLAYERS + 1];

ArrayList g_ClientGrenadeThrowTimes[MAXPLAYERS + 1];

int g_BeamSprite = -1;
ConVar g_PatchGrenadeTrajectoryCvar;
ConVar g_GrenadeTrajectoryClientColorCvar;
ConVar g_RandomGrenadeTrajectoryCvar;
ConVar g_GrenadeTrajectoryCvar;
ConVar g_GrenadeThicknessCvar;
ConVar g_GrenadeTimeCvar;
ConVar g_GrenadeSpecTimeCvar;

int g_ClientColors[MAXPLAYERS + 1][4];

enum GrenadeType {
    GrenadeType_None = 0,
    GrenadeType_Smoke = 1,
    GrenadeType_Flash = 2,
    GrenadeType_HE = 3,
    GrenadeType_Molotov = 4,
    GrenadeType_Decoy = 5,
    GrenadeType_Incendiary = 6,
};

GrenadeType g_LastGrenadeType[MAXPLAYERS + 1];
float g_LastGrenadeOrigin[MAXPLAYERS + 1][3];
float g_LastGrenadeVelocity[MAXPLAYERS + 1][3];


public void Nader_OnPluginStart() {
    g_NaderStartCvars = new ArrayList();
    g_NaderStartValues = new ArrayList();
    g_NaderEndCvars = new ArrayList();
    g_NaderEndValues = new ArrayList();
    
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
}

public void Nader_OnClientConnected(int client) {
    g_GrenadeHistoryIndex[client] = -1;
    g_LastGrenadeType[client] = GrenadeType_None;
    ClearArray(g_GrenadeHistoryPositions[client]);
    ClearArray(g_GrenadeHistoryAngles[client]);
    ClearArray(g_ClientGrenadeThrowTimes[client]);
}

public void Nader_OnMapStart() {
    g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public void StartNader() {
    g_InPracticeMode = true;
    g_InNaderMode = true;
    
    ReadNaderSettings();
    SetNaderSettings();
    
    MessageToAll("Nader Tool is now enabled");
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

public void ReadNaderSettings() {
    ClearNestedArray(g_NaderStartCvars);
    ClearNestedArray(g_NaderStartValues);
    ClearNestedArray(g_NaderEndCvars);
    ClearNestedArray(g_NaderEndValues);
    
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "configs/practicetools.cfg");
    
    KeyValues kv = new KeyValues("nader_cvars");
    if (!kv.ImportFromFile(filePath)) {
        LogError("Failed to import keyvalue from pracitcetools config file \"%s\"", filePath);
        delete kv;
        return;
    }
    
    if (kv.JumpToKey("cvars")) {
        ArrayList startCvars = new ArrayList(CVAR_NAME_LENGTH);
        ArrayList startValues = new ArrayList(CVAR_VALUE_LENGTH);
        if (kv.JumpToKey("start")) {
            ReadCvarKv(kv, startCvars, startValues);
            kv.GoBack();
        }
        g_NaderStartCvars.Push(startCvars);
        g_NaderStartValues.Push(startValues);
        
        ArrayList endCvars = new ArrayList(CVAR_NAME_LENGTH);
        ArrayList endValues = new ArrayList(CVAR_VALUE_LENGTH);
        if (kv.JumpToKey("end")) {
          ReadCvarKv(kv, endCvars, endValues);
          kv.GoBack();
        }
        g_NaderEndCvars.Push(endCvars);
        g_NaderEndValues.Push(endValues);
    }
    
    delete kv;
}

public void SetNaderSettings()
{
    for (int i = 0; i < g_NaderStartCvars.Length; i++) {
        ArrayList cvars = g_NaderStartCvars.Get(i);
        ArrayList values = g_NaderStartValues.Get(i);
        ExecuteCvarLists(cvars, values);
        LogMessage("%s is now %s.", cvars, values);
    }
}

public void RestoreNadeSettings()
{
    for (int i = 0; i < g_NaderEndCvars.Length; i++) {
        ArrayList cvars = g_NaderEndCvars.Get(i);
        ArrayList values = g_NaderEndValues.Get(i);
        ExecuteCvarLists(cvars, values);
        LogMessage("%s is now %s.", cvars, values);
    }
}

public void Nader_WeaponFired(Event event, const char[] name, bool dontBroadcast) {
    if (!g_InPracticeMode || !g_InNaderMode) {
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

public void AddGrenadeToHistory(int client) {
    //int max_grenades = g_MaxHistorySizeCvar.IntValue;
    int max_grenades = 50000;
    if (max_grenades > 0 && GetArraySize(g_GrenadeHistoryPositions[client]) >= max_grenades) {
        RemoveFromArray(g_GrenadeHistoryPositions[client], 0);
        RemoveFromArray(g_GrenadeHistoryAngles[client], 0);
    }

    float position[3];
    float angles[3];
    GetClientAbsOrigin(client, position);
    GetClientEyeAngles(client, angles);
    PushArrayArray(g_GrenadeHistoryPositions[client], position, sizeof(position));
    PushArrayArray(g_GrenadeHistoryAngles[client], angles, sizeof(angles));
    g_GrenadeHistoryIndex[client] = g_GrenadeHistoryPositions[client].Length;
}

public void Nader_OnEntityCreated(int entity, const char[] className) {
    if (!g_InPracticeMode || !g_InNaderMode)
        return;
    
    GrenadeType type = GrenadeFromProjectileName(className, entity);
    if (type == GrenadeType_None) {
        return;
    }
 
    SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
}

public int OnEntitySpawned(int entity) {
    RequestFrame(DelayedOnEntitySpawned, entity);
}

public int DelayedOnEntitySpawned(int entity) {
    RequestFrame(CaptureEntity, entity);
    
    if (!IsValidEdict(entity)) {
        return;
    }
    
    char className[CLASS_LENGTH];
    GetEdictClassname(entity, className, sizeof(className));
    
    if (IsGrenadeProjectile(className)) {
        int client = Entity_GetOwner(entity);
        if (IsPlayer(client) && g_InPracticeMode && GrenadeFromProjectileName(className, 0) == GrenadeType_Smoke)
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

public Action Nader_SmokeDetonate(Event event, const char[] name, bool dontBroadcast) {
    if (!g_InPracticeMode || !g_InNaderMode) {
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

public void CaptureEntity(int entity) {
    char className[128];
    GetEntityClassname(entity, className, sizeof(className));
    GrenadeType grenadeType = GrenadeFromProjectileName(className, entity);

    int client = Entity_GetOwner(entity);
    float origin[3];
    float velocity[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
    GetEntPropVector(entity, Prop_Data, "m_vecVelocity", velocity);

    OnThrowGrenade(client, entity, grenadeType, origin, velocity);
}

public void OnThrowGrenade(int client, int entity, GrenadeType grenadeType, const float origin[3], const float velocity[3]) {
    
    char finalMsg[1024];
    Format(finalMsg, sizeof(finalMsg), "LastGrenadeType: %s", grenadeType);
    Message(client, finalMsg);
    Format(finalMsg, sizeof(finalMsg), "origin: %.1f", origin);
    Message(client, finalMsg);
    Format(finalMsg, sizeof(finalMsg), "velocity: %.1f", velocity);
    Message(client, finalMsg);
    
    g_LastGrenadeType[client] = grenadeType;
    g_LastGrenadeOrigin[client] = origin;
    g_LastGrenadeVelocity[client] = velocity;
}

public void LastGrenadePosition(int client) {
    if (!g_InPracticeMode || !g_InNaderMode) {
        return;
    }

    int index = g_GrenadeHistoryPositions[client].Length - 1;
    if (index >= 0) {
        g_GrenadeHistoryIndex[client] = index;
        TeleportToGrenadeHistoryPosition(client, index, MOVETYPE_WALK);
        
        char finalMsg[1024];
        Format(finalMsg, sizeof(finalMsg), "Teleporting back to position %d in grenade history.", index + 1);
        Message(client, finalMsg);
    }
    else
    {
        Message(client, "No grenade thrown yet.");
    }

    return;
}

public void BackGrenadePosition(int client, int args) {
    if (!g_InPracticeMode || !g_InNaderMode) {
        return;
    }

    char argString[64];
    if (args >= 1 && GetCmdArg(1, argString, sizeof(argString))) {
        int index = StringToInt(argString) - 1;
        if (index >= 0 && index < g_GrenadeHistoryPositions[client].Length) {
            g_GrenadeHistoryIndex[client] = index;
            TeleportToGrenadeHistoryPosition(client, g_GrenadeHistoryIndex[client], MOVETYPE_WALK);
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Teleporting back to position %d in grenade history.", g_GrenadeHistoryIndex[client] + 1);
            Message(client, finalMsg);
        } else {
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Your grenade history only goes from 1 to %d.", g_GrenadeHistoryPositions[client].Length);
            Message(client, finalMsg);
        }
        return;
    }

    if (g_GrenadeHistoryPositions[client].Length > 0) {
        g_GrenadeHistoryIndex[client]--;
        if (g_GrenadeHistoryIndex[client] < 0)
            g_GrenadeHistoryIndex[client] = 0;

        TeleportToGrenadeHistoryPosition(client, g_GrenadeHistoryIndex[client], MOVETYPE_WALK);
        
        char finalMsg[1024];
        Format(finalMsg, sizeof(finalMsg), "Teleporting back to position %d in grenade history.", g_GrenadeHistoryIndex[client] + 1);
        Message(client, finalMsg);
    }

    return;
}

public void ForwardGrenadePosition(int client, int args) {
    if (!g_InPracticeMode || !g_InNaderMode) {
        return;
    }

    char argString[64];
    if (args >= 1 && GetCmdArg(1, argString, sizeof(argString))) {
        int index = StringToInt(argString) - 1;
        if (index >= 0 && index < g_GrenadeHistoryPositions[client].Length) {
            g_GrenadeHistoryIndex[client] = index;
            TeleportToGrenadeHistoryPosition(client, g_GrenadeHistoryIndex[client], MOVETYPE_WALK);
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Teleporting forward to position %d in grenade history.", g_GrenadeHistoryIndex[client] + 1);
            Message(client, finalMsg);
        } else {
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Your grenade history only goes from 1 to %d.", g_GrenadeHistoryPositions[client].Length);
            Message(client, finalMsg);
        }
        return;
    }


    if (g_GrenadeHistoryPositions[client].Length > 0) {
        int max = g_GrenadeHistoryPositions[client].Length;
        g_GrenadeHistoryIndex[client]++;
        if (g_GrenadeHistoryIndex[client] >= max)
            g_GrenadeHistoryIndex[client] = max - 1;
            
        TeleportToGrenadeHistoryPosition(client, g_GrenadeHistoryIndex[client], MOVETYPE_WALK);
        
        char finalMsg[1024];
        Format(finalMsg, sizeof(finalMsg), "Teleporting forward to position %d in grenade history.", g_GrenadeHistoryIndex[client] + 1);
        Message(client, finalMsg);
    }

    return;
}

public void TeleportToGrenadeHistoryPosition(int client, int index, MoveType moveType) {
    float origin[3];
    float angles[3];
    float velocity[3];
    g_GrenadeHistoryPositions[client].GetArray(index, origin, sizeof(origin));
    g_GrenadeHistoryAngles[client].GetArray(index, angles, sizeof(angles));
    TeleportEntity(client, origin, angles, velocity);
    SetEntityMoveType(client, moveType);
}

public Action ThrowLastGrenade(int client, int args) {
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

public void ThrowGrenade(int client, GrenadeType grenadeType, const float origin[3], const float velocity[3]) {
    g_LastGrenadeType[client] = grenadeType;
    g_LastGrenadeOrigin[client] = origin;
    g_LastGrenadeVelocity[client] = velocity;
    
    char classname[64];
    GetProjectileName(grenadeType, classname, sizeof(classname));
    
    int entity = CreateEntityByName(classname);
    if (entity == -1) {
        LogError("Could not create nade %s", classname);
        return;
    }
    
    TeleportEntity(entity, origin, NULL_VECTOR, velocity);
    
    DispatchSpawn(entity);
    DispatchKeyValue(entity, "globalname", "custom");
    
    int team = CS_TEAM_T;
    if (IsValidClient(client)) {
        team = GetClientTeam(client);
    }
    
    AcceptEntityInput(entity, "InitializeSpawnFromWorld");
    AcceptEntityInput(entity, "FireUser1", client);

    SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
    SetEntPropEnt(entity, Prop_Send, "m_hThrower", client);
    
    if (grenadeType == GrenadeType_Incendiary) {
        SetEntProp(entity, Prop_Send, "m_bIsIncGrenade", true, 1);
        SetEntityModel(entity, "models/weapons/w_eq_incendiarygrenade_dropped.mdl");
    }
}