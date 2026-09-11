/**
 * vim: set ts=4 :
 * =============================================================================
 * Nominations Extended
 * Allows players to nominate maps for Mapchooser
 *
 * Nominations Extended (C)2012-2013 Powerlord (Ross Bemrose)
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>
#include <mapchooser>
#include "include/mapchooser_extended"
#include <colors_csgo>
#include <store>

#pragma semicolon 1

#define MCE_VERSION "1.10.0"

public Plugin:myinfo =
{
	name = "Map Nominations Extended",
	author = "Powerlord and AlliedModders LLC",
	description = "Provides Map Nominations",
	version = MCE_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=156974"
};

new Handle:g_Cvar_ExcludeOld = INVALID_HANDLE;
new Handle:g_Cvar_ExcludeCurrent = INVALID_HANDLE;

ConVar g_Cvar_NominationPerk;
ConVar g_Cvar_NominationPrice;

ConVar g_Cvar_NominationPlayers;

new Handle:g_MapList = INVALID_HANDLE;
new Handle:g_MapMenu = INVALID_HANDLE;
new g_mapFileSerial = -1;

StringMap g_PrevMapCounter = null;

#define MAPSTATUS_ENABLED (1<<0)
#define MAPSTATUS_DISABLED (1<<1)
#define MAPSTATUS_EXCLUDE_CURRENT (1<<2)
#define MAPSTATUS_EXCLUDE_PREVIOUS (1<<3)
#define MAPSTATUS_EXCLUDE_NOMINATED (1<<4)

new Handle:g_mapTrie;

bool g_bNominatePerk = true;
int g_iNominatePrice = 50;

bool g_bPlayerNominated[MAXPLAYERS+1] = {false, ...};
bool g_bPlayerSwitched[MAXPLAYERS+1] = {false, ...};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("nominations.phrases");
	LoadTranslations("basetriggers.phrases"); // for Next Map phrase
	LoadTranslations("mapchooser_extended.phrases");
	
	new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);	
	g_MapList = CreateArray(arraySize);
	
	g_Cvar_ExcludeOld = CreateConVar("sm_nominate_excludeold", "1", "Specifies if the current map should be excluded from the Nominations list", 0, true, 0.00, true, 1.0);
	g_Cvar_ExcludeCurrent = CreateConVar("sm_nominate_excludecurrent", "1", "Specifies if the MapChooser excluded maps should also be excluded from Nominations", 0, true, 0.00, true, 1.0);
	
	g_Cvar_NominationPerk = CreateConVar("sm_nominate_vip_perk", "1", "Specifies if a player's VIP status should be checked");
	g_Cvar_NominationPrice = CreateConVar("sm_nominate_vip_price", "50", "The price in credits for non-VIP to nominate");
	g_Cvar_NominationPerk.AddChangeHook(NominateVIP_ConVarChange);
	g_Cvar_NominationPrice.AddChangeHook(NominateVIP_ConVarChange);

	g_Cvar_NominationPlayers = CreateConVar("sm_nominate_players", "0", "Specifies the number of players needed before nomination is enabled.");

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegConsoleCmd("sm_nominate", Command_Nominate);
	
	RegAdminCmd("sm_nominate_addmap", Command_Addmap, ADMFLAG_CHANGEMAP, "sm_nominate_addmap <mapname> - Forces a map to be on the next mapvote.");
	
	// Nominations Extended cvars
	CreateConVar("ne_version", MCE_VERSION, "Nominations Extended Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_PrevMapCounter = CreateTrie();
	g_mapTrie = CreateTrie();

	LoadConVars();
}

public void NominateVIP_ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    LoadConVars();
}

public void LoadConVars() {
	g_bNominatePerk = (g_Cvar_NominationPerk.IntValue == 1);
	g_iNominatePrice = g_Cvar_NominationPrice.IntValue;
}

public OnConfigsExecuted()
{
	if (ReadMapList(g_MapList,
					g_mapFileSerial,
					"nominations",
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		== INVALID_HANDLE)
	{
		if (g_mapFileSerial == -1)
		{
			SetFailState("Unable to create a valid map list.");
		}
	}
	
	BuildMapMenu();

	for(int i = 1; i <= MaxClients; i++) {
		g_bPlayerNominated[i] = false;
		g_bPlayerSwitched[i] = false;
	}
}

public void OnClientDisconnect(int client) {
	g_bPlayerNominated[client] = false;
	g_bPlayerSwitched[client] = false;
}

public OnNominationRemoved(const String:map[], owner)
{
	new status;
	
	/* Is the map in our list? */
	if (!GetTrieValue(g_mapTrie, map, status))
	{
		return;	
	}
	
	/* Was the map disabled due to being nominated */
	if ((status & MAPSTATUS_EXCLUDE_NOMINATED) != MAPSTATUS_EXCLUDE_NOMINATED)
	{
		return;
	}
	
	SetTrieValue(g_mapTrie, map, MAPSTATUS_ENABLED);	
}

