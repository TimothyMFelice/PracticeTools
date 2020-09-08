#define GRENADE_CATEGORY_LENGTH 128
#define GRENADE_ID_LENGTH 16
#define AUTH_LENGTH 64
#define AUTH_METHOD AuthId_Steam2


enum GrenadeType {
    GrenadeType_None = 0,
    GrenadeType_Smoke = 1,
    GrenadeType_Flash = 2,
    GrenadeType_HE = 3,
    GrenadeType_Molotov = 4,
    GrenadeType_Decoy = 5,
    GrenadeType_Incendiary = 6,
};

enum GrenadeFilterType {
    GrenadeFilterType_Invalid = -1,
    GrenadeFilterType_PlayersAndCategories = 0,
    GrenadeFilterType_Categories = 1,
    GrenadeFilterType_OnePlayer = 2,
    GrenadeFilterType_OneCategory = 3,
    GrenadeFilterType_MatchingName = 4,
    GrenadeFilterType_MatchingId = 5,
    GrenadeFilterType_MultiCategory = 6,
};


GrenadeType g_LastGrenadeType[MAXPLAYERS + 1];
float g_LastGrenadeOrigin[MAXPLAYERS + 1][3];
float g_LastGrenadeVelocity[MAXPLAYERS + 1][3];


public bool IsGrenadeProjectile(const char[] className) {
    static char projectileTypes[][] = {
        "hegrenade_projectile", 
        "smokegrenade_projectile",
        "decoy_projectile",
        "flashbang_projectile", 
        "molotov_projectile",
    };

    return FindStringInArray2(projectileTypes, sizeof(projectileTypes), className) >= 0;
}

stock GrenadeType GrenadeFromProjectileName(const char[] projectileName, int entity = 0) {
  if (StrEqual(projectileName, "smokegrenade_projectile")) {
    return GrenadeType_Smoke;
  } else if (StrEqual(projectileName, "flashbang_projectile")) {
    return GrenadeType_Flash;
  } else if (StrEqual(projectileName, "hegrenade_projectile")) {
    return GrenadeType_HE;
  } else if (StrEqual(projectileName, "decoy_projectile")) {
    return GrenadeType_Decoy;
  } else if (StrEqual(projectileName, "molotov_projectile")) {
    if (IsValidEntity(entity)) {
      int isInc = GetEntData(entity, FindSendPropInfo("CMolotovProjectile", "m_bIsIncGrenade"), 1);
      return isInc ? GrenadeType_Incendiary : GrenadeType_Molotov;
    }
    return GrenadeType_Molotov;
  } else {
    return GrenadeType_None;
  }
}

stock void TeleportToGrenadeHistoryPosition(int client, int index, MoveType moveType = MOVETYPE_WALK) {
    float origin[3];
    float angles[3];
    float velocity[3];
    g_GrenadeHistoryPositions[client].GetArray(index, origin, sizeof(origin));
    g_GrenadeHistoryAngles[client].GetArray(index, angles, sizeof(angles));
    TeleportEntity(client, origin, angles, velocity);
    SetEntityMoveType(client, moveType);
}

public bool IsGrenadeWeapon(const char[] weapon) {
    static char grenades[][] = {
        "weapon_incgrenade", "weapon_molotov",   "weapon_hegrenade",
        "weapon_decoy",      "weapon_flashbang", "weapon_smokegrenade",
    };

    return FindStringInArray2(grenades, sizeof(grenades), weapon) >= 0;
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

public bool IsGrenade(GrenadeType g) {
    return g != GrenadeType_None;
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

stock void GetProjectileName(GrenadeType type, char[] buffer, int length) {
    switch (type) {
        case GrenadeType_Smoke:
            Format(buffer, length, "smokegrenade_projectile");
        case GrenadeType_Flash:
            Format(buffer, length, "flashbang_projectile");
        case GrenadeType_HE:
            Format(buffer, length, "hegrenade_projectile");
        case GrenadeType_Molotov:
            Format(buffer, length, "molotov_projectile");
        case GrenadeType_Decoy:
            Format(buffer, length, "decoy_projectile");
        case GrenadeType_Incendiary:
            Format(buffer, length, "molotov_projectile");
        default:
            LogError("Unknown grenade type: %d", type);
    }
}

public void GetGrenadeParameters(int entity) {
    //if (HandleNativeRequestedNade(entity)) {
    //    return;
    //}
  
    RequestFrame(DelayCaptureEntity, entity);
}

public void DelayCaptureEntity(int entity) {
    RequestFrame(CaptureEntity, entity);
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