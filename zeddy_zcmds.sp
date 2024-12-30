#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#include <colors_csgo>

#pragma newdecls required
#define PLUGIN_VERSION "1.0"

#define CS_SLOT_PRIMARY 0
#define CS_SLOT_SECONDARY 1
#define CS_SLOT_KNIFE 2
#define CS_SLOT_GRENADE 3
#define CS_SLOT_C4 4

public Plugin myinfo = {
	name = "ZCmds",
	author = "Strellic",
	description = "Adds some fun commands to ZR",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/strellic"
};

ConVar g_cVZAmmoCost, g_cVZAmmoDuration;
ConVar g_cVZSpeedCost, g_cVZSpeedDuration, g_cVZSpeed;
ConVar g_cVZInvisCost, g_cVZInvisDuration, g_cVZInvisAmount;
ConVar g_cVBreachCost, g_cVBreachAmount, g_cVBreachUses, g_cVBreachDuration, g_cVBreachDamage, g_cVBreachRadius, g_cVBreachVolume;
ConVar g_cVZSpeedStatus, g_cVZInvisStatus, g_cVZAmmoStatus, g_cVBreachStatus;

int g_iAmmoCost = 0;
float g_fAmmoDuration = 0.0;

int g_iSpeedCost = 0;
float g_fSpeedDuration = 0.0, g_fSpeed = 0.0;

int g_iInvisCost = 0;
int g_iInvisAmount = 0;
float g_fInvisDuration = 0.0;

int g_iBreachCost = 0;
int g_iBreachAmount = 0;
int g_iBreachUses = 0;
float g_fBreachDuration = 0.0;
float g_fBreachDamage = 0.0;
float g_fBreachRadius = 0.0;
float g_fBreachVolume = 0.0;

bool g_bAmmoEnabled = false, g_bSpeedEnabled = false, g_bInvisEnabled = false, g_bBreachEnabled = false;

bool g_bInfAmmo[MAXPLAYERS + 1] = {false, ...};
bool g_bAmmoUsed[MAXPLAYERS + 1] = {false, ...};

bool g_bSpeedSet[MAXPLAYERS + 1] = {false, ...};
bool g_bSpeedUsed[MAXPLAYERS + 1] = {false, ...};

bool g_bInvisSet[MAXPLAYERS + 1] = {false, ...};
bool g_bInvisUsed[MAXPLAYERS + 1] = {false, ...};

int g_iBreachUsed[MAXPLAYERS + 1] = {0, ...};

int g_iZombieKills[MAXPLAYERS + 1] = {0, ...};

