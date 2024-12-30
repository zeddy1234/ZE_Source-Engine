#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

public Plugin myinfo = {
    name = "Configurable Zombie Escape boss HUD",
    author = "Tanko",
    description = "A plugin for displaying the health of a boss in Zombie Escape to all players using GFL's bosshud format",
    version = "1.10"
};

#define MAX_BOSSES 64
#define BOSS_NAME_LEN 256
#define BOSS_DEAD_HUD_TIMEOUT 3
#define BOSS_HUD_TIMEOUT 10

enum hpbar_mode {
    hpbar_increasing,
    hpbar_decreasing,
    hpbar_none
};

enum hp_mode {
    hp_decreasing,
    hp_increasing,
};

// Data about the bosses in the current level
// The data has to be reloaded every time the level changes
// We reload every round, but a cleaner solution would be possible
// (but I don't want to add even more data for the bosses since SourcePawn doesn't seem to support structs very well)

// The number of bosses in the current level
int n_bosses;

// Display name
char boss_names[BOSS_NAME_LEN][MAX_BOSSES];
// Entity ids
int boss_ids[MAX_BOSSES];
// Entity name
char boss_ents[BOSS_NAME_LEN][MAX_BOSSES];
// math_counter name
char boss_hpents[BOSS_NAME_LEN][MAX_BOSSES];
// math_counter init name
char boss_inithpents[BOSS_NAME_LEN][MAX_BOSSES];
// Max health bars per boss
int boss_max_bars[MAX_BOSSES];
// Current number of health bars
int boss_bars[MAX_BOSSES];
// Current HP, not used for anything, but could be used to refresh the HUD
int boss_hp[MAX_BOSSES];
// The amount of boss hp in each bar
int boss_init_hp[MAX_BOSSES];
// The highest amount of boss hp in each bar, used if there is no init hp
int boss_highest_hp[MAX_BOSSES];
// Force display to have a number of bars
int boss_hpbar_force[MAX_BOSSES];
// The starting hp, used to calculate percentage
int boss_starting_hp[MAX_BOSSES];
// Is the boss dead. If it is we stop showing it in the HUD
bool boss_dead[MAX_BOSSES];
// MultBoss (0/1)
bool boss_multboss;
// BossBeatenShowTopDamage (0/1)
bool boss_showtopdmg;
// Does the boss have HP bars, and if so, does the number increase or decrease
hpbar_mode boss_hpbarmodes[MAX_BOSSES];
hp_mode boss_hpmodes[MAX_BOSSES];
// The boss that is currently being fought
int current_boss;
// When was it last hit?
int boss_hit_time;

int boss_damage[MAXPLAYERS+1];

Handle damage_multiplier;
Handle counter_reward;
// Toggle for enabling/disabling the plugin on a per user basis
Handle enable_cookie;

bool g_bBHudEnabled[MAXPLAYERS] = {false, ...};

public int find_ent_hp(const char[] class, const char[] name) {
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, class)) != -1) {
        int ref = EntIndexToEntRef(ent);
        int hp = GetEntProp(ref, Prop_Data, "m_iHealth");
        char ent_name[256];
        GetEntPropString(ref, Prop_Data, "m_iName", ent_name, sizeof(ent_name));
        if (StrEqual(name, ent_name)) {
            return hp;
        }
    }

    return - 1;
}

