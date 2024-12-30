/**
 * Delay between round ending and new round starting. (Normal)
 */
#define ROUNDEND_DELAY 5.0
 
/**
 * Possible round end outcomes.
 */
enum RoundEndOutcome
{
    Restart,        /** Round is restarting. */
    Draw,           /** Round has ended in unexpected way. */
    HumansWin,      /** Humans have killed all zombies. */
    ZombiesWin,     /** Zombies have infected all humans. */
}

/**
 * Global variable to store round win timer handle.
 */
new Handle:tRoundEnd = INVALID_HANDLE;

/**
 * Map is starting.
 */ 
RoundEndOnMapStart()
{
    // Reset timer handle.
    tRoundEnd = INVALID_HANDLE;
}

/**
 * Client has been killed.
 */
RoundEndOnClientDeath()
{
    // Terminate the round if the last player was killed.
    new RoundEndOutcome:outcome;
    if (RoundEndGetRoundStatus(outcome))
    {
        RoundEndTerminateRound(ROUNDEND_DELAY, outcome);
    }
}

/**
 * Client has been infected.
 */
RoundEndOnClientInfected()
{
    // Terminate the round if the last player was infected.
    new RoundEndOutcome:outcome;
    if (RoundEndGetRoundStatus(outcome))
    {
        RoundEndTerminateRound(ROUNDEND_DELAY, outcome);
    }
}

/**
 * The round is starting.
 */
RoundEndOnRoundStart()
{
    // Stop all overlays.
    RoundEndOverlayStop();
    
    // If round end timer is running, then kill it.
    if (tRoundEnd != INVALID_HANDLE)
    {
        // Kill timer.
        KillTimer(tRoundEnd);
        
        // Reset timer handle.
        tRoundEnd = INVALID_HANDLE;
    }
}

/**
 * The freeze time is ending.
 */
