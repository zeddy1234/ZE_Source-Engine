#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors_csgo>

#pragma newdecls required
#define PLUGIN_VERSION "1.0"

#define MAX_BUTTONS 32
#define SETTING_FLAG ADMFLAG_ROOT

enum struct Button {
	int iHammerId;
	char szName[64];
}

Button g_buttons[MAX_BUTTONS];
int g_iButtons = 0;

bool g_bRoomSet = false;

enum ModifySetting {
	NONE, NAME, BUTTON, CONFIRM, DELETE
}

ModifySetting g_SetupStage[MAXPLAYERS+1] = {NONE, ...};
Button g_SetupButton[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "AdminRoom",
	author = "ZeddY^, Strellic",
	description = "A plugin that allows admins to teleport to admin rooms and change levels all via a menu.",
	version = PLUGIN_VERSION
};

float g_fRoomOrigin[3], g_fRoomAngles[3];

public void OnPluginStart() {
	CreateConVar("sm_adminroom_version", PLUGIN_VERSION, "AdminRoom Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_adminroom", Command_AdminRoom, ADMFLAG_BAN, "AdminRoom plugin command.");
	RegAdminCmd("sm_ar", Command_AdminRoom, ADMFLAG_BAN, "AdminRoom plugin command.");

	HookEntityOutput("func_button", "OnPressed", Event_ButtonPressed);

	LoadMapConfig();
}

public void OnMapStart() {
	LoadMapConfig();
}

public void LoadMapConfig() {
	char mapname[128], filename[256];
	GetCurrentMap(mapname, sizeof(mapname));
	Format(filename, sizeof(filename), "addons/sourcemod/configs/adminrooms/%s.cfg", mapname);

	g_iButtons = 0;
	g_bRoomSet = false;

	if(!FileExists(filename)) {
		return;
	}
	
	KeyValues kv = new KeyValues("Adminrooms");
	kv.ImportFromFile(filename);

	kv.GetVector("position", g_fRoomOrigin);
	kv.GetVector("angles", g_fRoomAngles);

	if(kv.JumpToKey("position")) {
		g_bRoomSet = true;
		kv.GoBack();
	}

	if(kv.GotoFirstSubKey()) {
		do {
			char defLevel[4];
			IntToString(g_iButtons + 1, defLevel, sizeof(defLevel));

			Button button;
			button.iHammerId = kv.GetNum("hammerID");
			kv.GetString("name", button.szName, sizeof(button.szName), defLevel); 

			g_buttons[g_iButtons++] = button;
		} while (kv.GotoNextKey());
	}

	delete kv;
}

public bool DoesClientHaveSettingsPrivilege(int client) {
	return CheckCommandAccess(client, "adminroom_settings", SETTING_FLAG, false);
}

public Action Command_AdminRoom(int client, int argc) {
	DisplayAdminRoomMenu(client);
	return Plugin_Handled;
}