// Load the config for this map (mapname could for example be de_dust2, no extensions or anything else)
public void LoadMapData(const char[] mapname) {
    n_bosses = 0;

    boss_hit_time = 0;
    KeyValues kv = new KeyValues("File");
    char filename[256];
    Format(filename, sizeof(filename), "addons/sourcemod/configs/bosshud/%s.txt", mapname);
    kv.ImportFromFile(filename);

    if (!kv.GotoFirstSubKey()) {
        char buf[256];
        Format(buf, sizeof(buf), "Boss HUD data could not be loaded for %s", mapname);
        PrintToChatAll(buf);
        // It's not strictly an error if we don't find the file, but there's no LogWarning
        LogError(buf);
        return;
    }

    boss_multboss = false;
    boss_showtopdmg = true;

    do {
        char buffer[256];
        kv.GetSectionName(buffer, sizeof(buffer));
        if (StrEqual(buffer, "config")) {
            kv.GetString("BossBeatenShowTopDamage", buffer, sizeof(buffer));
            if(StrEqual(buffer, "0"))
                boss_showtopdmg = false;

            continue;
        }

        kv.GetString("HP_counter", buffer, sizeof(buffer));
        if (strlen(buffer) != 0) {
            strcopy(boss_ents[n_bosses], BOSS_NAME_LEN, buffer);
        } else {
            kv.GetString("BreakableName", buffer, BOSS_NAME_LEN);
            strcopy(boss_ents[n_bosses], BOSS_NAME_LEN, buffer);
            boss_hp[n_bosses] = find_ent_hp("func_breakable", buffer);
        }
        kv.GetString("CustomText", buffer, sizeof(buffer));
        if (strlen(buffer) == 0) {
            strcopy(boss_names[n_bosses], strlen(boss_ents[n_bosses]) + 1, boss_ents[n_bosses]);
        } else {
            strcopy(boss_names[n_bosses], strlen(buffer) + 1, buffer);
        }
        kv.GetString("HPbar_counter", boss_hpents[n_bosses], BOSS_NAME_LEN);
        kv.GetString("HPbar_max", buffer, sizeof(buffer));
        kv.GetString("HPinit_counter", boss_inithpents[n_bosses], BOSS_NAME_LEN);
        if(strlen(buffer) == 0)
            Format(buffer, sizeof(buffer), "10");
        boss_max_bars[n_bosses] = StringToInt(buffer);
        kv.GetString("HPbar_default", buffer, sizeof(buffer));
        boss_bars[n_bosses] = StringToInt(buffer);
        kv.GetString("HPBar_force", buffer, sizeof(buffer));
        boss_hpbar_force[n_bosses] = StringToInt(buffer);
        kv.GetString("HPbar_mode", buffer, sizeof(buffer));
        boss_hp[n_bosses] = 0;
        if (StrEqual(buffer, "1")) {
            boss_hpbarmodes[n_bosses] = hpbar_decreasing;
        } else if (StrEqual(buffer, "2")) {
            boss_hpbarmodes[n_bosses] = hpbar_increasing;
            boss_bars[n_bosses] = boss_max_bars[n_bosses] - boss_bars[n_bosses];
        } else {
            boss_hpbarmodes[n_bosses] = hpbar_none;
        }

        kv.GetString("HP_mode", buffer, sizeof(buffer));
        if (StrEqual(buffer, "2")) {
            boss_hpmodes[n_bosses] = hp_increasing;
        }
        else {
            boss_hpmodes[n_bosses] = hp_decreasing;
        }

        boss_dead[n_bosses] = false;
        boss_ids[n_bosses] = -1; ++n_bosses;
    } while ( kv . GotoNextKey ());

    delete kv;
}

