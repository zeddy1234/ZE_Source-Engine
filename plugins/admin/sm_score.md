# ScoreChanger

**Version:** 1.0 · **Author:** Strellic

## What it does

Lets an admin manually override the T (zombie) and CT (human) scoreboard scores, then re-applies that override at the start of each following round if the natural score would otherwise be lower — it only ever pushes a team's score up, never down.

## Commands

- `sm_score <ct|t> <value>` — admin (`ADMFLAG_BAN`); sets the given team's score and announces the change in chat.

## ConVars

None.

## Dependencies

`cstrike`, `sdktools`, `colors_csgo`. No ZombieReloaded dependency — works on any CS-based mode with team scores.

## Notable

The override resets to disabled on map start, so enforcement only applies within the same map after an admin has explicitly set a score.
