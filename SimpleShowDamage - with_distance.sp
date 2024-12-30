#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdktools_stringtables>
#if SOURCEMOD_V_MINOR >= 9
	#include <sdktools_variant_t>
#endif

enum
{
	HG_Generic = 0,
	HG_Head,
	HG_Chest,
	HG_Stomach,
	HG_Leftarm,
	HG_Rightarm,
	HG_Leftleg,
	HG_Rightleg
};

bool
	bCSGO,
	bEnable,
	bMode,
	g_bIsFired[MAXPLAYERS+1],
	g_bIsCrit[MAXPLAYERS+1][MAXPLAYERS+1];

int g_iTotalSGDamage[MAXPLAYERS+1][MAXPLAYERS+1];

float
	fDist,
	g_fPlayerPosLate[MAXPLAYERS+1][3],
	g_fFortniteDist,
	g_faFortniteModifier[3];

Handle g_cType, g_hHudSync;
int g_iType[MAXPLAYERS + 1] = {0, ...};

public Plugin myinfo =
{
	name		= "Show Damage [Multi methods]",
	version		= "2.0.1",
	description	= "Show damage in hint message, HUD and Particle",
	author		= "TheBΦ$$♚#2967 (rewritten by Grey83) + Strellic",
	url			= "http://sourcemod.net"
};

public void OnPluginStart()
{
	g_cType = RegClientCookie("showdamage_type", "Show Damage Display Type", CookieAccess_Private);
	for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client) && AreClientCookiesCached(client))
            LoadCookie(client);
    }

	EngineVersion ev = GetEngineVersion();
	if(ev == Engine_CSGO) bCSGO = true;
	else if(ev != Engine_CSS) SetFailState("Plugin for CSS and CSGO only!");

	LoadTranslations("Simple_Show_Damage.phrases");

	ConVar cvar;
	cvar = CreateConVar("sm_show_damage_enable", "1", "Enable/Disable plugin?", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnable = cvar.BoolValue;

	cvar = CreateConVar("sm_show_damage_mode", "1", "0 = Show damage to victim only\n1 = Show damage and remaining health of victim", _, true, _, true, 2.0);
	cvar.AddChangeHook(CVarChanged_Mode);
	bMode = cvar.BoolValue;

	if(bCSGO)
	{
		cvar = CreateConVar("sm_show_damage_hit_distance", "50.0", "Distance between victim player and damage numbers (NOTE: Make that value lower to prevent numbers show up through the walls)", _, true, 0.0);
		cvar.AddChangeHook(CVarChanged_Dist);
		fDist = cvar.FloatValue;
	}

	cvar = CreateConVar("sm_show_damage_fortnite_distance", "-1", "Max distance for fortnite damage to still show, (-1 to disable)");
	cvar.AddChangeHook(CVarChanged_FortniteDist);
	g_fFortniteDist = cvar.FloatValue;

	cvar = CreateConVar("sm_show_damage_fortnite_distance_modifier", "70 70 75", "Position modifier for fortnite damage (forward, right, up)");
	cvar.AddChangeHook(CVarChanged_FortniteDistModifier);
	char buffer[32];
	cvar.GetString(buffer, sizeof(buffer));
	StringToVector(buffer, g_faFortniteModifier);

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	AutoExecConfig(true, "Simple_Show_Damage");

	RegConsoleCmd("sm_hits", Command_Hits);

	g_hHudSync = CreateHudSynchronizer();
}

public void StringToVector(const char[] sVectorString, float aVector[3])
{
	char asVectors[4][4];
	ExplodeString(sVectorString, " ", asVectors, sizeof(asVectors), sizeof(asVectors[]));

	aVector[0] = StringToFloat(asVectors[0]);
	aVector[1] = StringToFloat(asVectors[1]);
	aVector[2] = StringToFloat(asVectors[2]);
}

public void OnClientPutInServer(int client) {
    LoadCookie(client);
}

public void LoadCookie(int client) {
    char cookie[16];
    GetClientCookie(client, g_cType, cookie, sizeof(cookie));

    g_iType[client] = StringToInt(cookie);
}

public void CVarChanged_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;
}

public void CVarChanged_Mode(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bMode = cvar.BoolValue;
}

public void CVarChanged_Dist(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fDist = cvar.FloatValue;
}

public void CVarChanged_FortniteDist(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_fFortniteDist = cvar.FloatValue;
}

public void CVarChanged_FortniteDistModifier(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	char buffer[32];
	cvar.GetString(buffer, sizeof(buffer));
	StringToVector(buffer, g_faFortniteModifier);
}