public void OnPluginStart() {
    HookEntityOutput("func_physbox", "OnHealthChanged", OnHealthChanged);
    HookEntityOutput("func_physbox_multiplayer", "OnHealthChanged", OnHealthChanged);
    HookEntityOutput("func_breakable", "OnHealthChanged", OnHealthChanged);
    HookEntityOutput("func_physbox", "OnBreak", OnBreak);
    HookEntityOutput("func_physbox_multiplayer", "OnBreak", OnBreak);
    HookEntityOutput("func_breakable", "OnBreak", OnBreak);
    HookEntityOutput("math_counter", "OutValue", OnCounter);

    damage_multiplier = CreateConVar("sm_boss_damage_reward", "1", "Multiplier for damage reward on bosses", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
    counter_reward = CreateConVar("sm_boss_counter_reward", "50", "Damage reward for bosses using math_counter", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);

    enable_cookie = RegClientCookie("bhud_enabled", "Enable boss HP HUD", CookieAccess_Public);

    HookEvent("round_start", HandleRoundStart, EventHookMode_PostNoCopy);

    CreateTimer(0.75, update_hud, _, TIMER_REPEAT);

    RegAdminCmd("sm_load_boss_file", SmLoadBossFile, ADMFLAG_CHANGEMAP);
    RegConsoleCmd("sm_bosshud", SmBhudEnable);

    for(int client = 1; client <= MaxClients; client++)
    {
    	if(IsClientInGame(client) && AreClientCookiesCached(client))
            ClientCookieUpdate(client);
    }
}

stock bool IsValidClient(int client) 
{
    if(!( 1 <= client <= MaxClients ) || !IsClientInGame(client)) 
        return false; 
    return true; 
} 

public Action SmBhudEnable(int client, int args) {
    if (AreClientCookiesCached(client)) {
        char cookie[256];
        GetClientCookie(client, enable_cookie, cookie, sizeof(cookie));
        if (StrEqual(cookie, "disabled")) {
            SetClientCookie(client, enable_cookie, "enabled");
            ReplyToCommand(client, "Enabled boss HUD");
            g_bBHudEnabled[client] = true;
        } else {
            SetClientCookie(client, enable_cookie, "disabled");
            ReplyToCommand(client, "Disabled boss HUD");
            g_bBHudEnabled[client] = false;
        }
    }
}

public void OnClientPutInServer(int client) {
	ClientCookieUpdate(client);
}

public void ClientCookieUpdate(int client) {
    char cookie[16];
    GetClientCookie(client, enable_cookie, cookie, sizeof(cookie));
    if (StrEqual(cookie, "disabled")) {
        g_bBHudEnabled[client] = false;
    } else {
        g_bBHudEnabled[client] = true;
    }
}

public void OnMapStart() {
    char mapname[256];
    GetCurrentMap(mapname, sizeof(mapname));
    LoadMapData(mapname);
}

public void HandleRoundStart(Handle ev, const char[] name, bool broadcast) {
    OnMapStart();
}

// Load alternate config (or manually reload current config)
public Action SmLoadBossFile(int client, int args) {
    if (args != 1) {
        ReplyToCommand(client, "Usage: sm_load_boss_file config_name");
    }

    char filename[256];
    GetCmdArg(1, filename, sizeof(filename));
    LoadMapData(filename);
    return Plugin_Handled;
}

public Action update_hud(Handle timer) {
    render_hud();
    return Plugin_Continue;
}

public void render_hud() {
    int boss = current_boss;
    char buffer[256];

    if (boss_dead[boss]) {
        if (GetTime() < boss_hit_time + BOSS_DEAD_HUD_TIMEOUT) {
            int one = 0, two = 0, three = 0;
            for(int i = 1; i <= MaxClients; i++) {
                if(boss_damage[i] > boss_damage[one]) {
                    three = two;
                    two = one;
                    one = i;
                }
                else if(boss_damage[i] > boss_damage[two]) {
                    three = two;
                    two = i;
                }
                else if(boss_damage[i] > boss_damage[three]) {
                    three = i;
                }
            }
            if(boss_showtopdmg) {
                Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font> has been killed", boss_names[boss]);
                if(one != 0 && boss_damage[one] > 5) {
                    StrCat(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#FF0000'>TOP BOSS DAMAGE:</font>");

                    char template[64];
                    Format(template, sizeof(template), "<br>1. %N - %d hits", one, boss_damage[one]);
                    StrCat(buffer, sizeof(buffer), template);

                    if(one != two && two != 0 && boss_damage[two] > 5) {
                        Format(template, sizeof(template), "<br>2. %N - %d hits", two, boss_damage[two]);
                        StrCat(buffer, sizeof(buffer), template);

                        if(two != three && three != 0 && boss_damage[three] > 5) {
                            Format(template, sizeof(template), "<br>3. %N - %d hits", three, boss_damage[three]);
                            StrCat(buffer, sizeof(buffer), template);
                        }
                    }
                }
            }
            else
                Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font> has been killed", boss_names[boss]);

        } else {
            strcopy(buffer, sizeof(buffer), "");
            for(int i = 0; i <= MaxClients; i++) {
                boss_damage[i] = 0;
            }
        }
    } 
    else if (GetTime() < boss_hit_time + BOSS_HUD_TIMEOUT) {
        if(boss_hpbar_force[boss] != 0) { // boss hp bar force (really should never be used)
            if(boss_hp[boss] > boss_starting_hp[boss])
                boss_starting_hp[boss] = boss_hp[boss];

            float percentLeft = boss_hp[boss]*1.0 / boss_starting_hp[boss];

            if(percentLeft > 100.0)
                percentLeft = 100.0;

            if(percentLeft < 0.0)
                Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font>: %d HP<font color=\"#00FFFF\"><br><font class='fontSize-xl' color='#FFFF00'>", boss_names[boss], boss_hp[boss]); 
            else
                Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font>: %d HP [%d%%]<font color=\"#00FFFF\"><br><font class='fontSize-xl' color='#FFFF00'>", boss_names[boss], boss_hp[boss], RoundFloat(percentLeft*100));

            new barCount = RoundToFloor(boss_hpbar_force[boss] * percentLeft);
            for(int i = 0; i < barCount; i++)
                StrCat(buffer, sizeof(buffer), "⚫");
            for(int i = 0; i < boss_hpbar_force[boss] - barCount; i++)
            	StrCat(buffer, sizeof(buffer), "⚪");

            StrCat(buffer, sizeof(buffer), "</font>");
        }
        else if (boss_hpbarmodes[boss] == hpbar_none)
        {
            if(boss_hp[boss] > boss_starting_hp[boss])
                boss_starting_hp[boss] = boss_hp[boss];

            new percentLeft = RoundFloat((boss_hp[boss]*1.0 / boss_starting_hp[boss])*100);

            if(percentLeft > 100)
                percentLeft = 100;

            if(percentLeft < 0)
                Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font>: %d HP", boss_names[boss], boss_hp[boss]);
            else
                Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font>: %d HP [%d%%%%]", boss_names[boss], boss_hp[boss], percentLeft);
        } 
        else
        {
            if (boss_bars[boss] == 0) {
                return;
            }

            new barsRemaining = boss_bars[boss]-1;
            if(barsRemaining < 0)
                barsRemaining = 0;

            char circleClass[32];
            if(boss_max_bars[boss] > 32)
                Format(circleClass, sizeof(circleClass), "fontSize-l");
            else
                Format(circleClass, sizeof(circleClass), "fontSize-xl");

            if(boss_init_hp[boss] != 0) {
                new totalHP = boss_hp[boss] + (barsRemaining * boss_init_hp[boss]);
                new percentLeft = RoundFloat((totalHP*1.0 / (boss_max_bars[boss] * boss_init_hp[boss])) * 100); 

                if(percentLeft > 100)
                    percentLeft = 100;

                if(percentLeft < 0)
                    Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font>: %d HP<font color=\"#00FFFF\"><br><font class='%s' color='#FFFF00'>", boss_names[boss], totalHP, circleClass);
                else
                    Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font>: %d HP [%d%%%%]<font color=\"#00FFFF\"><br><font class='%s' color='#FFFF00'>", boss_names[boss], totalHP, percentLeft, circleClass);
            }
            else {
                new totalHP = boss_hp[boss] + (barsRemaining * boss_highest_hp[boss]);

                if(totalHP > boss_starting_hp[boss])
                    boss_starting_hp[boss] = totalHP;

                new percentLeft = RoundFloat((totalHP*1.0 / boss_starting_hp[boss])*100);

                if(percentLeft > 100)
                    percentLeft = 100;

                if(percentLeft < 0)
                    Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font>: %d HP<font color=\"#00FFFF\"><br><font class='%s' color='#FFFF00'>", boss_names[boss], totalHP, circleClass);
                else
                    Format(buffer, sizeof(buffer), "<br><font class='fontSize-xl' color='#00FFFF'>%s</font>: %d HP [%d%%%%]<font color=\"#00FFFF\"><br><font class='%s' color='#FFFF00'>", boss_names[boss], totalHP, percentLeft, circleClass);
            }

            for (int j = 0; j < boss_bars[boss]; ++j) {
            	StrCat(buffer, sizeof(buffer), "⚫");
            }
            for (int j = 0; j < boss_max_bars[boss] - boss_bars[boss]; ++j) {
            	StrCat(buffer, sizeof(buffer), "⚪");
            }
            StrCat(buffer, sizeof(buffer), "</font>");
        }
    } else {
        strcopy(buffer, sizeof(buffer), "");
    }

    if (strlen(buffer) != 0) {
	    for(int client = 1; client <= MaxClients; client++) {
	        if (IsClientInGame(client) && g_bBHudEnabled[client]) {
	       	    PrintHintText(client, buffer);
	        }
	    }
	}
}

