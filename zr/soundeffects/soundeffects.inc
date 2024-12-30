/*
 * ============================================================================
 *
 *  Zombie:Reloaded
 *
 *  File:		  soundeffects.inc
 *  Type:		  Core 
 *  Description:   Basic sound-management API.
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
 * Maximum sound path length.
 */
#define SOUND_MAX_PATH 128

/**
 * Ambient sound channel.
 */
#define SOUND_AMBIENT_CHANNEL 8

#include "zr/soundeffects/voice"
#include "zr/soundeffects/ambientsounds"
#include "zr/soundeffects/zombiesounds"

/**
 * Load sound effects hook.
 */

SEffectsInit() 
{
	AddNormalSoundHook(SEffects_SoundHook);
}

/**
 * Load sound effects data.
 */
SEffectsLoad()
{
	// Load ambient sound cvars.
	AmbientSoundsLoad();
}

/**
 * Map is starting.
 */ 
SEffectsOnMapStart()
{
	// Forward event to sub-modules.
	AmbientSoundsOnMapStart();
}

/**
 * Client is joining the server.
 * 
 * @param client	The client index.
 */
SEffectsClientInit(client)
{
	// Forward event to sub-modules.
	AmbientSoundsClientInit(client);
	ZombieSoundsClientInit(client);
	UpdateClientHitSounds(client);
}

/**
 * The round is starting.
 */
SEffectsOnRoundStart()
{
	// Forward event to sub-modules.
	VoiceOnRoundStart();
	AmbientSoundsOnRoundStart();
}

/**
 * The round is ending.
 */
SEffectsOnRoundEnd()
{
	// Forward event to sub-modules.
	VoiceOnRoundEnd();
	AmbientSoundsOnRoundEnd();
	ZombieSoundsOnRoundEnd();
}

/**
 * Client is spawning into the game.
 * 
 * @param client	The client index.
 */
SEffectsOnClientSpawn(client)
{
	// Forward event to sub-modules.
	VoiceOnClientSpawn(client);
	ZombieSoundsOnClientSpawn(client);
	UpdateClientHitSounds(client);
}

/**
 * Client is spawning into the game. *Post
 * 
 * @param client	The client index.
 */
SEffectsOnClientSpawnPost(client)
{
	// Forward event to sub-modules.
	AmbientSoundsOnClientSpawnPost(client);
}

/**
 * Client has been killed.
 * 
 * @param client	The client index.
 */
SEffectsOnClientDeath(client)
{
	// Forward event to sub-modules.
	ZombieSoundsOnClientDeath(client);
}

/**
 * Client has been hurt.
 * 
 * @param client	The client index.
 */
SEffectsOnClientHurt(client)
{
	// Forward event to sub-modules.
	ZombieSoundsOnClientHurt(client);
}

/**
 * Client has been infected.
 * 
 * @param client	The client index.
 */
SEffectsOnClientInfected(client)
{
	// Forward event to sub-modules.
	VoiceOnClientInfected(client);
	ZombieSoundsOnClientInfected(client);
}

/**
 * Client has been turned back human.
 * 
 * @param client	The client index.
 */
SEffectsOnClientHuman(client)
{
	// Forward event to sub-modules.
	VoiceOnClientHuman(client);
}

Handle gH_MuteHitSounds;
bool g_bMuteHitSounds[MAXPLAYERS+1] = {false, ...};

SEffectsOnCommandsCreate() {
	RegConsoleCmd("sm_hitsounds", Command_HitSounds, "Command for client to toggle hitsounds.");
	RegConsoleCmd("sm_hitsound", Command_HitSounds, "Command for client to toggle hitsounds.");
	RegConsoleCmd("sm_hs", Command_HitSounds, "Command for client to toggle hitsounds.");
	gH_MuteHitSounds = RegClientCookie("zr_mute_hitsound_cookie", "Hitsound status.", CookieAccess_Private);
}

public Action Command_HitSounds(int client, int argc) {
	g_bMuteHitSounds[client] = !g_bMuteHitSounds[client];
	CPrintToChat(client, "{green}[ZR]{default} You have {green}%s{default} hitsounds.", g_bMuteHitSounds[client] ? "muted" : "enabled");

	if(g_bMuteHitSounds[client])
		SetClientCookie(client, gH_MuteHitSounds, "1");
	else
		SetClientCookie(client, gH_MuteHitSounds, "0");

	return Plugin_Handled;
}

public void UpdateClientHitSounds(int client) {
	char cookie[8];
	GetClientCookie(client, gH_MuteHitSounds, cookie, sizeof(cookie));

	if(strlen(cookie) != 0)
		g_bMuteHitSounds[client] = StringToInt(cookie) == 1;
}

/**
 * Emits an ambient sound
 * 
 * @param sound		 The path to the sound file (relative to sounds/)
 * @param soundvolume   The volume of the sound (0.0 - 1.0)
 * @param client		(Optional) Client index to play sound to.
 */
SEffectsEmitAmbientSound(const String:sound[], Float:ambientvolume = 1.0, client = -1)
{
	// Precache sound before playing.
	if (g_Game == Game_CSGO)
	{
		PrecacheSoundAny(sound);
	}
	else
	{
		PrecacheSound(sound);
	}
	
	if (ZRIsClientValid(client))
	{
		// Emit ambient sound.
		if (g_Game == Game_CSGO)
		{
			EmitSoundToClientAny(client, sound, SOUND_FROM_PLAYER, SOUND_AMBIENT_CHANNEL, _, _, ambientvolume);
		}
		else
		{
			EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SOUND_AMBIENT_CHANNEL, _, _, ambientvolume);
		}
		
		// Flag client that sound is playing.
		bAmbientSoundsIsPlaying[client] = true;
		
	}
	else
	{
		for (new x = 1; x <= MaxClients; x++)
		{
			// If client isn't in-game, then stop.
			if (!IsClientInGame(x))
			{
				continue;
			}
			
			// Emit ambient sound.
			if (g_Game == Game_CSGO)
			{
				EmitSoundToClientAny(x, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, _, _, ambientvolume);
			}
			else
			{
				EmitSoundToClient(x, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, _, _, ambientvolume);
			}
		}
	}
}

/**
 * Stop an ambient sound
 *  
 * @param sound	 The path to the sound file (relative to sounds/) 
 */
SEffectsStopAmbientSound(const String:sound[])
{
	// x = client index.
	for (new x = 1; x <= MaxClients; x++)
	{
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// Stop ambient sound.
		StopSound(x, SOUND_AMBIENT_CHANNEL, sound);
	}
}

/**
 * Replay an ambient sound
 * 
 * @param sound	 The path to the sound file (relative to sounds/)
 */ 

public Action SEffects_SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	for (int i = 0; i < numClients; i++) {
		if (g_bMuteHitSounds[clients[i]]) {
			for (int j = i; j < numClients-1; j++) {
				clients[j] = clients[j+1];
			}
			
			numClients--;
			i--;
		}
	}

	if(StrContains(sample, "physics/flesh/flesh_impact_bullet") != -1 || StrContains(sample, "player/kevlar") != -1 || StrContains(sample, "player/headshot") != -1 || StrContains( sample, "player/bhit_helmet" ) != -1) {
		volume = GetConVarFloat(g_hCvarsList[CVAR_SEFFECTS_HIT_VOLUME]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}