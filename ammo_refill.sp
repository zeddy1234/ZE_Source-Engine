#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[ZR] Reserve Ammo Refill",
	author = "Strellic",
	description = "Refills a player's reserve ammo as they shoot.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/strellic"
};

public void OnPluginStart() {
	HookEvent("weapon_fire", Event_WeaponFire);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnEntityCreated(int entity, const char[] classname) {
	if(StrContains(classname, "weapon_") == 0 && StrContains(classname, "c4") == -1)
		SDKHook(entity, SDKHook_SpawnPost, Hook_OnSpawnPost);
}

public void Hook_OnSpawnPost(int entity) {
	RequestFrame(WeaponSpawnPost, EntIndexToEntRef(entity));
}

public void WeaponSpawnPost(int ref) {
	int weapon = EntRefToEntIndex(ref);
	if(weapon == INVALID_ENT_REFERENCE || !IsValidEdict(weapon))
		return;

	int client = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity"); 
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
		if(weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) {
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
		}
	}
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_WeaponEquipPost, Hook_Weapon);
}

public Action Hook_Weapon(int client, int weapon) {
    if(IsValidEdict(weapon) && (weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY))) {
		SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	}
}

public Action Event_WeaponFire(Event event, const char[] szName, bool bDontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if(IsValidEdict(weapon) && (weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY))) {
			if(GetEntProp(weapon, Prop_Send, "m_iClip1") != 0)
				SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount") + 1);
		}
	}
}