public int GetClientMoney(int client) {
	return GetEntProp(client, Prop_Send, "m_iAccount");
}
public void SetClientMoney(int client, int money) {
	SetEntProp(client, Prop_Send, "m_iAccount", money);
}
public void AddClientMoney(int client, int money) {
	SetClientMoney(client, GetClientMoney(client) + money);
}

/*
public void give_money(int player, int damage) {
    if (damage <0 || !IsValidClient(player)) {
        return;
    }

    float multiplier = GetConVarFloat(damage_multiplier);
    AddClientMoney(player, RoundToZero(float(damage) * multiplier))
}

public void give_money_counter(int player) {
    if (!IsValidClient(player)) {
        return;
    }
    int reward = GetConVarInt(counter_reward);
    AddClientMoney(player, reward);
}
*/

public void OnHealthChanged(const char[] output, int caller, int activator, float delay) {
    char szName[64];
    GetEntPropString(caller, Prop_Data, "m_iName", szName, sizeof(szName));
    int hp = GetEntProp(caller, Prop_Data, "m_iHealth");
    for (int i = 0; i < n_bosses; ++i) {
        if (StrEqual(boss_ents[i], szName)) {
            boss_hp[i] = hp;
            boss_ids[i] = caller;

            if(IsValidClient(activator)) {
                current_boss = i;
                boss_hit_time = GetTime();
                //give_money(activator, boss_hp[i] - hp);
                boss_damage[activator] += 1;
                
                if (boss_hpbarmodes[i] == hpbar_none && boss_hp[i] <= 0  && !boss_multboss) {
                    boss_dead[i] = true;
                }
            }

            return;
        }
    }
}

