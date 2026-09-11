/*  SM FPVMI - Custom Weapons Menu
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <fpvm_interface>
#include <multicolors>

#pragma newdecls required

#define DATA "3.2"

Handle kv, db, g_szaWeapons;

Handle g_cVSpawnMSG = INVALID_HANDLE;

char g_szClientWeapon[MAXPLAYERS+1];
int g_iClientId[MAXPLAYERS+1];

Handle Menu_CW;

char szSQLBuffer[3096];

bool g_bIsMySQL;

StringMap smWeaponSounds[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "SM FPVMI - Custom Weapons Menu",
	author = "Franc1sco franug / Romeo / Strellic",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
}
	
public void OnPluginStart() {
	CreateConVar("sm_customweaponsmenu_version", DATA, "plugin info", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cVSpawnMSG = CreateConVar("sm_customweaponsmenu_spawnmsg", "0", "Enable or Disable Spawnmessages");
	
	RegConsoleCmd("sm_cw", Command_CW);
	RegAdminCmd("sm_reloadcw", Command_ReloadSkins, ADMFLAG_ROOT);
	
	LoadTranslations("franug_cwm.phrases");
	LoadTranslations("common.phrases");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	
	RefreshKV();
	CheckDB(true);

	AddTempEntHook("Shotgun Shot", EntHook_PlayerShoot);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i))
			OnClientConnected(i);
	}
}

public void OnMapStart() {
	SetupDownloads();
}

public void OnClientConnected(int client) {
	smWeaponSounds[client] = CreateTrie();
}

stock bool IsValidClient(int client, bool nobots = true) { 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client))) {
        return false; 
    }
    return IsClientInGame(client); 
} 

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i))
			CheckSteamID(i);
	}
}

public Action Command_ReloadSkins(int client, int args) {	
	RefreshKV();
	CheckDB(true);
	CReplyToCommand(client, "\x04[CW]\x01 %T","Custom Weapons Menu configuration reloaded", client);
	
	return Plugin_Handled;
}

void CheckDB(bool reconnect = false, char dbName[64] = "customweapons")
{
	if(reconnect) {
		if(db != INVALID_HANDLE) {
			//LogMessage("Reconnecting DB connection");
			CloseHandle(db);
			db = INVALID_HANDLE;
		}
	}
	else if(db != INVALID_HANDLE) {
		return;
	}

	if(!SQL_CheckConfig(dbName)) {
		if(StrEqual(dbName, "storage-local"))
			SetFailState("Databases not found");
		else {
			CheckDB(true, "storage-local");
		}
		
		return;
	}
	SQL_TConnect(SQL_OnConnect, dbName);
}

public void SQL_OnConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) {
		LogError("Database failure: %s", error);
		SetFailState("Databases dont work");
	}
	else {
		db = hndl;
		
		SQL_GetDriverIdent(SQL_ReadDriver(db), szSQLBuffer, sizeof(szSQLBuffer));
		g_bIsMySQL = StrEqual(szSQLBuffer,"mysql", false) ? true : false;
	
		if(g_bIsMySQL) {
			Format(szSQLBuffer, sizeof(szSQLBuffer), "CREATE TABLE IF NOT EXISTS `customweapons` (`playername` varchar(128) NOT NULL, `steamid` varchar(32) NOT NULL,`last_accountuse` int(64) NOT NULL, `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY)");

			SQL_TQuery(db, SQL_FetchDB, szSQLBuffer);

		}
		else {
			Format(szSQLBuffer, sizeof(szSQLBuffer), "CREATE TABLE IF NOT EXISTS customweapons (playername varchar(128) NOT NULL, steamid varchar(32) NOT NULL,last_accountuse int(64) NOT NULL, id INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL)");
		
			SQL_TQuery(db, SQL_FetchDB, szSQLBuffer);
		}
	}
}

// Show Spawn Message
public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	// Get Client
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) == 1 && !IsPlayerAlive(client)) {
		return;
	}
	
	smWeaponSounds[client].Clear();

	// Check Convar & Spawnmsg
	if(GetConVarInt(g_cVSpawnMSG) == 1) {	
		CPrintToChat(client," \x04[CW]\x01 %T","spawnmsg", client);
	}
}

public void RefreshKV() {
	char szConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szConfig, PLATFORM_MAX_PATH, "configs/franug_cwm/configuration.txt");
	
	if(kv != INVALID_HANDLE)
		CloseHandle(kv);
	
	kv = CreateKeyValues("CustomModels");
	FileToKeyValues(kv, szConfig);
}

void SetupDownloads() {
	char imFile[PLATFORM_MAX_PATH];
	char line[192];
	
	BuildPath(Path_SM, imFile, sizeof(imFile), "configs/franug_cwm/downloads.txt");
	
	Handle file = OpenFile(imFile, "r");
	
	if(file != INVALID_HANDLE) {
		while (!IsEndOfFile(file)) {
			if(!ReadFileLine(file, line, sizeof(line))) {
				break;
			}
			
			TrimString(line);
			if(strlen(line) > 0 && FileExists(line)) {
				AddFileToDownloadsTable(line);
			}
		}

		CloseHandle(file);
	}
	else {
		LogError("[SM] no file found for downloads (configs/franug_cwm/downloads.txt)");
	}
}

public Action Command_CW(int client, int args) {	
	SetMenuTitle(Menu_CW, "Custom Weapons Menu v%s\n%T", DATA,"Select a weapon", client);
	DisplayMenu(Menu_CW, client, 0);
	return Plugin_Handled;
}

public int Menu_WeaponSelect_Handler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			Format(g_szClientWeapon[client], 64, "weapon_%s", item);
			
			KvJumpToKey(kv, g_szClientWeapon[client]);
			
			char szTemp[64];
			Menu weaponMenu = new Menu(Menu_SkinSelect_Handler);
			SetMenuTitle(weaponMenu, "%T", "Select a custom view model", client);
			AddMenuItem(weaponMenu, "default", "Default model");
			if(KvGotoFirstSubKey(kv)) {
				do {
					KvGetSectionName(kv, szTemp, 64);
					AddMenuItem(weaponMenu, szTemp, szTemp);
			
				} while (KvGotoNextKey(kv));
			}
			KvRewind(kv);
			SetMenuExitBackButton(weaponMenu, true);
			DisplayMenu(weaponMenu, client, 0);
		}
	}
}

public int Menu_SkinSelect_Handler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if(StrEqual(item, "default")) {
				CPrintToChat(client, " \x04[CW]\x01 %T","Now you have the default weapon model", client);
				Format(szSQLBuffer, sizeof(szSQLBuffer), "UPDATE %s SET saved = 'default' WHERE id = '%i';", g_szClientWeapon[client],g_iClientId[client]);
				SQL_TQuery(db, SQL_EmptyCallback, szSQLBuffer);
				Command_CW(client, 0);
				
				return;
			}
			KvJumpToKey(kv, g_szClientWeapon[client]);
			KvJumpToKey(kv, item);
			
			char cwmodel[PLATFORM_MAX_PATH], cwmodel2[PLATFORM_MAX_PATH], cwmodel3[PLATFORM_MAX_PATH];
			KvGetString(kv, "model", cwmodel, PLATFORM_MAX_PATH, "none");
			KvGetString(kv, "worldmodel", cwmodel2, PLATFORM_MAX_PATH, "none");
			KvGetString(kv, "dropmodel", cwmodel3, PLATFORM_MAX_PATH, "none");
			if(StrEqual(cwmodel, "none") && StrEqual(cwmodel2, "none") && StrEqual(cwmodel3, "none")) {
				CPrintToChat(client, " \x04[CW]\x01 %T","Invalid configuration for this model", client);
			}
			else {
				char flag[8];
				KvGetString(kv, "flag", flag, 8, "");
				if(HasPermission(client, flag)) {
					CPrintToChat(client, " \x04[CW]\x01 %T","Now you have a custom weapon model in",client, g_szClientWeapon[client]);
					
					Format(szSQLBuffer, sizeof(szSQLBuffer), "UPDATE %s SET saved = '%s' WHERE id = '%i';", g_szClientWeapon[client],item,g_iClientId[client]);
					SQL_TQuery(db, SQL_EmptyCallback, szSQLBuffer);
				}
				else {
					CPrintToChat(client, " \x04[CW]\x01 %T","You dont have access to use this weapon model", client);
				}
				Command_CW(client, 0);
			}
			KvRewind(kv);
		}
		case MenuAction_Cancel: {
			if(param2==MenuCancel_ExitBack) {
				Command_CW(client, 0);
			}
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

stock bool HasPermission(int iClient, char[] flagString)  {
	if(StrEqual(flagString, ""))  {
		return true;
	}
	
	AdminId admin = GetUserAdmin(iClient);
	
	if(admin != INVALID_ADMIN_ID) {
		int count, found, flags = ReadFlagString(flagString);
		for (int i = 0; i <= 20; i++) {
			if(flags & (1<<i)) {
				count++;
				
				if(GetAdminFlag(admin, view_as<AdminFlag>(i)))
					found++;
			}
		}

		if(count == found) {
			return true;
		}
	}

	return false;
} 

public void OnClientPostAdminCheck(int client) {
	g_iClientId[client] = 0;
	
	if(!IsFakeClient(client)) {
		CheckSteamID(client);
		SDKHook(client, SDKHook_WeaponEquipPost, Hook_OnWeaponEquip);
	}
}

public void OnClientDisconnect(int client) {
	if(!IsFakeClient(client)) 
		SaveCookies(client);
	
	g_iClientId[client] = 0;

	if(smWeaponSounds[client] != INVALID_HANDLE)
		CloseHandle(smWeaponSounds[client]);
}

void CheckSteamID(int client) {
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	Format(query, sizeof(query), "SELECT id FROM customweapons WHERE steamid = '%s'", steamid);
	SQL_TQuery(db, SQL_CheckSteamID, query, GetClientUserId(client));
}

public void SQL_CheckSteamID(Handle owner, Handle hndl, const char[] error, any data) {
	int client;
 
	if((client = GetClientOfUserId(data)) == 0) {
		return;
	}

	if(hndl == INVALID_HANDLE) {
		LogError("Query failure: %s", error);
		return;
	}

	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl))  {
		SQL_InsertUser(client);
		return;
	}
	
	g_iClientId[client] = SQL_FetchInt(hndl, 0);
	
	char items[64];
	for(int i = 0; i < GetArraySize(g_szaWeapons); i++) {
		GetArrayString(g_szaWeapons, i, items, 64);
		Format(szSQLBuffer, sizeof(szSQLBuffer), "SELECT saved FROM %s WHERE id = '%i'", items, g_iClientId[client]);
		SQL_TQuery(db, SQL_LoadUser, szSQLBuffer, (GetClientUserId(client)*10000)+i);
	}
}

void SQL_InsertUser(int client) {
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	int userid = GetClientUserId(client);
	
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
	{
		Format(SafeName, sizeof(SafeName), "<noname>");
	}
	else
	{
		TrimString(Name);
		SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
	}
		
	Format(query, sizeof(query), "INSERT INTO customweapons(playername, steamid, last_accountuse) VALUES('%s', '%s', '%d');", SafeName, steamid, GetTime());
	SQL_TQuery(db, SQL_AfterInsert, query, userid);
}

public void SQL_AfterInsert(Handle owner, Handle hndl, const char [] error, any data) {
	if(hndl == INVALID_HANDLE) {
		LogError("Query failure: %s", error);
		return;
	}
	int client;
 
	if((client = GetClientOfUserId(data)) == 0) {
		return;
	}
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	
	Format(szSQLBuffer, sizeof(szSQLBuffer), "SELECT id FROM customweapons WHERE steamid = '%s';", steamid);
	SQL_TQuery(db, SQL_RefreshUser, szSQLBuffer, GetClientUserId(client));
}

public void SQL_FetchDB(Handle owner, Handle hndl, const char[] error, any data) {
	if(hndl == INVALID_HANDLE) {
		LogError("Query failure: %s", error);
		return;
	}
	
	if(g_szaWeapons != INVALID_HANDLE) 
		CloseHandle(g_szaWeapons);
	g_szaWeapons = CreateArray(64);
	
	char temp[64];
	Menu_CW = new Menu(Menu_WeaponSelect_Handler);
	
	if(KvGotoFirstSubKey(kv)) {
		do {
			KvGetSectionName(kv, temp, 64);
			
			if (g_bIsMySQL) Format(szSQLBuffer, sizeof(szSQLBuffer), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11),`saved` varchar(128),PRIMARY KEY  (`id`))", temp);
			else Format(szSQLBuffer, sizeof(szSQLBuffer), "CREATE TABLE IF NOT EXISTS %s (id int(11),saved varchar(128),PRIMARY KEY  (id))", temp);
			SQL_TQuery(db, SQL_EmptyCallback, szSQLBuffer);
			PushArrayString(g_szaWeapons, temp);
			ReplaceString(temp, 64, "weapon_", "");
			AddMenuItem(Menu_CW, temp, temp);
			
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	for(int client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client)) {
			OnClientPostAdminCheck(client);
		}
	}
}

public void SQL_EmptyCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if(hndl == INVALID_HANDLE) {
		LogError("Query failure: %s", error);
	}
}

public void SQL_RefreshUser(Handle owner, Handle hndl, const char[] error, any data) {
	if(hndl == INVALID_HANDLE) {
		LogError("Query failure: %s", error);
		return;
	}
	int client;
 
	if((client = GetClientOfUserId(data)) == 0) {
		return;
	}
	
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) {
		return;
	}
	char items[64];
	g_iClientId[client] = SQL_FetchInt(hndl, 0);

	for(int i = 0; i < GetArraySize(g_szaWeapons); i++) {
		GetArrayString(g_szaWeapons, i, items, 64);
		Format(szSQLBuffer, sizeof(szSQLBuffer), "INSERT INTO %s(id, saved) VALUES('%i', 'default');", items,g_iClientId[client]);
		SQL_TQuery(db, SQL_EmptyCallback, szSQLBuffer);
	}
}

public void SQL_LoadUser(Handle owner, Handle hndl, const char[] error, any data) {
	if(hndl == INVALID_HANDLE) {
		LogError("Query failure: %s", error);
		return;
	}
	
	int userid = data/10000;
	int weapon = (data-(userid*10000));
	int client = GetClientOfUserId(userid);

	if(client == 0 || !IsValidClient(client)) {
		return;
	}
	
	char items[64], item[64];
	GetArrayString(g_szaWeapons, weapon, items, 64);
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl))  {
		
		Format(szSQLBuffer, sizeof(szSQLBuffer), "INSERT INTO %s(id, saved) VALUES('%i', 'default');", items,g_iClientId[client]);
		SQL_TQuery(db, SQL_EmptyCallback, szSQLBuffer);
		return;
	}
	
	SQL_FetchString(hndl, 0, item, sizeof(item));
	KvJumpToKey(kv, items);
	KvJumpToKey(kv, item);
	char cwmodel[PLATFORM_MAX_PATH], cwmodel2[PLATFORM_MAX_PATH], cwmodel3[PLATFORM_MAX_PATH];
	KvGetString(kv, "model", cwmodel, PLATFORM_MAX_PATH, "none");
	KvGetString(kv, "worldmodel", cwmodel2, PLATFORM_MAX_PATH, "none");
	KvGetString(kv, "dropmodel", cwmodel3, PLATFORM_MAX_PATH, "none");
	
	char flag[8];
	KvGetString(kv, "flag", flag, 8, "");
	
	if(HasPermission(client, flag))
		FPVMI_SetClientModel(client, items, !StrEqual(cwmodel, "none")?PrecacheModel(cwmodel):-1, !StrEqual(cwmodel2, "none")?PrecacheModel(cwmodel2):-1, cwmodel3);
	
	KvRewind(kv);
}

void SaveCookies(int client) {
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name))) {
		Format(SafeName, sizeof(SafeName), "<noname>");
	}
	else {
		TrimString(Name);
		SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
	}	

	char buffer[3096];
	Format(buffer, sizeof(buffer), "UPDATE customweapons SET last_accountuse = %d, playername = '%s' WHERE steamid = '%s';",GetTime(), SafeName,steamid);
	SQL_TQuery(db, SQL_EmptyCallback, buffer);
}

public Action EntHook_PlayerShoot(const char[] sTEName, const int[] iPlayers, int numClients, float flDelay) { 
	int client = TE_ReadNum("m_iPlayer") + 1;
	
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	int weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if(!IsValidEdict(weaponIndex)) {
		return Plugin_Continue;
	}

	char szWeaponClass[64];
	GetEntityClassname(weaponIndex, szWeaponClass, sizeof(szWeaponClass));

	char szWeaponSound[PLATFORM_MAX_PATH];
	smWeaponSounds[client].GetString(szWeaponClass, szWeaponSound, sizeof(szWeaponSound));
	if(!StrEqual(szWeaponSound, "none") && strlen(szWeaponSound) > 0) {
		EmitSoundToAll(szWeaponSound, weaponIndex, SNDCHAN_WEAPON, SNDLEVEL_NORMAL);
	}
	
	return Plugin_Continue;
}

public Action Hook_OnWeaponEquip(int client, int weaponIndex) {
	char classname[32];
	GetEntityClassname(weaponIndex, classname, sizeof(classname));
	
	smWeaponSounds[client].SetString(classname, "none");

	Format(szSQLBuffer, sizeof(szSQLBuffer), "SELECT saved FROM %s WHERE id = '%i'", classname, g_iClientId[client]);

	DataPack pack = CreateDataPack();
	pack.WriteCell((GetClientUserId(client)*10000));
	pack.WriteCell(weaponIndex);

	SQL_TQuery(db, SQL_FetchWeaponModelForSound, szSQLBuffer, pack);
}

public void SQL_FetchWeaponModelForSound(Handle owner, Handle hndl, const char[] error, DataPack pack) {
	pack.Reset();

	if(hndl == INVALID_HANDLE) {
		CloseHandle(pack);
		return;
	}
	
	int userid = pack.ReadCell()/10000;
	int client = GetClientOfUserId(userid);
	
	int weaponIndex = pack.ReadCell();

	if(client == 0 || !IsValidClient(client)) {
		CloseHandle(pack);
		return;
	}
	
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) {
		CloseHandle(pack);
		return;
	}
	
	char szWeaponModel[PLATFORM_MAX_PATH];
	SQL_FetchString(hndl, 0, szWeaponModel, sizeof(szWeaponModel));

	CloseHandle(pack);

	DataPack timerPack = CreateDataPack();
	CreateDataTimer(0.1, Timer_GetSound, timerPack);
	timerPack.WriteCell(client);
	timerPack.WriteCell(weaponIndex);
	timerPack.WriteString(szWeaponModel);
}

public Action Timer_GetSound(Handle timer, DataPack pack) {
	ResetPack(pack);
	
	int client = pack.ReadCell();
	int weaponIndex = pack.ReadCell();

	char szWeaponModel[PLATFORM_MAX_PATH];
	pack.ReadString(szWeaponModel, sizeof(szWeaponModel));
	
	if(!IsValidEdict(weaponIndex)) {
		return;
	}
	
	char flag[8];
	char sWeaponSound[PLATFORM_MAX_PATH];
	char classname[32];
	GetEntityClassname(weaponIndex, classname, sizeof(classname));

	KvJumpToKey(kv, classname);
	KvJumpToKey(kv, szWeaponModel);
	KvGetString(kv, "sound", sWeaponSound, PLATFORM_MAX_PATH, "none");
	KvGetString(kv, "flag", flag, 8, "");
	
	if(HasPermission(client, flag) && !StrEqual(szWeaponModel, "default") && !StrEqual(sWeaponSound, "none")) {
		ReplaceStringEx(sWeaponSound, PLATFORM_MAX_PATH, "sound/", "", -1, -1, false);
		Format(sWeaponSound, sizeof(sWeaponSound), "*%s", sWeaponSound);
		AddToStringTable(FindStringTable("soundprecache"), sWeaponSound);

		smWeaponSounds[client].SetString(classname, sWeaponSound);
	}
	
	KvRewind(kv);
}