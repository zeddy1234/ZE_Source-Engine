# Spectate (spectate_zeddy)

**Version:** 1.0 · **Author:** Strellic

## What it does

Adds a `!spectate` command so living players can force-suicide and switch to spectator to watch a specific teammate, or free-spectate with no target. A server-wide switch lets admins disable spectating entirely, and a per-client cooldown blocks whichever player just became Mother Zombie from spectating for 2 minutes after infection (to stop early map-scouting). This version also caps the server to 2 concurrent non-privileged spectators, letting players with spectate privilege bypass the cap; the same limit and cooldown are enforced on direct `jointeam` attempts into the spectator slot, not just on the chat command.

## Commands

- `sm_spectate` / `sm_spec [target]` — spectate a specific player, or free-spectate with no argument.
- `sm_disablespec` — admin (`ADMFLAG_ROOT`); toggles the server-wide spectate switch.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_spec_allow_timer` | `120` | Seconds a Mother Zombie is blocked from spectating after infection |

## Dependencies

`sourcemod`, `sdktools`, `cstrike`, `zombiereloaded` (hooks `ZR_OnClientInfected` for the mother-zombie cooldown), `colors_csgo`.

## Duplicate note

This repo had two copies of this plugin, one at the repo root and one under `/store`, both "Spectate" v1.0 by Strellic. This store copy is documented here. The root copy added "EDIT by Detroid" to its author field and dropped the 2-spectator cap and privilege bypass — but it also has a compile-breaking bug: both `Command_Spectate` and its `jointeam` listener reference an undefined variable `i` (`IsPlayerAdmin(i)`) that doesn't exist in that function's scope. Despite the "EDIT" suggesting a newer revision, that file doesn't compile as committed, so it can't have been the version running on the live server. The root copy is archived under `/legacy`.