public Action:Command_Addmap(client, args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "[NE] Usage: sm_nominate_addmap <mapname>");
		return Plugin_Handled;
	}
	
	decl String:mapname[PLATFORM_MAX_PATH];
	GetCmdArg(1, mapname, sizeof(mapname));

	
	new status;
	if (!GetTrieValue(g_mapTrie, mapname, status))
	{
		CReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;		
	}
	
	new NominateResult:result = NominateMap(mapname, true, 0);
	
	if (result > Nominate_Replaced)
	{
		/* We assume already in vote is the casue because the maplist does a Map Validity check and we forced, so it can't be full */
		CReplyToCommand(client, "%t", "Map Already In Vote", mapname);
		
		return Plugin_Handled;	
	}
	
	
	SetTrieValue(g_mapTrie, mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

	
	CReplyToCommand(client, "%t", "Map Inserted", mapname);
	LogAction(client, -1, "\"%L\" inserted map \"%s\".", client, mapname);

	return Plugin_Handled;		
}

public Action:Command_Say(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}

	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "nominate", false) == 0)
	{
		if (IsNominateAllowed(client))
		{
			//AttemptNominate(client);
			OpenNominationMenu(client);
		}
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

/*
public Action:Command_Nominate(client, args)
{
	if (!client || !IsNominateAllowed(client))
	{
		return Plugin_Handled;
	}
	
	if(!hasFreeNomination(client) && g_iNominatePrice > Store_GetClientCredits(client) && !g_bPlayerNominated[client]) {
		CReplyToCommand(client, "%t", "Not Enough Credits", g_iNominatePrice);
		return Plugin_Handled;
	}

	if (args == 0)
	{
		AttemptNominate(client);
		return Plugin_Handled;
	}
	
	decl String:mapname[PLATFORM_MAX_PATH];
	GetCmdArg(1, mapname, sizeof(mapname));
	
	new status;
	if (!GetTrieValue(g_mapTrie, mapname, status))
	{
		CReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;		
	}
	
	if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
	{
		if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
		{
			CReplyToCommand(client, "%t", "Can't Nominate Current Map");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
		{
			CReplyToCommand(client, "%t", "Map in Exclude List");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
		{
			CReplyToCommand(client, "%t", "Map Already Nominated");
		}
		
		return Plugin_Handled;
	}
	
	new NominateResult:result = NominateMap(mapname, false, client);
	
	if (result > Nominate_Replaced)
	{
		if (result == Nominate_AlreadyInVote)
		{
			CReplyToCommand(client, "%t", "Map Already In Vote", mapname);
		}
		else
		{
			CReplyToCommand(client, "%t", "Map Already Nominated");
		}
		
		return Plugin_Handled;	
	}

	
	SetTrieValue(g_mapTrie, mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);
	
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	CPrintToChatAll("%t", "Map Nominated", name, mapname);
	LogMessage("%s nominated %s", name, mapname);

	return Plugin_Continue;
}

AttemptNominate(client)
{
	SetMenuTitle(g_MapMenu, "%T", "Nominate Title", client);
	DisplayMenu(g_MapMenu, client, MENU_TIME_FOREVER);
	
	return;
}

*/

public Action Command_Nominate(int client, int args)
{
	if (!client || !IsNominateAllowed(client))
	{
		return Plugin_Handled;
	}

	if(!hasFreeNomination(client) && g_iNominatePrice > Store_GetClientCredits(client) && !g_bPlayerNominated[client]) {
		CReplyToCommand(client, "%t", "Not Enough Credits", g_iNominatePrice);
		return Plugin_Handled;
	}

	ReplySource source = GetCmdReplySource();
	
	if (args == 0)
	{	
		if (source == SM_REPLY_TO_CHAT)
		{
			OpenNominationMenu(client);
		}
		else
		{
			CReplyToCommand(client, "[SM] Usage: sm_nominate <mapname>");
		}
		
		return Plugin_Handled;
	}

	char mapname[PLATFORM_MAX_PATH];
	GetCmdArg(1, mapname, sizeof(mapname));

	ArrayList results = new ArrayList();
	int matches = FindMatchingMaps(g_MapList, results, mapname);

	char mapResult[PLATFORM_MAX_PATH];

	if (matches <= 0)
	{
		CReplyToCommand(client, "%t", "Map was not found", mapname);
	}
	// One result
	else if (matches == 1)
	{
		// Get the result and nominate it
		GetArrayString(g_MapList, results.Get(0), mapResult, sizeof(mapResult));
		AttemptNominate(client, mapResult, sizeof(mapResult));
	}
	else if (matches > 1)
	{
		if (source == SM_REPLY_TO_CONSOLE)
		{
			// if source is console, attempt instead of displaying menu.
			AttemptNominate(client, mapname, sizeof(mapname));
			delete results;
			return Plugin_Handled;
		}

		// Display results to the client and end
		Menu menu = new Menu(MenuHandler_MapSelect, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);
		menu.SetTitle("Select map");
		
		for (int i = 0; i < results.Length; i++)
		{
			GetArrayString(g_MapList,results.Get(i), mapResult, sizeof(mapResult));
			menu.AddItem(mapResult, mapResult);
		}

		menu.Display(client, 30);
	}

	delete results;

	return Plugin_Handled;
}


int FindMatchingMaps(Handle mapList, ArrayList results, const char[] input)
{
	int map_count = GetArraySize(mapList);

	if (!map_count)
	{
		return -1;
	}

	int matches = 0;
	char map[PLATFORM_MAX_PATH];

	for (int i = 0; i < map_count; i++)
	{
		GetArrayString(mapList, i, map, sizeof(map));
		if (StrContains(map, input) != -1)
		{
			results.Push(i);
			matches++;
		}
	}

	return matches;
}

void AttemptNominate(int client, const char[] map, int size, bool confirm = false)
{
	int count = 0;
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i))
			count++;
	}
	
	if(count < g_Cvar_NominationPlayers.IntValue) {
		CReplyToCommand(client, "%t", "Not Enough Players", count, g_Cvar_NominationPlayers.IntValue);
		return;
	}

	char mapname[PLATFORM_MAX_PATH];
	if (FindMap(map, mapname, size) == FindMap_NotFound)
	{
		// We couldn't resolve the map entry to a filename, so...
		CReplyToCommand(client, "%t", "Map was not found", mapname);
		return;		
	}
	
	char displayName[PLATFORM_MAX_PATH];
	GetMapDisplayName(mapname, displayName, sizeof(displayName));
	
	int status;
	if (!GetTrieValue(g_mapTrie, mapname, status))
	{
		CReplyToCommand(client, "%t", "Map was not found", displayName);
		return;		
	}
	
	if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
	{
		if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
		{
			CReplyToCommand(client, "%t", "Can't Nominate Current Map");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
		{
			CReplyToCommand(client, "%t", "Map in Exclude List");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
		{
			CReplyToCommand(client, "%t", "Map Already Nominated");
		}
		
		return;
	}
	
	if(hasFreeNomination(client) || confirm || g_bPlayerNominated[client]) {
		NominateResult result = NominateMap(mapname, false, client);
	
		if (result > Nominate_Replaced)
		{
			if (result == Nominate_AlreadyInVote)
			{
				CReplyToCommand(client, "%t", "Map Already In Vote", displayName);
			}
			else
			{
				CReplyToCommand(client, "%t", "Map Already Nominated");
			}
			
			return;	
		}

		SetTrieValue(g_mapTrie, mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);
		
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));

		if(confirm) {
			Store_SetClientCredits(client, Store_GetClientCredits(client) - g_iNominatePrice);
			CReplyToCommand(client, "%t", "Credits Charged", g_iNominatePrice, displayName);
			CPrintToChatAll("%t", "Map Nominated", name, displayName);
		}
		else {
			if(g_bPlayerNominated[client]) {
				CReplyToCommand(client, "%t", "Switch Nomination", displayName);
				CPrintToChatAll("%t", "Map Nominated", name, displayName);
				g_bPlayerSwitched[client] = true;
			}
			else
				CPrintToChatAll("%t", "Map Nominated Free", name, displayName);
		}

		g_bPlayerNominated[client] = true;
	}
	else {
		ConfirmNominationMenu(client, map);
	}

	return;
}

