#define CVAR_NAME_LENGTH 64
#define CVAR_VALUE_LENGTH 128

ArrayList g_NaderStartCvars;
ArrayList g_NaderStartValues;
ArrayList g_NaderEndCvars;
ArrayList g_NaderEndValues;

public void Nader_OnPluginStart() {
    g_NaderStartCvars = new ArrayList();
    g_NaderStartValues = new ArrayList();
    g_NaderEndCvars = new ArrayList();
    g_NaderEndValues = new ArrayList();
}

public void StartNader() {
    g_InPracticeMode = true;
    g_InNaderMode = true;
    
    ReadNaderSettings();
    SetNaderSettings();
    
    MessageToAll("Nader Tool is now enabled");
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