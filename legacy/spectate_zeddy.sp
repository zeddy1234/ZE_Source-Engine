#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zombiereloaded>
#include <csgocolors_fix>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name		= "Spectate",
	description	= "Adds a command to !spectate specific players.",
	author		= "Strellic EDIT by Detroid",
	version		= PLUGIN_VERSION,
	url			= ""
}

ConVar g_cvSpecAllowTimer;
bool g_bAllowGlobalSpec = true;
bool g_bAllowSpec[MAXPLAYERS+1] = {true, ...};

public void OnPluginStart()
{
	CreateConVar("sm_spectate_version", PLUGIN_VERSION, "Spectate Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_spectate", Command_Spectate, "Spectate a player.");
	RegConsoleCmd("sm_spec", Command_Spectate, "Spectate a player.");

	RegAdminCmd("sm_togglespec", Command_ToggleSpec, ADMFLAG_KICK);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	g_cvSpecAllowTimer = CreateConVar("sm_spec_allow_timer", "120", "Delay in sec after mother infection to reallow !spec for motherzombie", _, true, 0.0);

	AddCommandListener(Command_JoinTeam, "jointeam");

	AutoExecConfig(true);

	for(int i = 1; i <= MaxClients; i++) {
		g_bAllowSpec[i] = true;
    }
}

public void OnMapStart() {
	g_bAllowGlobalSpec = true;
}

stock bool IsValidClient(int client) {
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return false;
    return true;
}

public bool IsPlayerAdmin(int client) {
    return CheckCommandAccess(client, "adm_priv", ADMFLAG_KICK, false) || CheckCommandAccess(client, "adm_priv", ADMFLAG_KICK, false);;
}

public void Event_RoundStart(Handle ev, const char[] name, bool broadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		g_bAllowSpec[i] = true;
		if(IsValidClient(i) && GetClientTeam(i) == CS_TEAM_SPECTATOR && !g_bAllowGlobalSpec && !IsPlayerAdmin(i)) {
			ChangeClientTeam(i, CS_TEAM_CT);
        }
    }
}

public Action Command_Spectate(int client, int argc)
{
	if (!client) {
		PrintToServer("[SM] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if(!g_bAllowGlobalSpec && !IsPlayerAdmin(i)) {
		CPrintToChat(client, "[SM] Spectating is {red}disabled{default} for {green}Normal Players{default}.");
		return Plugin_Handled;
	}

	if(!g_bAllowSpec[client]) {
		CPrintToChat(client, "[SM] You can't go to spectate for {green}2 minutes{default} after becoming {red}Mother Zombie{default}!");
		return Plugin_Handled;
	}

	if (!argc)
	{
		if (GetClientTeam(client) != CS_TEAM_SPECTATOR)
		{
			ForcePlayerSuicide(client);
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		}

		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArg(1, sTarget, sizeof(sTarget));

	int iTarget;
	if ((iTarget = FindTarget(client, sTarget, false, false)) <= 0)
		return Plugin_Handled;

	if (!IsPlayerAlive(iTarget))
	{
		ReplyToCommand(client, "[SM] %t", "Target must be alive");
		return Plugin_Handled;
	}

	if (GetClientTeam(client) != CS_TEAM_SPECTATOR)
	{
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	}

	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", iTarget);

	PrintToChat(client, "{default}[SM] Spectating {orange}%N{default}.", iTarget);

	return Plugin_Handled;
}

public Action Command_JoinTeam(int client, const char[] command, int argc) 
{ 
	if (!client)
	{
		return Plugin_Continue;
	}
	
	char szTeam[4]; 
	GetCmdArgString(szTeam, sizeof(szTeam)); 
	int iTeam = StringToInt(szTeam); 

	if(iTeam == CS_TEAM_SPECTATOR) {
		if(!g_bAllowGlobalSpec && !IsPlayerAdmin(i)) {
			CPrintToChat(client, "[SM] Spectating is {red}disabled{default} for {green}Normal Players{default}.");
			return Plugin_Handled;
		}


		if(!g_bAllowSpec[client]) {
			CPrintToChat(client, "[SM] You can't go to spectate for {green}2 minutes{default} after becoming {red}Mother Zombie{default}!");
			return Plugin_Handled;
		}

		ChangeClientTeam(client, CS_TEAM_SPECTATOR); 
	}
	
	return Plugin_Continue; 
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn) {
	if(motherInfect) {
		g_bAllowSpec[client] = false;
		CreateTimer(g_cvSpecAllowTimer.FloatValue, AllowSpec, GetClientSerial(client));
	}
}

public void OnClientDisconnect(int client) {
	g_bAllowSpec[client] = true;
}

public Action AllowSpec(Handle timer, int serial) {
	int client = GetClientFromSerial(serial);
	if(client != 0) {
		g_bAllowSpec[client] = true;
	}
}

public Action Command_ToggleSpec(int client, int argc) {
	g_bAllowGlobalSpec = !g_bAllowGlobalSpec;
	ReplyToCommand(client, "[SM] You have %s spectate for {green}Normal Players{default}.", g_bAllowGlobalSpec ? "{green}enabled" : "{red}disabled");
}