public void OnPluginStart() {
	CreateConVar("sm_zcmds_version", PLUGIN_VERSION, "ZCmds Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	RegConsoleCmd("sm_zammo", Command_ZAmmo);

	RegConsoleCmd("sm_breachcharge", Command_Breach);
	RegConsoleCmd("sm_breach", Command_Breach);
	RegConsoleCmd("sm_charge", Command_Breach);
	RegConsoleCmd("sm_bc", Command_Breach);

	RegConsoleCmd("sm_skill", Command_Skill);
	RegConsoleCmd("sm_skills", Command_Skill);

	g_cVZAmmoCost 		= CreateConVar("sm_zcmds_zammo_cost", "20000", "Defines how much the !zammo command will cost.");
	g_cVZAmmoDuration 	= CreateConVar("sm_zcmds_zammo_duration", "10.0", "Defines how much time humans are given infinite ammo when using !zammo.");
	g_cVZAmmoCost.AddChangeHook(OnConVarChange);
	g_cVZAmmoDuration.AddChangeHook(OnConVarChange);

	g_cVZSpeedCost 		= CreateConVar("sm_zcmds_zspeed_killcost", "8", "Defines how many kills zspeed requires.");
	g_cVZSpeedDuration 	= CreateConVar("sm_zcmds_zspeed_duration", "5.0", "Defines how much time zombies are given increased speed when using !zspeed.");
	g_cVZSpeed 			= CreateConVar("sm_zcmds_zspeed", "1.8", "Defines the new speed multiplier of zombies when using !zspeed.");
	g_cVZSpeedCost.AddChangeHook(OnConVarChange);
	g_cVZSpeedDuration.AddChangeHook(OnConVarChange);
	g_cVZSpeed.AddChangeHook(OnConVarChange);

	g_cVZInvisCost 		= CreateConVar("sm_zcmds_zinvis_killcost", "5", "Defines how many kills zinvis requires.");
	g_cVZInvisDuration 	= CreateConVar("sm_zcmds_zinvis_duration", "5.0", "Defines how much time zombies are given increased speed when using !zspeed.");
	g_cVZInvisAmount 	= CreateConVar("sm_zcmds_zinvis_amount", "100", "Defines the new alpha value given to invisible zombies. [0 - 255]", _, true, 0.0, true, 255.0);
	g_cVZInvisCost.AddChangeHook(OnConVarChange);
	g_cVZInvisDuration.AddChangeHook(OnConVarChange);
	g_cVZInvisAmount.AddChangeHook(OnConVarChange);

	g_cVBreachCost 		= CreateConVar("sm_zcmds_breach_cost", "20000", "Defines how much breachcharges will cost.");
	g_cVBreachAmount	= CreateConVar("sm_zcmds_breach_amount", "1", "Defines how many breachcharges are given.");
	g_cVBreachUses		= CreateConVar("sm_zcmds_breach_uses", "1", "Defines how many times a player can use the breachcharge command (-1 to disable limit).");
	g_cVBreachDuration	= CreateConVar("sm_zcmds_breach_duration", "4.0", "Defines how long zombies will stay on fire for from breachcharges.");
	g_cVBreachDamage	= CreateConVar("sm_zcmds_breach_damage", "50.0", "Defines the multiplier of the damage zombies will take from breachcharges.");
	g_cVBreachRadius	= CreateConVar("sm_zcmds_breach_radius", "200.0", "Defines the multiplier for the radius of the breachcharge explosion .");
	g_cVBreachVolume	= CreateConVar("sm_zcmds_breach_volume", "0.4", "Defines the volume for the beeping noise of the breachcharge.", _, true, 0.0, true, 1.0);
	g_cVBreachCost.AddChangeHook(OnConVarChange);
	g_cVBreachAmount.AddChangeHook(OnConVarChange);
	g_cVBreachUses.AddChangeHook(OnConVarChange);
	g_cVBreachDuration.AddChangeHook(OnConVarChange);
	g_cVBreachDamage.AddChangeHook(OnConVarChange);
	g_cVBreachRadius.AddChangeHook(OnConVarChange);
	g_cVBreachVolume.AddChangeHook(OnConVarChange);

	g_cVZAmmoStatus		= CreateConVar("sm_zcmds_zammo_status", "1", "Defines whether !zammo is enabled or disabled.");
	g_cVZSpeedStatus	= CreateConVar("sm_zcmds_zspeed_status", "1", "Defines whether zspeed is enabled or disabled.");
	g_cVZInvisStatus	= CreateConVar("sm_zcmds_zinvis_status", "1", "Defines whether zinvis is enabled or disabled.");
	g_cVBreachStatus	= CreateConVar("sm_zcmds_breach_status", "1", "Defines whether breachcharges are enabled or disabled.");
	g_cVZAmmoStatus.AddChangeHook(OnConVarChange);
	g_cVZSpeedStatus.AddChangeHook(OnConVarChange);
	g_cVZInvisStatus.AddChangeHook(OnConVarChange);
	g_cVBreachStatus.AddChangeHook(OnConVarChange);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_PostNoCopy);

	AutoExecConfig(true);
	UpdateConVars();

	AddNormalSoundHook(Hook_NormalSound);
}

public void OnConVarChange(Handle cvar, const char[] oldValue, const char[] newValue) {
	UpdateConVars();
}

