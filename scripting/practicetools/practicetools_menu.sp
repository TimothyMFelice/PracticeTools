#define CHOICE1 "#Nader"
#define CHOICE2 "#choice2"
#define CHOICE3 "#choice3"

public void GivePracticeMenu(int client)
{
  Menu practiceMenu = new Menu(PracticeMenuHandler, MENU_ACTIONS_ALL);
  practiceMenu.SetTitle("%T", "Menu Title", LANG_SERVER);
  
  practiceMenu.AddItem(CHOICE1, "Nader");
  practiceMenu.AddItem(CHOICE2, "Choice 2");
  practiceMenu.AddItem(CHOICE3, "Choice 3");
  
  practiceMenu.ExitButton = true;
  
  practiceMenu.Display(client, MENU_TIME_FOREVER);
}

public int PracticeMenuHandler(Menu practiceMenu, MenuAction action, int param1, int param2)
{
  switch(action)
  {
    case MenuAction_Start:
    {
      PrintToServer("Displaying Practice Tools Menu");
    }
 
    case MenuAction_Display:
    {
    }
 
    case MenuAction_Select:
    {
      char info[32];
      practiceMenu.GetItem(param2, info, sizeof(info));
      PrintToServer("Client %d selected %s", param1, info);
      if (StrEqual(info, CHOICE1))
      {
        LaunchNaderMode();
      }
      else
      {
        PrintToServer("Client %d selected %s", param1, info);
      }
    }
 
    case MenuAction_Cancel:
    {
      PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
    }
 
    case MenuAction_End:
    {
      delete practiceMenu;
    }
 
    case MenuAction_DrawItem:
    {
    }
 
    case MenuAction_DisplayItem:
    {
      char info[32];
      practiceMenu.GetItem(param2, info, sizeof(info));
 
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