public int outvalue(int counter) {
    int offset = FindDataMapInfo(counter, "m_OutValue");
    if (offset < 0) {
        return 0;
    } else {
        return RoundFloat(GetEntDataFloat(counter, offset));
    }
}

public void OnCounter(const char[] output, int caller, int activator, float delay) {
    char szName[64];
    GetEntPropString(caller, Prop_Data, "m_iName", szName, sizeof(szName));
    for (int i = 0; i < n_bosses; ++i) {
        if (StrEqual(boss_ents[i], szName) && !boss_dead[i]) {
            boss_ids[i] = caller;
            int newHP = outvalue(caller);

            if(boss_hpmodes[i] == hp_increasing) {
                newHP = RoundFloat(GetEntPropFloat(caller, Prop_Data, "m_flMax")) - newHP; 
            }

            if(newHP > boss_hp[i])
            	boss_highest_hp[i] = newHP;

            boss_hp[i] = newHP;

            if(IsValidClient(activator)) {
                boss_damage[activator] += 1;

                AddClientMoney(activator, 20);
                current_boss = i;
                boss_hit_time = GetTime();
                if (boss_hpbarmodes[i] == hpbar_none && boss_hp[i] <= 0 && !boss_multboss) {
                    boss_dead[i] = true;
                }
               // bgive_money_counter(activator);
            }
        }

        if(StrEqual(boss_inithpents[i], szName) && !boss_dead[i]) {
            boss_init_hp[i] = outvalue(caller);
        }

        if (StrEqual(boss_hpents[i], szName) && !boss_dead[i]) {
            int count = outvalue(caller);
            if (boss_hpbarmodes[i] == hpbar_increasing) {
                count = boss_max_bars[i] - count;
            }

            if(IsValidClient(activator)) {
                if (count == 0  && !boss_multboss) {
                    boss_dead[i] = true;
                }

                boss_hit_time = GetTime();
                boss_bars[i] = count;
                current_boss = i;
            }
        }
    }
}

public void OnBreak(const char[] output, int caller, int activator, float delay) {
    for (int i = 0; i < n_bosses; ++i) {
        if (boss_ids[i] == caller && !boss_multboss) {
            boss_hp[i] = 0;
            boss_dead[i] = true;
        }
    }
}