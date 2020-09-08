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

public bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

public bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}