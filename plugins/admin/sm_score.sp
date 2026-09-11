#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <colors_csgo>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name 		= "ScoreChanger",
	author 		= "Strellic",
	description	= "Allows an admin to change team scores.",
	version 	= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/id/strellic"
};

int g_iCTScore 	= -1;
int g_iTScore 	= -1;

public void OnPluginStart() {
	RegAdminCmd("sm_score", Command_Score, ADMFLAG_BAN);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnMapStart() {
	g_iCTScore 	= -1;
	g_iTScore 	= -1;
}

public Action Command_Score(int client, int argc) {
	if(argc < 2) {
		ReplyToCommand(client, "[SM] Usage: sm_score <ct|t> <value>");
		return Plugin_Handled;
	}

	char szTarget[64];
	char szScore[8];

	GetCmdArg(1, szTarget, sizeof(szTarget));
	GetCmdArg(2, szScore, sizeof(szScore));

	int iScore = StringToInt(szScore);

	if(StrEqual(szTarget, "ct", false)) {
		g_iCTScore = iScore;
		SetTeamScore(CS_TEAM_CT, iScore);
		CPrintToChatAll("[SM] {green}%N{default} changed the score of {green}HUMANS{default} to {red}%i{default}.", client, iScore);
	}
	else if(StrEqual(szTarget, "t", false)) {
		g_iTScore = iScore;
		SetTeamScore(CS_TEAM_T, iScore);
		CPrintToChatAll("[SM] {green}%N{default} changed the score of {red}ZOMBIES{default} to {red}%i{default}.", client, iScore);
	}
	else {
		ReplyToCommand(client, "[SM] Usage: sm_score <ct|t> <value>");
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action Event_RoundStart(Handle ev, const char[] name, bool broadcast) {
	if(g_iTScore != -1 && GetTeamScore(CS_TEAM_T) < g_iTScore)
		SetTeamScore(CS_TEAM_T, g_iTScore);
	if(g_iCTScore != -1 && GetTeamScore(CS_TEAM_CT) < g_iCTScore)
		SetTeamScore(CS_TEAM_CT, g_iCTScore);
}