#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors_csgo>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "SayColor",
	author = "Strellic",
	description = "",
	version = "1.0",
	url = "https://strellic.dev/"
}

public void OnPluginStart()
{
	AddCommandListener(FilterChat, "say");
}


public Action FilterChat(int client, const char[] command, int args)
{
	if (!client) 
	{
		char text[192];
		GetCmdArgString(text, sizeof(text));
		CPrintToChatAll("{green}+++ {red}%s{green} +++", text);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}