public void UpdateConVars() {
	g_iAmmoCost = g_cVZAmmoCost.IntValue;
	g_fAmmoDuration = g_cVZAmmoDuration.FloatValue;

	g_iSpeedCost = g_cVZSpeedCost.IntValue;
	g_fSpeedDuration = g_cVZSpeedDuration.FloatValue;
	g_fSpeed = g_cVZSpeed.FloatValue;

	g_iInvisCost = g_cVZInvisCost.IntValue;
	g_fInvisDuration = g_cVZInvisDuration.FloatValue;
	g_iInvisAmount = g_cVZInvisAmount.IntValue;

	g_iBreachCost = g_cVBreachCost.IntValue;
	g_iBreachAmount = g_cVBreachAmount.IntValue;
	g_iBreachUses = g_cVBreachUses.IntValue;
	g_fBreachDuration = g_cVBreachDuration.FloatValue;
	g_fBreachDamage = g_cVBreachDamage.FloatValue;
	g_fBreachRadius = g_cVBreachRadius.FloatValue;
	g_fBreachVolume = g_cVBreachVolume.FloatValue;

	g_bAmmoEnabled = g_cVZAmmoStatus.BoolValue;
	g_bSpeedEnabled = g_cVZSpeedStatus.BoolValue;
	g_bInvisEnabled = g_cVZInvisStatus.BoolValue;
	g_bBreachEnabled = g_cVBreachStatus.BoolValue;
}

public int GetClientMoney(int client) {
	return GetEntProp(client, Prop_Send, "m_iAccount");
}
public void SetClientMoney(int client, int money) {
	SetEntProp(client, Prop_Send, "m_iAccount", money);
}

public void SetClientInfiniteAmmo(int client, bool status) {
	g_bInfAmmo[client] = status;
}

public void ResetClient(int client) {
	g_bInfAmmo[client] = false;
	g_bAmmoUsed[client] = false;

	g_bSpeedUsed[client] = false;
	if(g_bSpeedSet[client]) {
		g_bSpeedSet[client] = false;
		if(IsClientInGame(client))
			SetClientSpeedMultiplier(client, 1.0);
	}

	g_bInvisUsed[client] = false;
	if(g_bInvisSet[client]) {
		g_bInvisSet[client] = false;
		if(IsClientInGame(client))
			AdjustTransparency(client, 255);
	}

	g_iBreachUsed[client] = 0;
	g_iZombieKills[client] = 0;

	if(IsClientInGame(client)) {
		int wpnCheck = GetPlayerWeaponSlot(client, CS_SLOT_C4); // breachcharge slot
		while (wpnCheck != -1) {
			RemovePlayerItem(client, wpnCheck);
			AcceptEntityInput(wpnCheck, "Kill");
			wpnCheck = GetPlayerWeaponSlot(client, CS_SLOT_C4);
		}
	}
}

public void Event_RoundStart(Handle hEvent, char[] name, bool dontBroadcast) {
	for(int client = 1; client <= MaxClients; client++) {
		ResetClient(client);
	}
}

public void Event_WeaponFire(Handle hEvent, char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(g_bInfAmmo[client]) {
		int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", 0);
		if(IsValidEntity(weapon)) {
			if(weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) {
				if(GetEntProp(weapon, Prop_Send, "m_iState", 4, 0) == 2 && GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0)) {
					int ammoAdd = 1;
					char weaponClassname[128];
					GetEntityClassname(weapon, weaponClassname, sizeof(weaponClassname));

					if(StrEqual(weaponClassname, "weapon_glock", true) || StrEqual(weaponClassname, "weapon_famas", true)) {
						if(GetEntProp(weapon, Prop_Send, "m_bBurstMode")) {
							switch (GetEntProp(weapon, Prop_Send, "m_iClip1")) {
								case 1: {
									ammoAdd = 1;
								}
								case 2: {
									ammoAdd = 2;
								}
								default: {
									ammoAdd = 3;
								}
							}
						}
					}
					SetEntProp(weapon, Prop_Send, "m_iClip1", GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0) + ammoAdd, 4, 0);
				}
			}
		}
	}

	return;
}

