/*
 * ============================================================================
 *
 *  Zombie:Reloaded
 *
 *  File:		  zombiesounds.inc
 *  Type:		  Core 
 *  Description:   Zombie sound effects.
 *
 *  Copyright (C) 2009-2013  Greyscale, Richard Helgeby
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

/**
 * @section Defines for min/max moaning sound file index.
 */
#define SOUND_MOAN_PATH "npc/zombie/zombie_voice_idle%d.wav" // %d is sound file index
#define SOUND_MOAN_PATH_CSGO "zr/zombie_voice_idle%d.mp3" // %d is sound file index
#define SOUND_MOAN_MIN 1
#define SOUND_MOAN_MAX 14
/**
 * @endsection
 */

/**
 * @section Defines for min/max groan sound file index.
 */
#define SOUND_GROAN_PATH "npc/zombie/zombie_pain%d.wav" // %d is sound file index
#define SOUND_GROAN_PATH_CSGO "zr/zombie_pain%d.mp3" // %d is sound file index
#define SOUND_GROAN_MIN 1
#define SOUND_GROAN_MAX 6
/**
 * @endsection
 */

/**
 * @section Defines for min/max death sound file index.
 */
#define SOUND_DEATH_PATH "npc/zombie/zombie_die%d.wav" // %d is sound file index
#define SOUND_DEATH_PATH_CSGO "zr/zombie_die%d.mp3" // %d is sound file index
#define SOUND_DEATH_MIN 1
#define SOUND_DEATH_MAX 3
/**
 * @endsection
 */

/**
 * Zombie sound types
 */
enum ZombieSounds
{
	Moan, /** Zombie's moan periodically */
	Groan, /** When zombie is hurt */
	Death, /** When a zombie is killed */
}
 
/**
 * Array for storing zombie moaning timer handles per client.
 */
new Handle:tSEffectsMoan[MAXPLAYERS + 1];

/**
 * Number of sound commands executed by the player.
 */
new g_SEffectsCommandCount[MAXPLAYERS + 1];

/**
 * Timers for resetting sound command counters.
 */
new Handle:g_hSEffectsCommandTimer[MAXPLAYERS + 1];

/**
 * Client is joining the server.
 * 
 * @param client	The client index.
 */
ZombieSoundsClientInit(client)
{
	// Reset timer handle.
	tSEffectsMoan[client] = INVALID_HANDLE;
	
	// Reset command counter and make sure there's no timer running.
	g_SEffectsCommandCount[client] = 0;
	ZREndTimer(g_hSEffectsCommandTimer[client]);

	UpdateClientZVol(client);
}

/**
 * Client is spawning into the game.
 * 
 * @param client	The client index.
 */
ZombieSoundsOnClientSpawn(client)
{
	// If timer is running, kill it.
	if (tSEffectsMoan[client] != INVALID_HANDLE)
	{
		KillTimer(tSEffectsMoan[client]);
	}
	
	// Reset timer handle.
	tSEffectsMoan[client] = INVALID_HANDLE;
	
	// Reset command counter and kill timer.
	g_SEffectsCommandCount[client] = 0;
	ZREndTimer(g_hSEffectsCommandTimer[client]);

	UpdateClientZVol(client);
}

/**
 * Client has been killed.
 * 
 * @param client	The client index.
 */
ZombieSoundsOnClientDeath(client)
{
	// If timer is running, kill it.
	if (tSEffectsMoan[client] != INVALID_HANDLE)
	{
		KillTimer(tSEffectsMoan[client]);
	}
	
	// Reset timer handle.
	tSEffectsMoan[client] = INVALID_HANDLE;
	
	// Reset command counter and kill timer.
	g_SEffectsCommandCount[client] = 0;
	ZREndTimer(g_hSEffectsCommandTimer[client]);
	
	// If player isn't a zombie, then stop.
	if (!InfectIsClientInfected(client))
	{
		return;
	}
	
	// If death sound cvar is disabled, then stop.
	new bool:death = GetConVarBool(g_hCvarsList[CVAR_SEFFECTS_DEATH]);
	if (!death)
	{
		return;
	}
	
	// Get random death sound.
	decl String:sound[SOUND_MAX_PATH];
	ZombieSoundsGetRandomSound(sound, Death);
	
	SEffectsEmitSoundFromClientWithZVol(client, sound);
}