void ConfirmNominationMenu(int client, const char[] map) {
	Menu menu = CreateMenu(MenuHandler_Confirm);
	menu.SetTitle("Nominate %s for %i credits?", map, g_iNominatePrice);
	menu.AddItem(map, "Yes");
	menu.AddItem("No", "No");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Confirm(Menu menu, MenuAction action, int client, int position) {
	if(action == MenuAction_Select) {
		char choice[PLATFORM_MAX_PATH];
		menu.GetItem(position, choice, sizeof(choice));

		if(StrEqual(choice, "No")) {
			return;
		}
		else {
			if(g_iNominatePrice > Store_GetClientCredits(client)) {
				CPrintToChat(client, "%t", "Not Enough Credits", g_iNominatePrice);
				return;
			}
			
			AttemptNominate(client, choice, sizeof(choice), true);
		}
	}
	else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}

void OpenNominationMenu(int client)
{
	if(hasFreeNomination(client) || g_bPlayerNominated[client])
		SetMenuTitle(g_MapMenu, "%T", "Nominate Title", client);
	else
		SetMenuTitle(g_MapMenu, "%T\nPrice: %i credits", "Nominate Title", client, g_iNominatePrice);
	DisplayMenu(g_MapMenu, client, MENU_TIME_FOREVER);
}

BuildMapMenu()
{
	if (g_MapMenu != INVALID_HANDLE)
	{
		CloseHandle(g_MapMenu);
		g_MapMenu = INVALID_HANDLE;
	}
	
	ClearTrie(g_mapTrie);
	
	g_MapMenu = CreateMenu(MenuHandler_MapSelect, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);

	decl String:map[PLATFORM_MAX_PATH];
	
	ArrayList excludeMaps;
	decl String:currentMap[32];
	
	if (GetConVarBool(g_Cvar_ExcludeOld))
	{	
		excludeMaps = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
		GetExcludeMapList(excludeMaps);
	}
	
	if (GetConVarBool(g_Cvar_ExcludeCurrent))
	{
		GetCurrentMap(currentMap, sizeof(currentMap));
	}
	
		
	for (new i = 0; i < GetArraySize(g_MapList); i++)
	{
		new status = MAPSTATUS_ENABLED;
		
		GetArrayString(g_MapList, i, map, sizeof(map));
		
		if (GetConVarBool(g_Cvar_ExcludeCurrent))
		{
			if (StrEqual(map, currentMap))
			{
				status = MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_CURRENT;
			}
		}
		
		/* Dont bother with this check if the current map check passed */
		if (GetConVarBool(g_Cvar_ExcludeOld) && status == MAPSTATUS_ENABLED)
		{
			if (FindStringInArray(excludeMaps, map) != -1)
			{
				status = MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_PREVIOUS;
			}
		}
		
		AddMenuItem(g_MapMenu, map, map);
		SetTrieValue(g_mapTrie, map, status);
	}
	
	SetMenuExitButton(g_MapMenu, true);

	int exclude = FindConVar("mce_exclude").IntValue;
	g_PrevMapCounter.Clear();
	for(int i = 0; i < excludeMaps.Length; i++) {
		char excluded[PLATFORM_MAX_PATH];
		excludeMaps.GetString(i, excluded, sizeof(excluded));

		g_PrevMapCounter.SetValue(excluded, i + (exclude - excludeMaps.Length) + 1);
	}

	if (excludeMaps != INVALID_HANDLE)
	{
		CloseHandle(excludeMaps);
	}
}

/*
public Handler_MapSelectMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:map[PLATFORM_MAX_PATH], String:name[MAX_NAME_LENGTH];
			GetMenuItem(menu, param2, map, sizeof(map));		
			
			GetClientName(param1, name, MAX_NAME_LENGTH);
	
			new NominateResult:result = NominateMap(map, false, param1);
			
			if (result == Nominate_AlreadyInVote)
			{
				CPrintToChat(param1, "%t", "Map Already Nominated");
				return 0;
			}
			else if (result == Nominate_VoteFull)
			{
				CPrintToChat(param1, "%t", "Max Nominations");
				return 0;
			}
			
			SetTrieValue(g_mapTrie, map, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

			if (result == Nominate_Replaced)
			{
				CPrintToChatAll("%t", "Map Nomination Changed", name, map);
				return 0;	
			}
			
			CPrintToChatAll("%t", "Map Nominated", name, map);
			LogMessage("%s nominated %s", name, map);
		}
		
		case MenuAction_DrawItem:
		{
			decl String:map[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, map, sizeof(map));
			
			new status;
			
			if (!GetTrieValue(g_mapTrie, map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return ITEMDRAW_DEFAULT;
			}
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				return ITEMDRAW_DISABLED;	
			}
			
			return ITEMDRAW_DEFAULT;
						
		}
		
		case MenuAction_DisplayItem:
		{
			decl String:map[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, map, sizeof(map));
			
			new mark = GetConVarInt(g_Cvar_MarkCustomMaps);
			new bool:official;

			new status;
			
			if (!GetTrieValue(g_mapTrie, map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return 0;
			}
			
			decl String:buffer[100];
			decl String:display[150];
			
			if (mark)
			{
				official = IsMapOfficial(map);
			}
			
			if (mark && !official)
			{
				switch (mark)
				{
					case 1:
					{
						Format(buffer, sizeof(buffer), "%T", "Custom Marked", param1, map);
					}
					
					case 2:
					{
						Format(buffer, sizeof(buffer), "%T", "Custom", param1, map);
					}
				}
			}
			else
			{
				strcopy(buffer, sizeof(buffer), map);
			}
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
				{
					Format(display, sizeof(display), "%s (%T)", buffer, "Current Map", param1);
					return RedrawMenuItem(display);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
				{
					int cooldown = -1;
					if(!g_PrevMapCounter.GetValue(map, cooldown)) {
						cooldown = -1;
					}
					Format(display, sizeof(display), "%s (%T - %i left)", buffer, "Recently Played", param1, cooldown);
					return RedrawMenuItem(display);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
				{
					Format(display, sizeof(display), "%s (%T)", buffer, "Nominated", param1);
					return RedrawMenuItem(display);
				}
			}
			
			if (mark && !official)
				return RedrawMenuItem(buffer);
			
			return 0;
		}
	}
	
	return 0;
}
*/

public int MenuHandler_MapSelect(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char mapname[PLATFORM_MAX_PATH];
			// Get the map name and attempt to nominate it
			GetMenuItem(menu, param2, mapname, sizeof(mapname));
			AttemptNominate(param1, mapname, sizeof(mapname));
		}
		case MenuAction_DrawItem:
		{
			char map[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, map, sizeof(map));
			
			int status;
			if (!GetTrieValue(g_mapTrie, map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return ITEMDRAW_DEFAULT;
			}
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				return ITEMDRAW_DISABLED;	
			}

			return ITEMDRAW_DEFAULT;
		}
		case MenuAction_DisplayItem:
		{
			char mapname[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, mapname, sizeof(mapname));

			int status;
			
			if (!GetTrieValue(g_mapTrie, mapname, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return 0;
			}
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
				{
					Format(mapname, sizeof(mapname), "%s (%T)", mapname, "Current Map", param1);
					return RedrawMenuItem(mapname);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
				{
					int cooldown = -1;
					if(!g_PrevMapCounter.GetValue(mapname, cooldown)) {
						cooldown = -1;
					}
					Format(mapname, sizeof(mapname), "%s (%T - %i left)", mapname, "Recently Played", param1, cooldown);
					return RedrawMenuItem(mapname);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
				{
					Format(mapname, sizeof(mapname), "%s (%T)", mapname, "Nominated", param1);
					return RedrawMenuItem(mapname);
				}
			}
		}
		case MenuAction_End:
		{
			// This check allows the plugin to use the same callback
			// for the main menu and the match menu.
			if (menu != g_MapMenu)
			{
				delete menu;
			}
			
		}
	}
	return 0;
}

stock bool:IsNominateAllowed(client)
{
	if(g_bPlayerSwitched[client]) {
		CReplyToCommand(client, "%t", "Switch Used");
		return false;
	}

	new CanNominateResult:result = CanNominate();
	
	switch(result)
	{
		case CanNominate_No_VoteInProgress:
		{
			CReplyToCommand(client, "%t", "Nextmap Voting Started");
			return false;
		}
		
		case CanNominate_No_VoteComplete:
		{
			new String:map[PLATFORM_MAX_PATH];
			GetNextMap(map, sizeof(map));
			CReplyToCommand(client, "%t", "Next Map", map);
			return false;
		}
		
		case CanNominate_No_VoteFull:
		{
			CReplyToCommand(client, "%t", "Max Nominations");
			return false;
		}
	}
	
	return true;
}

public bool hasFreeNomination(int client) {
	//return false;
	return !g_bNominatePerk || CheckCommandAccess(client, "nominate_vip", ADMFLAG_CUSTOM5, false);
}