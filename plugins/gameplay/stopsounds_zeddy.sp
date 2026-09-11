#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <colors_csgo>

#pragma newdecls required

bool g_bHooked;
Handle g_hClientCookie = INVALID_HANDLE;
ConVar gcV_Volume;
float fVolume = 1.0;

#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5
#define SPECMODE_FREELOOK	 		6

enum SoundStatus {
	DEFAULT = 0,
	DISABLED = 1,
	SILENCED = 2
}

SoundStatus g_StopSound[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "Stop Weapon Sounds",
	author = "GoD-Tony",
	description = "Allows clients to modify hearing weapon sounds",
	version = "1.0",
	url = ""
};

public void OnPluginStart() {
	g_hClientCookie = RegClientCookie("stopsound_type", "Toggle hearing weapon sounds", CookieAccess_Private);
	SetCookieMenuItem(StopSoundCookieHandler, g_hClientCookie, "Stop Weapon Sounds");

	AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
	AddNormalSoundHook(Hook_NormalSound);
	
	RegConsoleCmd("sm_stopsound", Command_StopSound, "Toggle hearing weapon sounds");
	RegConsoleCmd("sm_stopsounds", Command_StopSound, "Toggle hearing weapon sounds");

	gcV_Volume = CreateConVar("sm_stopsounds_silencer_volume", "0.5", "", _, true, 0.0, true, 1.0);
	fVolume = gcV_Volume.FloatValue;
	gcV_Volume.AddChangeHook(OnConVarChange);

	for (int i = 1; i <= MaxClients; i++) {
		if (!AreClientCookiesCached(i)) {
			continue;
		}
		
		OnClientCookiesCached(i);
	}
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (convar == gcV_Volume) {
		fVolume = convar.FloatValue;
	}
}

public void OnMapStart() {
	PrecacheSound("~)weapons/usp/usp1.wav", true);
}

public void StopSoundCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen) {
	switch (action) {
		case CookieMenuAction_DisplayOption: {
		}
		
		case CookieMenuAction_SelectOption: {
			if(CheckCommandAccess(client, "sm_stopsound", 0)) {
				PrepareMenu(client);
			}
			else {
				ReplyToCommand(client, "[SM] You have no access!");
			}
		}
	}
}

void PrepareMenu(int client) {
	Menu menu = CreateMenu(YesNoMenu);
	SetMenuTitle(menu, "Stop Weapon Sounds Menu");
	AddMenuItem(menu, "0", "Disable");
	AddMenuItem(menu, "1", "Stop Sound");
	AddMenuItem(menu, "2", "Silencer Sound");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public int YesNoMenu(Handle menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_DrawItem: {
			if(g_StopSound[client] == view_as<SoundStatus>(item)) {
				return ITEMDRAW_DISABLED;
			}
		}
		case MenuAction_Select: {
			char info[50];
			if(GetMenuItem(menu, item, info, sizeof(info))) {
				SetClientCookie(client, g_hClientCookie, info);
				g_StopSound[client] = view_as<SoundStatus>(StringToInt(info));
				if(g_StopSound[client] == SILENCED) {
					CReplyToCommand(client, "\x04[StopSound]\x01 Stop weapon sounds:\x04 Silenced Sounds\x01.");
				}
				else if (g_StopSound[client] == DISABLED) {
					CReplyToCommand(client, "\x04[StopSound]\x01 Stop weapon sounds: \x04%s\x01.", "Disabled");
				}
				else {
					CReplyToCommand(client, "\x04[StopSound]\x01 Stop weapon sounds: \x04%s\x01.", "Enabled");
				}
				CheckHooks();
				PrepareMenu(client);
			}
		}
		case MenuAction_Cancel: {
			if( item == MenuCancel_ExitBack ) {
				ShowCookieMenu(client);
			}
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}

	return 0;
}

public void OnClientCookiesCached(int client) {
	char sValue[8];
	GetClientCookie(client, g_hClientCookie, sValue, sizeof(sValue));

	if (strlen(sValue) == 0)
		g_StopSound[client] = SILENCED;
	else
		g_StopSound[client] = view_as<SoundStatus>(StringToInt(sValue));

	CheckHooks();
}

public Action Command_StopSound(int client, int argc) {
	if(AreClientCookiesCached(client)) {
		PrepareMenu(client);
	}
	else {
		ReplyToCommand(client, "[SM] Error: Cookies not cached yet.");
	}
	
	return Plugin_Handled;
}

public void OnClientDisconnect_Post(int client) {
	g_StopSound[client] = DEFAULT;
	CheckHooks();
}

void CheckHooks() {
	bool bShouldHook = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_StopSound[i] != DEFAULT) {
			bShouldHook = true;
			break;
		}
	}
	
	g_bHooked = bShouldHook;
}

stock bool IsValidClient(int client, bool nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
} 

public Action Hook_NormalSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags) {
	if (!g_bHooked || StrEqual(sample, "~)weapons/usp/usp1.wav", false) || !(strncmp(sample, "weapons", 7, false) == 0 || strncmp(sample[1], "weapons", 7, false) == 0 || strncmp(sample[2], "weapons", 7, false) == 0))
	return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"); 
	
	bool bSpecList[MAXPLAYERS+1] = {false, ...};
	if(IsValidClient(owner)) {
		bSpecList[owner] = true;
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || !IsClientObserver(i))
				continue;

			int iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
				continue;

			int iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			if(iTarget == owner)
				bSpecList[i] = true;
		}
	}

	for (int i = 0; i < numClients; i++)
	{
		if (g_StopSound[clients[i]] != DEFAULT && !bSpecList[clients[i]])
		{
			// Remove the client from the array.
			for (int j = i; j < numClients-1; j++)
			{
				clients[j] = clients[j+1];
			}
			
			numClients--;
			i--;
		}
	}
	
	return (numClients > 0) ? Plugin_Changed : Plugin_Stop;
}

public Action CSS_Hook_ShotgunShot(const char[] te_name, const int[] Players, int numClients, float delay) {
	if (!g_bHooked)
		return Plugin_Continue;

	// Check which clients need to be excluded.
	int defaultList[MAXPLAYERS+1], defaultCount;

	int silenceList[MAXPLAYERS+1];
	int silenceCount = 0;

	for (int i = 0; i < numClients; i++) {
		int client = Players[i];
		
		if (g_StopSound[client] == DEFAULT) {
			defaultList[defaultCount++] = client;
		}
		if(g_StopSound[client] == SILENCED) {
			silenceList[silenceCount++] = client;
		}
	}
	
	// No clients were excluded.
	if (defaultCount == numClients)
		return Plugin_Continue;

	int player = TE_ReadNum("m_iPlayer");
	int entity = player + 1;
	for (int j = 0; j < silenceCount; j++) {
		if (entity == silenceList[j]) {
			for (int k = j; k < silenceCount-1; k++) {
				silenceList[k] = silenceList[k+1];
			}
			
			silenceCount--;
			j--;
		}
	}
	EmitSound(silenceList, silenceCount, "~)weapons/usp/usp1.wav", entity, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, fVolume);
	
	// All clients were excluded and there is no need to broadcast.
	if (defaultCount == 0)
		return Plugin_Stop;
	
	// Re-broadcast to clients that still need it.
	float vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_weapon", TE_ReadNum("m_weapon"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", player);
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(defaultList, defaultCount, delay);
	
	return Plugin_Stop;
}