public void OnMapStart()
{
	if(!bCSGO) return;

	AddFileToDownloadsTable("particles/gammacase/hit_nums.pcf");
	AddFileToDownloadsTable("materials/gammacase/fortnite/hitnums/nums_bw.vmt");
	AddFileToDownloadsTable("materials/gammacase/fortnite/hitnums/nums_bw.vtf");
	PrecacheGeneric("particles/gammacase/hit_nums.pcf", true);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnable)
		return;

	static int victim, attacker, health, dmg;
	if(!(attacker = GetClientOfUserId(event.GetInt("attacker"))) || !(victim = GetClientOfUserId(event.GetInt("userid")))
	|| attacker == victim)
		return;

	health = event.GetInt("health");
	dmg = event.GetInt("dmg_health");

	switch(g_iType[attacker])
	{
		case 0:
		{
			static bool headshot;
			headshot = event.GetInt("hitgroup") == HG_Head;
			static char wpn[16];
			event.GetString("weapon", wpn, sizeof(wpn));
			if(!strcmp(wpn, "xm1014") || !strcmp(wpn, "nova") || !strcmp(wpn, "mag7") || !strcmp(wpn, "sawedoff"))
			{
				if(!g_bIsFired[attacker])
				{
					g_bIsFired[attacker] = true;
					g_iTotalSGDamage[attacker][victim] = dmg;

					CreateTimer(0.1, TimerHit_CallBack, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
				}
				else g_iTotalSGDamage[attacker][victim] += dmg;

				if(headshot) g_bIsCrit[attacker][victim] = true;
				GetClientAbsOrigin(victim, g_fPlayerPosLate[victim]);
			}
			else ShowPRTDamage(attacker, victim, dmg, headshot);
		}
		case 1:
		{
			if(!bCSGO)
			{
				if(!bMode)
					PrintHintText(attacker, "%t %i %t %N", "Damage Giver", dmg, "Damage Taker", victim);
				else PrintHintText(attacker, "%t  %t %N\n %t %i", "Damage Giver", dmg, "Damage Taker", victim, "Health Remaining", health);
				return;
			}

			if(!bMode)
				PrintHintText(attacker, "%t <font color='#FF0000'>%i</font> %t <font color='#3DB1FF'>%N", "Damage Giver", dmg, "Damage Taker", victim);
			else PrintHintText(attacker, "%t <font color='#FF0000'>%i</font> %t <font color='#3DB1FF'>%N</font>\n %t <font color='#00FF00'>%i</font>", "Damage Giver", dmg, "Damage Taker", victim, "Health Remaining", health);
		}
		case 2:
		{
			if(!bMode)
			{
				if(health > 50)
					SetHudTextParams(-1.0, 0.45, 1.3, 0, 253, 30, 200, 1);	// green
				else if(health > 20)
					SetHudTextParams(-1.0, 0.45, 1.3, 253, 229, 0, 200, 1);	// yellow
				else SetHudTextParams(-1.0, 0.45, 1.3, 255, 0, 0, 200, 1);	// red
				ShowSyncHudText(attacker, g_hHudSync, "%i", dmg);
			}
			else
			{
				//if(health > 50)
				//	SetHudTextParams(0.43, 0.45, 1.3, 0, 253, 30, 200, 1);	// green
				//else if(health > 20)
				//	SetHudTextParams(0.43, 0.45, 1.3, 253, 229, 0, 200, 1);	// yellow
				//else SetHudTextParams(0.43, 0.45, 1.3, 255, 0, 0, 200, 1);	// red
				//ShowSyncHudText(attacker, g_hHudSync2, "%i", health);

				SetHudTextParams(0.57, 0.45, 1.3, 255, 255, 255, 200, 1);	// white
				ShowSyncHudText(attacker, g_hHudSync, "%i", dmg);
			}
		}
	}
}

public Action TimerHit_CallBack(Handle timer, int userid)
{
	static int attacker;
	if(!(attacker = GetClientOfUserId(userid)))
		return Plugin_Stop;

	g_bIsFired[attacker] = false;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && g_iTotalSGDamage[attacker][i])
	{
		ShowPRTDamage(attacker, i, g_iTotalSGDamage[attacker][i], g_bIsCrit[attacker][i], true);
		g_iTotalSGDamage[attacker][i] = 0;
		g_bIsCrit[attacker][i] = false;
	}

	return Plugin_Continue;
}

stock void AnglesToUV(float vOut[3], float vAngles[3])
{
    vOut[0] = Cosine(vAngles[1] * FLOAT_PI / 180.0) * Cosine(vAngles[0] * FLOAT_PI / 180.0);
    vOut[1] = Sine(vAngles[1] * FLOAT_PI / 180.0) * Cosine(vAngles[0] * FLOAT_PI / 180.0);
    vOut[2] = -Sine(vAngles[0] * FLOAT_PI / 180.0);
} 

