
/**
 * List of objective entities.
 */
#define ROUNDSTART_OBJECTIVE_ENTITIES "func_bomb_target|func_hostage_rescue|c4|hostage_entity"

bool g_bFirstRound = false;
bool g_bWarmup = false;

//Handle hHudSync = INVALID_HANDLE;

RoundStartOnMapStart()
{
    if(CS_GetTeamScore(CS_TEAM_CT) == 0 && CS_GetTeamScore(CS_TEAM_T) == 0)
        g_bFirstRound = true;
}

RoundStartOnMapEnd()
{
}

/**
 * Client is spawning into the game.
 * 
 * @param client    The client index.
 */
RoundStartOnClientSpawn(client)
{
    WarmupCheck();
    // If client hasn't spawned yet, then stop.
    if (!IsPlayerAlive(client))
    {
        return;
    }
}

int timeLeft = -1;

/**
 * The round is starting.
 */
RoundStartOnRoundStart()
{
    // Print round objective to all clients.
    
    // Kill all objective entities.
    RoundStartKillObjectives();
}

public void WarmupCheck()
{
    if(GetConVarFloat(g_hCvarsList[CVAR_WARMUP_DURATION]) != -1.0 && g_bFirstRound)
    {
        //hHudSync = CreateHudSynchronizer();

        g_bFirstRound = false;
        g_bWarmup = true;
        timeLeft = RoundToFloor(GetConVarFloat(g_hCvarsList[CVAR_WARMUP_DURATION]));

        CreateTimer(GetConVarFloat(g_hCvarsList[CVAR_WARMUP_DURATION]), Timer_EndWarmup, _, TIMER_FLAG_NO_MAPCHANGE);
        TriggerTimer(CreateTimer(1.0, Timer_Warmup, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT));
    }
}

// What happens after warmup? Who knows -.-
public Action Timer_EndWarmup(Handle timer)
{
    CS_SetTeamScore(CS_TEAM_CT, 0);
    CS_SetTeamScore(CS_TEAM_T, 0);

    // This is honestly the better implementation that should've been done
    //for(int i = 1; i <= MaxClients; i++)
   // {
    //    if(IsClientInGame(i))
   //     {
   //         ForcePlayerSuicide(i);
   //     }
   // }

    CS_TerminateRound(0.0, CSRoundEnd_Draw, false);
    g_bWarmup = false;

    // Move all clients to CT (yes that includes specs)
    // Honestly, this shit shouldn't be done because it lags the server, but we have no choice but to do so
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            CS_SwitchTeam(i, CS_TEAM_CT);
        }
    }
}

public Action Timer_Warmup(Handle timer)
{
    if(!g_bWarmup)
        return Plugin_Stop;

    timeLeft--;
    //SetHudTextParams(-1.0, 0.1, 1.0, 255, 0, 0, 255);

    int hours = RoundToFloor(timeLeft / 3600.0);
    int mins = RoundToFloor((timeLeft % 3600) / 60.0);
    int secs = timeLeft % 60;

    char szTimeFormat[64];
    if(hours > 0)
        Format(szTimeFormat, sizeof(szTimeFormat), "%d:%02d:%02d", hours, mins, secs);
    else
        Format(szTimeFormat, sizeof(szTimeFormat), "%d:%02d", mins, secs);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            //ShowSyncHudText(i, hHudSync, "Warmup %s", szTimeFormat);
            PrintHintText(i, "<font color='#FF0000' class='fontSize-l'>Warmup: </font><font color='#00FF00' class='fontSize-l'>%s</font> left<br>Killing everyone afterwards", szTimeFormat);
        }
    }
    return Plugin_Continue;
}

/**
 * Kills all objective entities.
 */
stock RoundStartKillObjectives()
{
    decl String:classname[64];
    
    // Get max entity count.
    new maxentities = GetMaxEntities();
    
    // x = entity index.
    for (new x = 0; x <= maxentities; x++)
    {
        // If entity isn't valid, then stop.
        if(!IsValidEdict(x))
        {
            continue;
        }
        
        // Get valid edict's classname.
        GetEdictClassname(x, classname, sizeof(classname));
        
        // Check if it matches any objective entities, then stop if it doesn't.
        if(StrContains(ROUNDSTART_OBJECTIVE_ENTITIES, classname) > -1)
        {
            // Entity is an objective, kill it.
            AcceptEntityInput(x, "Kill");
        }
    }
}
