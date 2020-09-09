public void ClearNestedArray(ArrayList array) {
    for (int i = 0; i < array.Length; i++) {
        ArrayList h = view_as<ArrayList>(array.Get(i));
        delete h;
    }

    ClearArray(array);
}

public void ReadCvarKv(KeyValues kv, ArrayList cvars, ArrayList values) {
    char cvarName[CVAR_NAME_LENGTH];
    char cvarValue[CVAR_VALUE_LENGTH];
    if (kv.GotoFirstSubKey(false)) {
        do {
            kv.GetSectionName(cvarName, sizeof(cvarName));
            cvars.PushString(cvarName);
            kv.GetString(NULL_STRING, cvarValue, sizeof(cvarValue));
            values.PushString(cvarValue);
            LogMessage("cvarName: %s | cvarValue: %s", cvarName, cvarValue);
        } while (kv.GotoNextKey(false));
        kv.GoBack();
    }
}

public void ExecuteCvarLists(ArrayList cvars, ArrayList values) {
    char cvar[CVAR_NAME_LENGTH];
    char value[CVAR_VALUE_LENGTH];
    for (int i = 0; i < cvars.Length; i++) {
        cvars.GetString(i, cvar, sizeof(cvar));
        values.GetString(i, value, sizeof(value));
        ServerCommand("%s %s", cvar, value);
    }
}

public ConVar GetCvar(const char[] name) {
    ConVar cvar = FindConVar(name);
    if (cvar == null) {
        SetFailState("Failed to find cvar: \"%s\"", name);
    }
    return cvar;
}

public bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

public bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

public bool IsGrenadeWeapon(const char[] weapon) {
    static char grenades[][] = {
        "weapon_incgrenade", "weapon_molotov",   "weapon_hegrenade",
        "weapon_decoy",      "weapon_flashbang", "weapon_smokegrenade",
    };

    return FindStringInArray2(grenades, sizeof(grenades), weapon, false) >= 0;
}

public int FindStringInArray2(const char[][] array, int len, const char[] string, bool caseSensitive) {
    for (int i = 0; i < len; i++) {
        if (StrEqual(string, array[i], caseSensitive)) {
        return i;
        }
    }

    return -1;
}

public bool IsGrenade(GrenadeType g) {
    return g != GrenadeType_None;
}

public GrenadeType GrenadeFromProjectileName(const char[] projectileName, int entity) {
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

public bool IsGrenadeProjectile(const char[] className) {
    static char projectileTypes[][] = {
        "hegrenade_projectile", 
        "smokegrenade_projectile",
        "decoy_projectile",
        "flashbang_projectile", 
        "molotov_projectile",
    };

    return FindStringInArray2(projectileTypes, sizeof(projectileTypes), className, false) >= 0;
}

public void GetProjectileName(GrenadeType type, char[] buffer, int length) {
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