stock void ShowPRTDamage(int attacker, int victim, int damage, bool crit, bool late = false)
{
	static float pos[3], pos2[3], ang[3], fwd[3], right[3], temppos[3], dist, d;
	static int ent, l, count, dmgnums[8];
	static char buff[16];

	count = 0;

	while(damage > 0)
	{
		dmgnums[count++] = damage % 10;
		damage /= 10;
	}

	GetClientEyeAngles(attacker, ang);
	GetClientAbsOrigin(attacker, pos2);

	if(late)
		pos = g_fPlayerPosLate[victim];
	else
		GetClientAbsOrigin(victim, pos);

	GetAngleVectors(ang, fwd, right, NULL_VECTOR);

	l = RoundToCeil(float(count) / 2.0);

	dist = GetVectorDistance(pos2, pos);

	if(dist > 700.0)
		d = dist / 700.0 * 6.0;
	else d = 6.0;

	pos[0] += right[0] * d * l * GetRandomFloat(-0.5, 1.0);
	pos[1] += right[1] * d * l * GetRandomFloat(-0.5, 1.0);
	if(GetEntProp(victim, Prop_Send, "m_bDucked"))
		if(crit)
			pos[2] += 45.0 + GetRandomFloat(0.0, 10.0);
		else pos[2] += 25.0 + GetRandomFloat(0.0, 20.0);
	else
		if(crit)
			pos[2] += 60.0 + GetRandomFloat(0.0, 10.0);
		else pos[2] += 35.0 + GetRandomFloat(0.0, 20.0);

	float f1 = GetRandomFloat(-5.0, 5.0);
	float f2 = GetRandomFloat(-5.0, 5.0);
	float f3 = GetRandomFloat(-5.0, 5.0);

	for(int i = count - 1; i >= 0; i--)
	{
		temppos = pos;

		temppos[0] -= fwd[0] * fDist + right[0] * d * l;
		temppos[1] -= fwd[1] * fDist + right[1] * d * l;

		if(dist > g_fFortniteDist && g_fFortniteDist > 0) {
			float fForward[3], fRight[3], fUp[3];
			GetAngleVectors(ang, fForward, fRight, fUp);

			temppos[0] = pos2[0] + fForward[0] * g_faFortniteModifier[0] + fRight[0] * g_faFortniteModifier[1] + f1;
			temppos[1] = pos2[1] + fForward[1] * g_faFortniteModifier[0] + fRight[1] * g_faFortniteModifier[1] + f2;

			temppos[0] += right[0] * 5.5 * l;
			temppos[1] += right[1] * 5.5 * l;

			temppos[2] = pos2[2] + g_faFortniteModifier[2] + f3;
		}

		ent = CreateEntityByName("info_particle_system");
		if(ent == -1)
			SetFailState("Error creating \"info_particle_system\" entity!");

		TeleportEntity(ent, temppos, ang, NULL_VECTOR);

		FormatEx(buff, sizeof(buff), "%s_num%i_f%s", crit ? "crit" : "def", dmgnums[i], l-- > 0 ? "l" : "r");

		DispatchKeyValue(ent, "effect_name", buff);
		DispatchKeyValue(ent, "start_active", "1");

		char szName[16];
		Format(szName, sizeof(szName), "fortnite_%i", attacker);
		DispatchKeyValue(ent, "targetname", szName);

		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", attacker);
		SetVariantString("OnUser1 !self:kill::3:-1");

		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");

		DispatchSpawn(ent);
		ActivateEntity(ent);

		SDKHook(ent, SDKHook_SetTransmit, SetTransmit_Hook);
	}
}

public Action SetTransmit_Hook(int entity, int client) {
	static int buffer;
	if((buffer = GetEdictFlags(entity)) & FL_EDICT_ALWAYS)
		SetEdictFlags(entity, (buffer ^ FL_EDICT_ALWAYS));

	if(client == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) {
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action Command_Hits(int client, int argc) {
	Menu menu = CreateMenu(HitsHandler);
	menu.SetTitle("Display Damage");

	menu.AddItem("0", g_iType[client] == 0 ? "Fortnite [ENABLED]" : "Fortnite");
	menu.AddItem("1", g_iType[client] == 1 ? "HintText [ENABLED]" : "HintText");
	menu.AddItem("2", g_iType[client] == 2 ? "HUD [ENABLED]" : "HUD");
	menu.AddItem("-1", "Disable");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int HitsHandler(Handle menu, MenuAction action, int client, int position)
{
	if(action == MenuAction_Select) {
		char info[8];
		GetMenuItem(menu, position, info, sizeof(info));

		SetClientCookie(client, g_cType, info);
		g_iType[client] = StringToInt(info);

		Command_Hits(client, 0);
	}
	else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}