RoundEndOnRoundFreezeEnd()
{
    // Calculate round length, in seconds.
    // Get mp_roundtime. (in minutes)
    new Float:roundtime = GetConVarFloat(FindConVar("mp_roundtime"));
    
    // Convert to seconds.
    roundtime *= 60.0;
    
    // Subtract one second if running CS: GO to prevent round draw when round
    // ends. For some reason the timing doesn't match the actual round end.
    // Thanks to Jargon.
    if (g_Game == Game_CSGO)
    {
        roundtime--;
    }
    
    // Start timer.
    tRoundEnd = CreateTimer(roundtime, RoundEndTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * The round is ending.
 * 
 * @param winner    winner
 */
RoundEndOnRoundEnd(winner)
{
    // If round end timer is running, then kill it.
    if (tRoundEnd != INVALID_HANDLE)
    {
        // Kill timer.
        KillTimer(tRoundEnd);
        
        // Reset timer handle.
        tRoundEnd = INVALID_HANDLE;
    }
    
    // Tell plugin no zombies have been spawned.
    g_bZombieSpawned = false;
    
    // Update team scores.
    new teamscore;
    switch(winner)
    {
        // Zombies won the round.
        case CS_TEAM_T:
        {
            // Increment T score.
            teamscore = GetTeamScore(CS_TEAM_T);
            SetTeamScore(CS_TEAM_T, ++teamscore);
        }
        // Humans won the round.
        case CS_TEAM_CT:
        {
            // Increment CT score.
            teamscore = GetTeamScore(CS_TEAM_CT);
            SetTeamScore(CS_TEAM_CT, ++teamscore);
        }
    }
    
    // Display the overlay to all clients.
    RoundEndOverlayStart(winner);

    RoundEndDisplayStats();

    // Balance teams if enabled.
    if (GetConVarBool(g_hCvarsList[CVAR_ROUNDEND_BALANCE_TEAMS]))
    {
        RoundEndBalanceTeams();
    }
}

/**
 * Timer callback, called when round time reaches 0.
 *
 * @param timer     The timer handle.
 */
public Action:RoundEndTimer(Handle:timer)
{
    // Set the global timer handle variable to INVALID_HANDLE.
    tRoundEnd = INVALID_HANDLE;
    
    // If there aren't clients on both teams, then stop.
    if (!ZRTeamHasClients())
    {
        return;
    }
    
    // Terminate the round with humans as the winner.
    RoundEndTerminateRound(ROUNDEND_DELAY, HumansWin);
}

/**
 * Checks if the round is over.
 * 
 * @param outcome   Set to the outcome of the round, if round is over.
 * @return          True if the round is over, false otherwise.
 */
bool:RoundEndGetRoundStatus(&RoundEndOutcome:outcome)
{
    // If zombie hasn't spawned, then stop.
    // Commented out to see if this fixes the stupid issue with zombies not spawning
    //if (!g_bZombieSpawned)
    //{
    //    // Round isn't over.
    //    return false;
    //}

    // Initialize count variables
    new zombiecount;
    new humancount;

    // Count valid clients. (true to only allow living clients)
    ZRCountValidClients(zombiecount, humancount, true);

    // If there are no clients on either teams, then stop.
    if (!zombiecount && !humancount)
    {
        // Round isn't active.
        return false;
    }

    // If there are clients on both teams, then stop.
    if (zombiecount && humancount)
    {
        // Round isn't over.
        return false;
    }

    // We know here, that either zombiecount or humancount is 0. (not both)

    // If there are zombies, then zombies won the round.
    if (zombiecount)
    {
        outcome = ZombiesWin;
    }
    // If there are no zombies, that means there must be humans, they win the round.
    else
    {
        outcome = HumansWin;
    }

    // Round is over.
    return true;
}

/**
 * Ends the round with the given outcome and delay.
 * 
 * @param delay     Delay before new round starts. 
 * @param outcome   The outcome of the round.
 */
RoundEndTerminateRound(Float:delay, RoundEndOutcome:outcome = Restart)
{
    switch(outcome)
    {
        // Round is restarting.
        case Restart:
        {
            CS_TerminateRound(delay, CSRoundEnd_GameStart, false);
        }
        // Round was a draw.
        case Draw:
        {
            CS_TerminateRound(delay, CSRoundEnd_Draw, false);
        }
        // Zombies won.
        case ZombiesWin:
        {
            CS_TerminateRound(delay, CSRoundEnd_TerroristWin, false);
        }
        // Humans won.
        case HumansWin:
        {
            CS_TerminateRound(delay, CSRoundEnd_CTWin, false);
        }
    }
}

/**
 * Balances teams.
 */
RoundEndBalanceTeams()
{
    // Create eligible player list.
    new Handle:arrayEligibleClients = INVALID_HANDLE;
    new eligibleclients = ZRCreateEligibleClientList(arrayEligibleClients, true);
    
    // If there are no eligible client's then stop.
    if (!eligibleclients)
    {
        // Destroy handle.
        CloseHandle(arrayEligibleClients);
        
        return;
    }
    
    new client;
    
    // Move all clients to T
    
    // x = Array index.
    // client = client index.
    for (new x = 0; x < eligibleclients; x++)
    {
        // Get client stored in array index.
        client = GetArrayCell(arrayEligibleClients, x);
        
        // Switch client to T
        CS_SwitchTeam(client, CS_TEAM_T);
    }
    
    // Move every other client back to CT
    
    // x = array index
    // client = client index.
    for (new x = 0; x < eligibleclients; x += 2)
    {
        // Get client stored in array index.
        client = GetArrayCell(arrayEligibleClients, x);
        
        // Switch client to CT
        CS_SwitchTeam(client, CS_TEAM_CT);
    }
    
    // Destroy handle.
    CloseHandle(arrayEligibleClients);
}

/**
 * Displays overlays to clients, depending on the winner.
 * 
 * @param time     Time to display overlays.
 * @param winner   The winner of the round.
 */
RoundEndOverlayStart(winner)
{
    // If round end overlays are disabled, then stop.
    new bool:overlay = GetConVarBool(g_hCvarsList[CVAR_ROUNDEND_OVERLAY]);
    
    decl String:overlaypath[PLATFORM_MAX_PATH];
    char effectName[64];

    switch(winner)
    {
        // Show "zombies win" overlay.
        case CS_TEAM_T:
        {
            GetConVarString(g_hCvarsList[CVAR_ROUNDEND_OVERLAY_ZOMBIE], overlaypath, sizeof(overlaypath));
            GetConVarString(g_hCvarsList[CVAR_ROUNDEND_OVERLAY_PARTICLES_ZOMBIE], effectName, sizeof(effectName));
        }
        // Show "humans win" overlay.
        case CS_TEAM_CT:
        {
            GetConVarString(g_hCvarsList[CVAR_ROUNDEND_OVERLAY_HUMAN], overlaypath, sizeof(overlaypath));
            GetConVarString(g_hCvarsList[CVAR_ROUNDEND_OVERLAY_PARTICLES_HUMAN], effectName, sizeof(effectName));
        }
        // Show no overlay.
        default:
        {
            strcopy(overlaypath, sizeof(overlaypath), "");
            strcopy(effectName, sizeof(effectName), "");
        }
    }
    
    // x = client index.
    for (new x = 1; x <= MaxClients; x++)
    {
        // If client isn't in-game, then stop.
        if (!IsClientInGame(x))
        {
            continue;
        }
        
        // If client is fake (or bot), then stop.
        if (IsFakeClient(x))
        {
            continue;
        }
        
        if (overlay)
        {
            OverlaysClientSetChannelPath(x, OVERLAYS_CHANNEL_ROUNDEND, overlaypath);
            OverlaysClientSetChannelState(x, OVERLAYS_CHANNEL_ROUNDEND, true, false, true);
        }
    }

    if(g_bParticleOverlay)
        OverlaysRenderParticle(effectName);
}

RoundEndOverlayStop()
{
    // x = client index.
    for (new x = 1; x <= MaxClients; x++)
    {
        // If client isn't in-game, then stop.
        if (!IsClientInGame(x))
        {
            continue;
        }
        
        // If client is fake (or bot), then stop.
        if (IsFakeClient(x))
        {
            continue;
        }
        
        // Disable roundend overlay channel.
        OverlaysClientSetChannelState(x, OVERLAYS_CHANNEL_ROUNDEND, true, false, false, true);
    }
}

//=======
// ROUND END STATS
//=======
enum struct StatsArray
{
    bool bPlaying;
    char sPlayerID[8];
    char sPlayerName[MAX_NAME_LENGTH+2];
    char sPlayerAuth[24];
    char sPlayerState[8];
    char sPlayerTeam[8];
    char sPlayerPrint[255];
}

StatsArray iStatsArray[MAXPLAYERS+1];

void RoundEndDisplayStats()
{
    ArrayList prints = new ArrayList(255);
    for (int player = 1; player <= MaxClients; player++)
    {
        if (!IsClientInGame(player) || GetClientTeam(player) < CS_TEAM_T)
        {
            iStatsArray[player].bPlaying = false;
            continue;
        }

        iStatsArray[player].bPlaying = true;
        FormatEx(iStatsArray[player].sPlayerID, 8, "%d", GetClientUserId(player));
        FormatEx(iStatsArray[player].sPlayerName, MAX_NAME_LENGTH+2, "\"%N\"", player);

        if(!GetClientAuthId(player, AuthId_Steam2, iStatsArray[player].sPlayerAuth, 24))
            FormatEx(iStatsArray[player].sPlayerAuth, 24, "STEAM_ID_PENDING");

        if(IsPlayerAlive(player))
            FormatEx(iStatsArray[player].sPlayerState, 8, "Alive");
        else
            FormatEx(iStatsArray[player].sPlayerState, 8, "Dead");

        if(InfectIsClientInfected(player))
            FormatEx(iStatsArray[player].sPlayerTeam, 8, "Zombie");
        else
            FormatEx(iStatsArray[player].sPlayerTeam, 8, "Human");

        FormatEx(iStatsArray[player].sPlayerPrint, 255, "# %8.8s    %-40.40s    %-24.24s    %-5.5s    %-6.6s",
            iStatsArray[player].sPlayerID, iStatsArray[player].sPlayerName,
            iStatsArray[player].sPlayerAuth, iStatsArray[player].sPlayerState, iStatsArray[player].sPlayerTeam);

        prints.PushString(iStatsArray[player].sPlayerPrint);
    }
    PrintToConsoleAll("------------------------ [ZR] ZDG Round End Stats ------------------------");
    ArrayList arr = new ArrayList();
    arr.Push(0);
    arr.Push(prints);
    CreateTimer(0.1, Timer_SendStats, arr, TIMER_REPEAT);
}

public Action Timer_SendStats(Handle timer, ArrayList arr)
{
    int iCount = arr.Get(0);
    ArrayList prints = view_as<ArrayList>(arr.Get(1));
    char sPrint[255];
    for (int c = 0; c < 8; c++, iCount++)
    {
        if (iCount >= prints.Length)
        {
            delete prints;
            delete arr;
            PrintToConsoleAll("--------------------------------------------------------------------------");
            return Plugin_Stop;
        }
        else
        {
            prints.GetString(iCount, sPrint, sizeof(sPrint));
            PrintToConsoleAll(sPrint);
        }
    }
    arr.Set(0, iCount);
    return Plugin_Continue;
}
