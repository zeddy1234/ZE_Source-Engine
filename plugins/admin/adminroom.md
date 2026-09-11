# AdminRoom

**Version:** 1.0 · **Authors:** ZeddY^, Strellic

## What it does

Gives admins a menu to teleport to a per-map "admin room" and to remotely trigger predefined `func_button` entities (for example, a level-change button), plus an in-chat setup wizard for admins with an elevated override to set the room location and add or remove buttons. Everything is persisted to a per-map config file.

## Commands

- `sm_adminroom`, `sm_ar` — admin (`ADMFLAG_BAN`); opens the AdminRoom menu (teleport / level buttons / settings).
- A further **Settings** menu (reload/delete config, add/delete a button) is gated behind a custom access override, `adminroom_settings`, falling back to `ADMFLAG_ROOT` if that override isn't configured.

## ConVars

`sm_adminroom_version` — informational only, not a behavior toggle.

## Dependencies

`sdktools`, `colors_csgo`. No ZombieReloaded dependency — works on any CS:GO map. Reads and writes per-map config at `addons/sourcemod/configs/adminrooms/<mapname>.cfg`.

## Notable

The "add button" flow captures raw chat text as an ad-hoc setup wizard (name → button → confirm), which could intercept an admin's normal chat mid-setup. Each map needs its own config built before the room/button features do anything.