/**
 * Client has been hurt.
 * 
 * @param client	The client index.
 */
ZombieSoundsOnClientHurt(client)
{
	// If player isn't a zombie, then stop.
	if (!InfectIsClientInfected(client))
	{
		return;
	}
	
	// Get groan factor, if 0, then stop.
	new groan = GetConVarInt(g_hCvarsList[CVAR_SEFFECTS_GROAN]);
	if (!groan)
	{
		return;
	}
	
	// 1 in 'groan' chance of groaning.
	if (GetRandomInt(1, groan) == 1)
	{
		// Get random groan sound.
		decl String:sound[SOUND_MAX_PATH];
		ZombieSoundsGetRandomSound(sound, Groan);
		
		SEffectsEmitSoundFromClientWithZVol(client, sound);
	}
}

/**
 * Client has been infected.
 * 
 * @param client	The client index.
 */
ZombieSoundsOnClientInfected(client)
{
	// If interval is set to 0, then stop.
	new Float:interval = GetConVarFloat(g_hCvarsList[CVAR_SEFFECTS_MOAN]);
	if (!interval)
	{
		return;
	}
	
	// If timer is currently running, kill it.
	if (tSEffectsMoan[client] != INVALID_HANDLE)
	{
		KillTimer(tSEffectsMoan[client]);
	}
	
	// Start repeating timer.
	tSEffectsMoan[client] = CreateTimer(interval, ZombieSoundsMoanTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

/**
 * Round ended.
 */
ZombieSoundsOnRoundEnd()
{
	ZombieSoundsResetCmdCounters();
	ZombieSoundsResetCmdTimers();
}

ZombieSoundsOnMapEnd()
{
	ZombieSoundsOnRoundEnd();
}

Handle gH_ZVolume;

ZombieSoundsOnCommandsCreate()
{
	RegConsoleCmd("scream", ZombieSoundsScreamCommand, "Emits a scream sound, if the player is a zombie.");
	RegConsoleCmd("moan", ZombieSoundsMoanCommand, "Emits a moan sound, if the player is a zombie.");

	RegConsoleCmd("sm_zvol", Command_ZVol, "Menu for client to change Zombie SFX volume.");

	gH_ZVolume = RegClientCookie("zr_zvol_cookie", "Float for a client's Zombie SFX volume.", CookieAccess_Private);
}

float g_fZVolume[MAXPLAYERS + 1] = {-1.0, ...};

public Action Command_ZVol(int client, int args) {
	Handle menu = CreateMenu(ZVolMenuHandler);

	char cookie[8];
	GetClientCookie(client, gH_ZVolume, cookie, sizeof(cookie));
	float current = StringToFloat(cookie);

	char currentFormat[64];

	if(strlen(cookie) != 0) {
		switch (current) {
		    case 1.0: {
		        Format(currentFormat, sizeof(currentFormat), "Current: 100%%");
		    }
		    case 0.6: {
		        Format(currentFormat, sizeof(currentFormat), "Current: 75%%");
		    }
		    case 0.3: {
		        Format(currentFormat, sizeof(currentFormat), "Current: 50%%");
		    }
		    case 0.1: {
		        Format(currentFormat, sizeof(currentFormat), "Current: 25%%");
		    }
		    case 0.0: {
		        Format(currentFormat, sizeof(currentFormat), "Current: 0%%");
		    }
		}
	}
	else {
		Format(currentFormat, sizeof(currentFormat), "Current: 100%%");
	}

	SetMenuTitle(menu, "Zombie Volume Menu\n%s", currentFormat);
	AddMenuItem(menu, "1.0", "100% Volume");
	AddMenuItem(menu, "0.6",  "75% Volume");
	AddMenuItem(menu, "0.3",  "50% Volume");
	AddMenuItem(menu, "0.1",  "25% Volume");
	AddMenuItem(menu, "0.0",  "Disabled");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int ZVolMenuHandler(Handle menu, MenuAction action, int client, int position) {
	if(action == MenuAction_Select) {
		char info[32], display[32];
		GetMenuItem(menu, position, info, sizeof(info), _, display, sizeof(display));
		SetClientCookie(client, gH_ZVolume, info);

		float current = StringToFloat(info);
		char currentFormat[8];
		switch (current) {
		    case 1.0: {
		        Format(currentFormat, sizeof(currentFormat), "100%%");
		    }
		    case 0.6: {
		        Format(currentFormat, sizeof(currentFormat), "75%%");
		    }
		    case 0.3: {
		        Format(currentFormat, sizeof(currentFormat), "50%%");
		    }
		    case 0.1: {
		        Format(currentFormat, sizeof(currentFormat), "25%%");
		    }
		    case 0.0: {
		        Format(currentFormat, sizeof(currentFormat), "0%%");
		    }
		    default: {
		    	Format(currentFormat, sizeof(currentFormat), "100%%");
		    }
		} 

		CPrintToChat(client, "{green}[ZR]{default} You have set your {red}zombie volume{default} to {green}%s{default} volume.", currentFormat);

		UpdateClientZVol(client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public void UpdateClientZVol(int client) {
	char cookie[8];
	GetClientCookie(client, gH_ZVolume, cookie, sizeof(cookie));

	g_fZVolume[client] = StringToFloat(cookie);
}

SEffectsEmitSoundFromClientWithZVol(client, const String:sound[], level = SNDLEVEL_NORMAL)
{
	if (g_Game == Game_CSGO)
	{
		// Precache sound before playing.// Emit sound from client.
		PrecacheSoundAny(sound);
		
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				if(g_fZVolume[i] == -1.0)
					g_fZVolume[i] = 1.0;

				EmitSoundToClientAny(i, sound, client, _, level, _, g_fZVolume[i]);
			}
		}
	}
	else
	{
		// Precache sound before playing.// Emit sound from client.
		PrecacheSound(sound);
		// Emit sound from client.
		EmitSoundToAll(sound, client, _, level);
	}
}

/**
 * Gets a random zombie sound from hl2 folder.
 *
 * @param sound	 The randomly picked sound.
 * @param soundtype The type of sound to get. (See enum ZombieSounds)
 * @return		  True if sound was successfully picked, false otherwise. 
 */	
bool:ZombieSoundsGetRandomSound(String:sound[], ZombieSounds:soundtype)
{
	new soundmin;
	new soundmax;
	decl String:soundpath[SOUND_MAX_PATH];
	
	switch(soundtype)
	{
		// Find moan sound.
		case Moan:
		{
			// Copy min and max
			soundmin = SOUND_MOAN_MIN;
			soundmax = SOUND_MOAN_MAX;
			
			// Copy path
			if (g_Game != Game_CSGO) strcopy(soundpath, sizeof(soundpath), SOUND_MOAN_PATH);
			else strcopy(soundpath, sizeof(soundpath), SOUND_MOAN_PATH_CSGO);
		}
		// Find groan sound. (zombie shot)
		case Groan:
		{
			// Copy min and max
			soundmin = SOUND_GROAN_MIN;
			soundmax = SOUND_GROAN_MAX;
			
			// Copy path
			if (g_Game != Game_CSGO) strcopy(soundpath, sizeof(soundpath), SOUND_GROAN_PATH);
			else strcopy(soundpath, sizeof(soundpath), SOUND_GROAN_PATH_CSGO);
		}
		// Find death sound.
		case Death:
		{
			// Copy min and max
			soundmin = SOUND_DEATH_MIN;
			soundmax = SOUND_DEATH_MAX;
			
			// Copy path
			if (g_Game != Game_CSGO) strcopy(soundpath, sizeof(soundpath), SOUND_DEATH_PATH);
			else strcopy(soundpath, sizeof(soundpath), SOUND_DEATH_PATH_CSGO);
		}
		// Invalid case given.
		default:
		{
			// No handled case was given.
			return false;
		}
	}
	
	// Pick a random integer between min and max sound file index.
	new randsound = GetRandomInt(soundmin, soundmax);
	
	// Format random index into sound path.
	Format(sound, SOUND_MAX_PATH, soundpath, randsound);
	
	// Found sound.
	return true;
}

/**
 * Timer callback, repeats a moaning sound on zombies.
 * 
 * @param timer	 The timer handle.
 * @param client	The client index.
 */
public Action:ZombieSoundsMoanTimer(Handle:timer, any:client)
{
	// If client isn't in-game or client is no longer a zombie, then stop.
	if (!IsClientInGame(client) || !InfectIsClientInfected(client))
	{
		// Reset timer handle.
		tSEffectsMoan[client] = INVALID_HANDLE;
		
		// Stop timer.
		return Plugin_Stop;
	}
	
	// Emit moan sound.
	ZombieSoundsMoan(client);
	
	// Allow timer to continue.
	return Plugin_Continue;
}

/**
 * Emits a moan sound from the specified client.
 *
 * @param client	Client index.
 */
ZombieSoundsMoan(client)
{
	// Get random moan sound.
	decl String:sound[SOUND_MAX_PATH];
	ZombieSoundsGetRandomSound(sound, Moan);
	
	// Emit sound from client.
	SEffectsEmitSoundFromClientWithZVol(client, sound, SNDLEVEL_SCREAMING);
}

/**
 * Emits the scream sound (on infection) from the specified client.
 *
 * @param client	Client index.
 */
ZombieSoundsScream(client)
{
	decl String:sound[PLATFORM_MAX_PATH];
	GetConVarString(g_hCvarsList[CVAR_INFECT_SOUND], sound, sizeof(sound));
	
	// If cvar contains path, then continue.
	if (sound[0])
	{
		// Emit infect sound from infected client.
		SEffectsEmitSoundFromClientWithZVol(client, sound, SNDLEVEL_SCREAMING);
	}
}

/**
 * Starts a reset timer for the client's command counter if not already started.
 *
 * @param client	Client index.
 */
ZombieSoundsCmdTimerCheck(client)
{
	// Only create timer if it doesn't exist.
	if (g_hSEffectsCommandTimer[client] == INVALID_HANDLE)
	{
		new Float:timespan = GetConVarFloat(g_hCvarsList[CVAR_SEFFECTS_COMMAND_TIMESPAN]);
		
		// Only create timer if time span is enabled.
		if (timespan > 0.0)
		{
			g_hSEffectsCommandTimer[client] = CreateTimer(timespan, ZombieSoundsCmdTimer, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}
	}
}

/**
 * Resets all command counters.
 */
ZombieSoundsResetCmdCounters()
{
	for (new client = 0; client <= MAXPLAYERS; client++)
	{
		g_SEffectsCommandCount[client] = 0;
	}
}

/**
 * Stops all command counter timers.
 */
ZombieSoundsResetCmdTimers()
{
	for (new client = 0; client <= MAXPLAYERS; client++)
	{
		ZREndTimer(g_hSEffectsCommandTimer[client]);
	}
}

/**
 * Returns whether a player is allowed to play a zombie sound or not.
 *
 * @param client	Client index.
 * @return		  True if allowed, false otherwise.
 */
bool:ZombieSoundsCommandAllowed(client)
{
	new limit = GetConVarInt(g_hCvarsList[CVAR_SEFFECTS_COMMAND_LIMIT]);
	
	if (limit <= 0 ||
		g_SEffectsCommandCount[client] < limit)
	{
		return true;
	}
	
	return false;
}

/**
 * Scream command handler.
 */
public Action:ZombieSoundsScreamCommand(client, argc)
{
	if (IsClientInGame(client) &&
		IsPlayerAlive(client) &&
		InfectIsClientInfected(client) &&
		ZombieSoundsCommandAllowed(client))
	{
		ZombieSoundsScream(client);
		g_SEffectsCommandCount[client]++;
		ZombieSoundsCmdTimerCheck(client);
	}
	
	return Plugin_Handled;
}

/**
 * Moan command handler.
 */
public Action:ZombieSoundsMoanCommand(client, argc)
{
	if (IsClientInGame(client) &&
		IsPlayerAlive(client) &&
		InfectIsClientInfected(client) &&
		ZombieSoundsCommandAllowed(client))
	{
		ZombieSoundsMoan(client);
		g_SEffectsCommandCount[client]++;
		ZombieSoundsCmdTimerCheck(client);
	}
	
	return Plugin_Handled;
}

/**
 * Command counter reset timer.
 */
public Action:ZombieSoundsCmdTimer(Handle:timer, any:client)
{
	g_SEffectsCommandCount[client] = 0;
}