public Action Command_ZAmmo(int client, int args) {
	if(!g_bAmmoEnabled) {
		CPrintToChat(client, "{darkred}[ZR]{default} The {green}!zammo{default} command is currently {red}disabled{default}.");
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(client)) {
		CPrintToChat(client, "{darkred}[ZR]{default} You must be {green}alive{default} to use the {green}!zammo{default} command.");
		return Plugin_Handled;
	}

	if(!ZR_IsClientHuman(client)) {
		CPrintToChat(client, "{darkred}[ZR]{default} You must be a {blue}human{default} to use the {green}!zammo{default} command.");
		return Plugin_Handled;
	}

	if(g_bAmmoUsed[client]) {
		CPrintToChat(client, "{darkred}[ZR]{default} You have already used {green}!zammo{default} this round!");
		return Plugin_Handled;
	}

	if(g_iAmmoCost > GetClientMoney(client)) {
		CPrintToChat(client, "{darkred}[ZR]{default} You do not have enough money to use the {green}!zammo{default} command, you need {green}$%i{default} to buy {green}infinite ammo{default} for {green}%.2fs{default}.", g_iAmmoCost, g_fAmmoDuration);
		return Plugin_Handled;
	}

	CPrintToChat(client, "{darkred}[ZR]{default} You have bought {green}infinite ammo{default} for {green}%.2fs{default}!", g_fAmmoDuration);
	CPrintToChatAll("{darkred}[ZR] {green}%N{default} has bought {green}infinite ammo{default}!", client);
	SetClientMoney(client, GetClientMoney(client) - g_iAmmoCost);
	g_bInfAmmo[client] = true;
	g_bAmmoUsed[client] = true;

	CreateTimer(g_fAmmoDuration, Timer_DisableZAmmo, client);

	return Plugin_Handled;
}

public Action Timer_DisableZAmmo(Handle timer, int client) {
	g_bInfAmmo[client] = false;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn) {
	ResetClient(client);

	if(attacker != -1 && !motherInfect) {
		g_iZombieKills[attacker]++;
		
		PrintHintText(attacker, "Kill Count: %d", g_iZombieKills[attacker]);

		if((g_iZombieKills[attacker] == g_iSpeedCost && g_bSpeedEnabled && !g_bSpeedUsed[attacker]) || 
			(g_iZombieKills[attacker] == g_iInvisCost && g_bInvisEnabled && !g_bInvisUsed[attacker])) {
			DisplayZMenu(attacker);
		}
	}
}