public void DisplayAdminRoomMenu(int client) {
	Menu menu = new Menu(AdminRoom_MenuHandler);
	menu.SetTitle("AdminRoom Menu");

	if(g_bRoomSet) {
		menu.AddItem("tele", "Teleport");
	}
	else {
		menu.AddItem("set", "Set Admin Room");
	}

	if(DoesClientHaveSettingsPrivilege(client)) {
		menu.AddItem("settings", "Settings Menu");
	}

	if(g_iButtons != 0) {
		menu.AddItem("--", "-- LEVELS --", ITEMDRAW_DISABLED);

		for(int i = 0; i < g_iButtons; i++) {
			menu.AddItem(g_buttons[i].szName, g_buttons[i].szName);
		}
	}


	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int AdminRoom_MenuHandler(Menu menu, MenuAction action, int client, int choice) {
    if (action == MenuAction_End)
		delete menu;
	else if (action == MenuAction_Select) {
		char option[64];
		menu.GetItem(choice, option, sizeof(option));

		if(StrEqual(option, "tele")) {
			PrintToChat(client, "[SM] You have been teleported to the admin room.");
			CPrintToChatAll("{green}[SM]{default} Moderator {red}%N {default}has teleported to the {red}admin room{default}!", client);
			TeleportEntity(client, g_fRoomOrigin, g_fRoomAngles, NULL_VECTOR);
		}
		else if(StrEqual(option, "settings") && DoesClientHaveSettingsPrivilege(client)) {
			DisplaySettingsMenu(client);
		}
		else if(StrEqual(option, "set")) {
			GetClientAbsOrigin(client, g_fRoomOrigin);
			GetClientAbsAngles(client, g_fRoomAngles);

			KeyValues kv = new KeyValues("Adminrooms");
			kv.SetVector("position", g_fRoomOrigin);
			kv.SetVector("angles", g_fRoomAngles);

			char mapname[128], filename[256];
			GetCurrentMap(mapname, sizeof(mapname));
			Format(filename, sizeof(filename), "addons/sourcemod/configs/adminrooms/%s.cfg", mapname);

			kv.ExportToFile(filename);

			PrintToChat(client, "[SM] The new admin room config has been saved.");

			delete kv;

			LoadMapConfig();
		}
		else {
			for(int i = 0; i < MAX_BUTTONS; i++) {
				if(StrEqual(option, g_buttons[i].szName)) {
					int ent = GetEntityFromHammerID(g_buttons[i].iHammerId);
					if(ent != -1) {
						AcceptEntityInput(ent, "Press", client, client);
						PrintToChat(client, "[SM] The '%s' option has been selected.", option);
						CPrintToChatAll("{green}[SM]{default} Moderator {red}%N {default}has pressed the {red}%s{default} button!", client, option);
					}
					break;
				}
			}
		}
	}
}
 
public void DisplaySettingsMenu(int client) {
	Menu menu = new Menu(AdminRoomSettings_MenuHandler);
	menu.SetTitle("AdminRoom Settings Menu");

	menu.AddItem("reload", "Reload Config");
	menu.AddItem("delete", "Delete Config");
	menu.AddItem("add", "Add Button");

	if(g_iButtons > 0)
		menu.AddItem("deleteb", "Delete Button");
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int AdminRoomSettings_MenuHandler(Menu menu, MenuAction action, int client, int choice) {
    if (action == MenuAction_End || !DoesClientHaveSettingsPrivilege(client))
		delete menu;
	else if (action == MenuAction_Cancel) 
		DisplayAdminRoomMenu(client);
	else if (action == MenuAction_Select) {
		char option[64];
		menu.GetItem(choice, option, sizeof(option));

		if(StrEqual(option, "reload")) {
			LoadMapConfig();
			PrintToChat(client, "[SM] The admin room config has been reloaded.");
		}
		else if(StrEqual(option, "delete")) {
			char mapname[128], filename[256];
			GetCurrentMap(mapname, sizeof(mapname));
			Format(filename, sizeof(filename), "addons/sourcemod/configs/adminrooms/%s.cfg", mapname);

			if(FileExists(filename))
				DeleteFile(filename);

			g_iButtons = 0;

			PrintToChat(client, "[SM] The admin room config has been deleted.");
			LoadMapConfig();
		}
		else if(StrEqual(option, "add")) {
			PrintToChat(client, "[SM] Type the name of the new button in chat (type 'exit' to quit):");
			g_SetupStage[client] = NAME;
		}
		else if(StrEqual(option, "deleteb")) {
			PrintToChat(client, "[SM] Type the name of the button you want to delete in chat (type 'exit' to quit):");
			g_SetupStage[client] = DELETE;
		}
	}
}

stock int GetEntityFromHammerID(int hammerID) {
    for (int i = 0; i < GetEntityCount(); i++) {
        if (IsValidEdict(i)) {
            if (GetEntProp(i, Prop_Data, "m_iHammerID") == hammerID) {
                return i;
            }
        }
    }
    return -1;
}

stock int GetHammerIDFromEntity(int entity) {
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if(g_SetupStage[client] == NAME) {
		if(StrEqual(sArgs, "exit", true)) {
			PrintToChat(client, "[SM] Button setup cancelled.");
			g_SetupStage[client] = NONE;

			return Plugin_Handled;	
		}
		else {
			int id = -1;
			for(int i = 0; i < g_iButtons; i++) {
				if(StrEqual(g_buttons[i].szName, sArgs)) {
					id = i;
					break;
				}
			}

			if(id != -1) {
				PrintToChat(client, "[SM] A button already exists with that name! Please type the name of the button you want to add (type 'exit' to cancel):", sArgs);
			}
			else {
				PrintToChat(client, "[SM] You have chosen the name '%s'. Now, press the button that you want to add (type 'exit' to cancel):", sArgs);
				g_SetupStage[client] = BUTTON;
				strcopy(g_SetupButton[client].szName, sizeof(g_SetupButton[].szName), sArgs);
			}

			return Plugin_Handled;
		}
	}
	else if(g_SetupStage[client] == BUTTON) {
		if(StrEqual(sArgs, "exit", true)) {
			PrintToChat(client, "[SM] Button setup cancelled.");
			g_SetupStage[client] = NONE;

			return Plugin_Handled;	
		}
	}
	else if(g_SetupStage[client] == CONFIRM) {
		if(StrEqual(sArgs, "exit", true)) {
			PrintToChat(client, "[SM] Button setup cancelled.");
			g_SetupStage[client] = NONE;

			return Plugin_Handled;	
		}
		else if(StrEqual(sArgs, "confirm", true)) {
			g_SetupStage[client] = NONE;

			char mapname[128], filename[256];
			GetCurrentMap(mapname, sizeof(mapname));
			Format(filename, sizeof(filename), "addons/sourcemod/configs/adminrooms/%s.cfg", mapname);

			KeyValues kv = new KeyValues("Adminrooms");
			kv.ImportFromFile(filename);

			char nextKey[8];
			IntToString(g_iButtons, nextKey, sizeof(nextKey));

			kv.JumpToKey(nextKey, true);
			kv.SetString("name", g_SetupButton[client].szName);
			kv.SetNum("hammerID", g_SetupButton[client].iHammerId);

			kv.Rewind();
			kv.ExportToFile(filename);

			delete kv;

			LoadMapConfig();

			PrintToChat(client, "[SM] The setup of the new option '%s' was successful.", g_SetupButton[client].szName);

			strcopy(g_SetupButton[client].szName, sizeof(g_SetupButton[].szName), "");
			g_SetupButton[client].iHammerId = 0;

			return Plugin_Handled;	
		}
	}
	else if(g_SetupStage[client] == DELETE) {
		if(StrEqual(sArgs, "exit", true)) {
			PrintToChat(client, "[SM] Button deletion cancelled.");
			g_SetupStage[client] = NONE;

			return Plugin_Handled;	
		}
		else {
			g_SetupStage[client] = NONE;

			char mapname[128], filename[256];
			GetCurrentMap(mapname, sizeof(mapname));
			Format(filename, sizeof(filename), "addons/sourcemod/configs/adminrooms/%s.cfg", mapname);

			KeyValues kv = new KeyValues("Adminrooms");
			kv.ImportFromFile(filename);

			int id = -1;
			for(int i = 0; i < g_iButtons; i++) {
				if(StrEqual(g_buttons[i].szName, sArgs)) {
					id = i;
					break;
				}
			}

			if(id != -1) {
				char delKey[8];
				IntToString(id, delKey, sizeof(delKey));

				kv.JumpToKey(delKey);
				kv.DeleteThis();
				kv.Rewind();

				int n = 0;
				if(kv.GotoFirstSubKey()) {
					do {
						char szName[8];
						kv.GetSectionName(szName, sizeof(szName));
						IntToString(n++, szName, sizeof(szName));
						kv.SetSectionName(szName);
					} while (kv.GotoNextKey());
				}

				kv.Rewind();

				kv.ExportToFile(filename);
				PrintToChat(client, "[SM] The deletion of the option '%s' was successful.", sArgs);
			}
			else {
				PrintToChat(client, "[SM] No entry was found with the name '%s'.", sArgs);
			}
				
			delete kv;
			LoadMapConfig();

			return Plugin_Handled;	
		}
	}

	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool nobots = true) { 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client))) {
        return false; 
    }
    return IsClientInGame(client); 
} 

public Action Event_ButtonPressed(const char[] output, int entity, int client, float delay) {
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(g_SetupStage[client] == BUTTON) {
		g_SetupButton[client].iHammerId = GetHammerIDFromEntity(entity);

		char szName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", szName, sizeof(szName));

		if(strlen(szName) == 0)
			Format(szName, sizeof(szName), "None");

		PrintToChat(client, "[SM] Button selected (Targetname: %s, HammerID: %i, Display Name: %s). Does this look right to you? (type 'exit' to cancel or 'confirm' to save)", szName, g_SetupButton[client].iHammerId, g_SetupButton[client].szName);
		g_SetupStage[client] = CONFIRM;

		return Plugin_Stop;
	}
	return Plugin_Continue;
}
