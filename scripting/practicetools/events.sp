enum ClientColor {
    ClientColor_Yellow = 0,
    ClientColor_Purple = 1,
    ClientColor_Green = 2,
    ClientColor_Blue = 3,
    ClientColor_Orange = 4,
};

public Action Event_OnPluginStart() {
    HookEvent("weapon_fire", Event_WeaponFired);
    HookEvent("smokegrenade_detonate", Event_SmokeDetonate);
    HookEvent("flashbang_detonate", Event_FlashDetonate);
    HookEvent("player_blind", Event_PlayerBlind);
}

public void OnMapStart() {
    Nader_OnMapStart();
}

public void OnClientConnected(int client) {
    Nader_OnClientConnected(client);
}

public Action Event_WeaponFired(Event event, const char[] name, bool dontBroadcast) {
    Nader_WeaponFired(event, name, dontBroadcast);
}

public Action Event_SmokeDetonate(Event event, const char[] name, bool dontBroadcast) {
    Nader_SmokeDetonate(event, name, dontBroadcast);
}

public Action Event_FlashDetonate(Event event, const char[] name, bool dontBroadcast) {
    Nader_FlashDetonate(event, name, dontBroadcast);
}

public void OnEntityCreated(int entity, const char[] className) {
    if (!IsValidEntity(entity)) {
        return; 
    }
    
    Nader_OnEntityCreated(entity, className);
}

public Action Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast) {
    Nader_PlayerBlind(event, name, dontBroadcast);
}

public void QueryClientColor(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
    int color = StringToInt(cvarValue);
    GetColor(view_as<ClientColor>(color), g_ClientColors[client]);
}

public void GetColor(ClientColor c, int array[4]) {
    int r, g, b;
    switch (c) {
        case ClientColor_Yellow: {
            r = 229;
            g = 224;
            b = 44;
        }
        case ClientColor_Purple: {
            r = 150;
            g = 45;
            b = 225;
        }
        case ClientColor_Green: {
            r = 23;
            g = 255;
            b = 102;
        }
        case ClientColor_Blue: {
            r = 112;
            g = 191;
            b = 255;
        }
        case ClientColor_Orange: {
            r = 227;
            g = 152;
            b = 33;
        }
        default: {
            r = 23;
            g = 255;
            b = 102;
        }
    }
    array[0] = r;
    array[1] = g;
    array[2] = b;
    array[3] = 255;
}