stock void ClearNestedArray(ArrayList array) {
  for (int i = 0; i < array.Length; i++) {
    ArrayList h = view_as<ArrayList>(array.Get(i));
    delete h;
  }

  ClearArray(array);
}

stock ConVar GetCvar(const char[] name) {
  ConVar cvar = FindConVar(name);
  if (cvar == null) {
    SetFailState("Failed to find cvar: \"%s\"", name);
  }
  return cvar;
}

stock void ReadCvarKv(KeyValues kv, ArrayList cvars, ArrayList values) {
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

stock void ExecuteCvarLists(ArrayList cvars, ArrayList values) {
    char cvar[CVAR_NAME_LENGTH];
    char value[CVAR_VALUE_LENGTH];
    for (int i = 0; i < cvars.Length; i++) {
        cvars.GetString(i, cvar, sizeof(cvar));
        values.GetString(i, value, sizeof(value));
        ServerCommand("%s %s", cvar, value);
    }
}

public void AddChatAlias(const char[] alias, const char[] command)
{
    if (g_ChatAliases.FindString(alias) == -1) {
        g_ChatAliases.PushString(alias);
        g_ChatAliasesCommands.PushString(command);
    }
}

stock bool IsPlayer(int client) {
  return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

stock bool IsValidClient(int client) {
  return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

stock int FindStringInArray2(const char[][] array, int len, const char[] string, bool caseSensitive = true) {
    for (int i = 0; i < len; i++) {
        if (StrEqual(string, array[i], caseSensitive)) {
        return i;
        }
    }

    return -1;
}
