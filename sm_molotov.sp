#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#undef REQUIRE_EXTENSIONS
#include <zombiereloaded>
#define REQUIRE_EXTENSIONS

#pragma newdecls required
#define PLUGIN_VERSION 			"1.0"

public Plugin myinfo = {
    name = "Molotov Command",
    author = "Strellic",
    description = "Adds the !molo and !molotov commands.",
    version = PLUGIN_VERSION
};

bool g_bZREnabled = false;
int g_iGrenadePrice = 15000;
bool g_bBoughtGrenade[MAXPLAYERS+1] = {false, ...};
ConVar g_cVMolotovPrice;

public void OnPluginStart() {
	RegConsoleCmd("sm_molo", Command_GiveGrenade);
	RegConsoleCmd("sm_molotov", Command_GiveGrenade);
	RegConsoleCmd("sm_molly", Command_GiveGrenade);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	g_cVMolotovPrice = CreateConVar("sm_molotov_price", "15000", "!molotov price", _, true, 0.0);
	g_cVMolotovPrice.AddChangeHook(ConVarChange);

	AutoExecConfig(true);
	GetConVars();
}

public void Event_RoundStart(Handle ev, const char[] name, bool broadcast) {
	for(int i = 1; i <= MaxClients; i++)
		g_bBoughtGrenade[i] = false;
}

public void ConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
    GetConVars();
}
public void GetConVars() {
    g_iGrenadePrice = g_cVMolotovPrice.IntValue;
}

public void OnAllPluginsLoaded() {
    g_bZREnabled = LibraryExists("zombiereloaded");
}
public void OnLibraryRemoved(const char[] name) {
    if (StrEqual(name, "zombiereloaded")) {
        g_bZREnabled = false;
    }
}
public void OnLibraryAdded(const char[] name) {
    if (StrEqual(name, "zombiereloaded")) {
        g_bZREnabled = true;
    }
}

public int GetClientMoney(int client) {
    return GetEntProp(client, Prop_Send, "m_iAccount");
}
public void SetClientMoney(int client, int money) {
    SetEntProp(client, Prop_Send, "m_iAccount", money);
}

public Action Command_GiveGrenade(int client, int argc) {
	if(!IsPlayerAlive(client)) {
		ReplyToCommand(client, "[SM] You must be alive to use this command!");
		return Plugin_Handled;
	}
	
	if((g_bZREnabled && !ZR_IsClientHuman(client)) || (!g_bZREnabled && GetClientTeam(client) != CS_TEAM_CT)) {
		ReplyToCommand(client, "[SM] You must be a human to use this command!");
		return Plugin_Handled;
	}

	if(g_bBoughtGrenade[client]) {
		ReplyToCommand(client, "[SM] You have already bought an incendiary grenade this round!");
		return Plugin_Handled;
	}

	if(GetClientMoney(client) < g_iGrenadePrice) {
		ReplyToCommand(client, "[SM] You do not have enough money to use this command, you need $%i.", g_iGrenadePrice);
		return Plugin_Handled;
	}

	SetClientMoney(client, GetClientMoney(client) - g_iGrenadePrice);
	g_bBoughtGrenade[client] = true;
	GivePlayerItem(client, "weapon_incgrenade");
	ReplyToCommand(client, "[SM] You bought an incendiary grenade for $%i.", g_iGrenadePrice);

	return Plugin_Handled;
}