#define CHOICE1 "#Nader"
#define CHOICE2 "#Prefire"
#define CHOICE3 "#DemoViewer"

public void PracticeToolsMenu_OnPluginStart() {
    LoadTranslations("PracticeMenu.phrases");
}

public void StartPracticeTools(int client) {
    if (!g_InPracticeMode)
        GivePracticeToolsMenu(client);
}

public void ExitPracticeTools() {
    if (g_InPracticeMode)
    {
        if (g_InNaderMode)
        {
            ExitNaderMode();
            return;
        }
    }
}

public void GivePracticeToolsMenu(int client) {
    Menu practiceToolsMenu = new Menu(PracticeToolsMenuHandler, MENU_ACTIONS_ALL);
    practiceToolsMenu.SetTitle("%T", "Menu Title", LANG_SERVER);
    
    practiceToolsMenu.AddItem(CHOICE1, "Nader");
    practiceToolsMenu.AddItem(CHOICE2, "Prefire");
    practiceToolsMenu.AddItem(CHOICE3, "DemoViewer");
    
    practiceToolsMenu.ExitBackButton = false;
    
    practiceToolsMenu.Display(client, MENU_TIME_FOREVER);
}

public int PracticeToolsMenuHandler(Menu practiceToolsMenu, MenuAction action, int param1, int param2) {
    switch(action)
    {
        case MenuAction_Start:
        {
            MessageToServer("Displaying Practice Tools Menu");
        }
 
        case MenuAction_Display:
        {
        }
 
        case MenuAction_Select:
        {
            char info[32];
            practiceToolsMenu.GetItem(param2, info, sizeof(info));
            
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Client %d selected %s", param1, info);
            MessageToServer(finalMsg);
            
            if (StrEqual(info, CHOICE1))
            {
                StartNader();
            }
            else
            {
                Format(finalMsg, sizeof(finalMsg), "Client %d selected %s", param1, info);
                MessageToServer(finalMsg);
            }
        }
 
        case MenuAction_Cancel:
        {
            char finalMsg[1024];
            Format(finalMsg, sizeof(finalMsg), "Client %d's menu was cancelled for reason %d", param1, param2);
            MessageToServer(finalMsg);
        }
 
        case MenuAction_End:
        {
            delete practiceToolsMenu;
        }
 
        case MenuAction_DrawItem:
        {
        }
 
        case MenuAction_DisplayItem:
        {
            char info[32];
            practiceToolsMenu.GetItem(param2, info, sizeof(info));
 
            char display[64];
 
            if (StrEqual(info, CHOICE1))
            {
                Format(display, sizeof(display), "%T", "Nader Menu Item", param1);
                return RedrawMenuItem(display);
            }
       }
    }
    return 0;
}