public void DisplayZMenu(int client) {
	FakeClientCommand(client, "menuselect 9");

	Handle menu = CreateMenu(ZMenuHandler);

	SetMenuTitle(menu, "Zombie Menu (!skill)\nKills: %i", g_iZombieKills[client]);
	if(g_bSpeedEnabled) {
		char zSpeedInfo[64];

		if(g_bSpeedUsed[client]) {
			Format(zSpeedInfo, sizeof(zSpeedInfo), "ZSpeed [USED]");
			AddMenuItem(menu, "zspeed", zSpeedInfo, ITEMDRAW_DISABLED);
		}
		else {
			Format(zSpeedInfo, sizeof(zSpeedInfo), "ZSpeed (Kills Required: %d / %.2fs)", g_iSpeedCost, g_fSpeedDuration);
			if(g_iZombieKills[client] >= g_iSpeedCost)
				AddMenuItem(menu, "zspeed", zSpeedInfo);
			else
				AddMenuItem(menu, "zspeed", zSpeedInfo, ITEMDRAW_DISABLED);
		}
	}
	if(g_bInvisEnabled) {
		char zInvisInfo[64];

		if(g_bInvisUsed[client]) {
			Format(zInvisInfo, sizeof(zInvisInfo), "ZInvis [USED]");
			AddMenuItem(menu, "zinvis", zInvisInfo, ITEMDRAW_DISABLED);
		}
		else {
			Format(zInvisInfo, sizeof(zInvisInfo), "ZInvis (Kills Required: %d / %.2fs)", g_iInvisCost, g_fInvisDuration);
			if(g_iZombieKills[client] >= g_iInvisCost)
				AddMenuItem(menu, "zinvis", zInvisInfo);
			else
				AddMenuItem(menu, "zinvis", zInvisInfo, ITEMDRAW_DISABLED);
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int ZMenuHandler(Handle menu, MenuAction action, int client, int position)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, position, info, sizeof(info));

		if(StrEqual(info, "zspeed") && IsPlayerAlive(client) && ZR_IsClientZombie(client) && g_iZombieKills[client] >= g_iSpeedCost) {
			CPrintToChat(client, "{darkred}[ZR]{default} {green}Zombie speed{default} activated for {green}%.2fs{default}!", g_fSpeedDuration);
			CPrintToChatAll("{darkred}[ZR] {green}%N{default} has activated {green}zombie speed{default}! {red}WATCH OUT!{default}", client);

			SetClientSpeedMultiplier(client, g_fSpeed);
			g_bSpeedSet[client] = true;
			g_bSpeedUsed[client] = true;

			CreateTimer(g_fSpeedDuration, Timer_DisableZSpeed, GetClientSerial(client));

			if(!g_bInvisUsed[client] && g_iZombieKills[client] >= g_iInvisCost)
				DisplayZMenu(client);
		}
		else if(StrEqual(info, "zinvis") && IsPlayerAlive(client) && ZR_IsClientZombie(client) && g_iZombieKills[client] >= g_iInvisCost) {
			CPrintToChat(client, "{darkred}[ZR]{default} {green}Zombie invis{default} activated for {green}%.2fs{default}!", g_fInvisDuration);
			CPrintToChatAll("{darkred}[ZR] {green}%N{default} has activated {green}zombie invis{default}! {red}WATCH OUT!{default}", client);

			g_bInvisSet[client] = true;
			g_bInvisUsed[client] = true;

			AdjustTransparency(client, g_iInvisAmount);
			CreateTimer(g_fInvisDuration, Timer_DisableZInvis, client);

			if(!g_bSpeedUsed[client] && g_iZombieKills[client] >= g_iSpeedCost)
				DisplayZMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void AdjustTransparency(int entity, int amount) {
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 255, 255, 255, amount);
}

public Action Timer_DisableZInvis(Handle timer, int client) {
	AdjustTransparency(client, 255);
	g_bInvisSet[client] = false;
}

public void SetClientSpeedMultiplier(int client, float multiplier) {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", multiplier);
}

public Action Timer_DisableZSpeed(Handle timer, int serial) {
	int client = GetClientFromSerial(serial);
	if (client == 0) {
		return Plugin_Stop;
	}

	g_bSpeedSet[client] = false;
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		SetClientSpeedMultiplier(client, 1.0);
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client) {
	ResetClient(client);
}

public Action Command_Skill(int client, int args) {
	if(!IsPlayerAlive(client)) {
		CPrintToChat(client, "{darkred}[ZR]{default} You must be {green}alive{default} to use the {green}!skill{default} command.");
		return Plugin_Handled;
	}

	if(!ZR_IsClientZombie(client)) {
		CPrintToChat(client, "{darkred}[ZR]{default} You must be a {red}zombie{default} to use the {green}!skill{default} command.");
		return Plugin_Handled;
	}

	DisplayZMenu(client);
	return Plugin_Handled;
}

public Action Command_Breach(int client, int argc) {
	if(!g_bBreachEnabled) {
		CPrintToChat(client, "{darkred}[ZR]{default} The {green}breach charge{default} command is currently {red}disabled{default}.");
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(client)) {
		CPrintToChat(client, "{darkred}[ZR]{default} You must be {green}alive{default} to buy a {green}breach charge{default}.");
		return Plugin_Handled;
	}

	if(!ZR_IsClientHuman(client)) {
		CPrintToChat(client, "{darkred}[ZR]{default} You must be a {green}human{default} to buy a {green}breach charge{default}.");
		return Plugin_Handled;
	}

	if(g_iBreachUsed[client] >= g_iBreachUses && g_iBreachUses != -1) {
		CPrintToChat(client, "{darkred}[ZR]{default} You do not have any more {green}breach charges{default} left this round! {red}(%i/%i){default}", g_iBreachUsed[client], g_iBreachUses);
		return Plugin_Handled;
	}

	if(g_iBreachCost > GetClientMoney(client)) {
		CPrintToChat(client, "{darkred}[ZR]{default} You do not have enough money to buy a {green}breach charge{default}, you need {green}$%i{default}.", g_iBreachCost);
		return Plugin_Handled;
	}

	g_iBreachUsed[client]++;

	if(g_iBreachUses == -1)
		CPrintToChat(client, "{darkred}[ZR]{default} You have bought a {green}breach charge{default}!");
	else
		CPrintToChat(client, "{darkred}[ZR]{default} You have bought a {green}breach charge{default}! {red}(%i/%i){default}", g_iBreachUsed[client], g_iBreachUses);

	SetClientMoney(client, GetClientMoney(client) - g_iBreachCost);

	int wpnCheck = GetPlayerWeaponSlot(client, 4); // breachcharge slot
	if(wpnCheck != -1) {
		char szClassname[64];
		GetEntityClassname(wpnCheck, szClassname, sizeof(szClassname));

		if(StrEqual(szClassname, "weapon_breachcharge")) {
			int newAmmo = GetEntProp(wpnCheck, Prop_Send, "m_iClip1") + g_iBreachAmount;
			SetEntProp(wpnCheck, Prop_Send, "m_iClip1", newAmmo);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wpnCheck);
			
			return Plugin_Handled;
		}
		CS_DropWeapon(client, wpnCheck, false, false);
	}

	int bc = GivePlayerItem(client, "weapon_breachcharge");
	SetEntProp(bc, Prop_Send, "m_iClip1", g_iBreachAmount);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", bc);

	return Plugin_Handled;
}

public void Event_PlayerHurt(Event event, char[] name, bool dontBroadcast) {
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);

	char szWeapon[64];
	event.GetString("weapon", szWeapon, sizeof(szWeapon));

	if(StrContains(szWeapon, "breachcharge") != -1) {
		if(IsPlayerAlive(victim) && ZR_IsClientZombie(victim)) {
			ExtinguishEntity(victim);
			IgniteEntity(victim, g_fBreachDuration);
		}
	}
}

public Action Hook_NormalSound(int clients[64], int &numClients, char sample[256], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[256], int &seed) {
	if(StrContains(sample, "survival/breach_warning_beep_01.wav") != -1) {
		volume = g_fBreachVolume;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname) {
	if(StrEqual(classname, "breachcharge_projectile")) {
		SDKHook(entity, SDKHook_SpawnPost, Hook_OnChargeSpawnPost);
		SDKHook(entity, SDKHook_Use, Hook_OnUse);
	}
}

public Action Hook_OnChargeSpawnPost(int entity) {
	CreateTimer(0.01, Timer_ChangeGrenadeStats, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Hook_OnUse(int entity) {
	char szClassname[128];
	GetEntityClassname(entity, szClassname, sizeof(szClassname));

	if(StrEqual(szClassname, "breachcharge_projectile")) {
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_ChangeGrenadeStats(Handle hTimer, int entity) {
	SetEntPropFloat(entity, Prop_Send, "m_DmgRadius", g_fBreachRadius);
	SetEntPropFloat(entity, Prop_Send, "m_flDamage", g_fBreachDamage);
	SetEntProp(entity, Prop_Data, "m_takedamage", 0, 1);
}