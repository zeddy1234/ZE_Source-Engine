# BossHud + Hit Markers (bhud3_2)

**Version:** 2.4.3 · **Authors:** ZeddY^, AntiTeal, Cruze

## What it does

An earlier-generation boss-HP HUD than the `zeddy_bhud*` family, shown via `game_text` or center-text (configurable) rather than hint-text, with position/color/display-type/HUD-channel all tunable via cvars. Adds a hitmarker overlay both when a player damages a tracked boss/breakable/`math_counter`, and when a player damages a zombie (detected via ZombieReloaded). Per-client on/off state is saved to a client cookie, and the HUD can optionally be restricted to admins only.

## Commands

- `sm_bhud`, `sm_bhm`, `sm_bosshm`, `sm_bosshitm`, `sm_bosshmarker`, `sm_bosshitmarker`, `sm_bhitmarker` — aliases that toggle the HUD and hitmarkers for the caller.
- `sm_currenthp`, `sm_subtracthp <hp>`, `sm_addhp <hp>` — admin (`ADMFLAG_GENERIC`); inspect/adjust the currently tracked entity's HP.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_bhud_position` | `-1.0 0.09` | HUD X/Y position |
| `sm_bhud_color` | `255 0 0` | HUD text RGB color |
| `sm_bhud_symbols` | `1` | Wrap HUD text in `>>`/`<<` |
| `sm_bhud_updatetime` | `3` | How long the HUD keeps showing HP after the last hit |
| `sm_bhud_displaytype` | `0` | `0` = `game_text`, `1` = center text |
| `sm_bhud_adminonly` | `0` | Restrict the HUD to admins only |
| `sm_bhud_zombie_hitmarker_vmt` / `_vtf` | `overlays/AA/hitmarker_AA_blue.*` | Hitmarker shown when hitting a zombie |
| `sm_bhud_boss_hitmarker_vmt` / `_vtf` | `overlays/ragehitmarker/hitmarker2.*` | Hitmarker shown when damaging a boss/breakable |
| `sm_bhud_hudchannel` | `4` | HUD text channel used for `ShowHudText` |

## Dependencies

`sourcemod`, `sdktools`, `sdkhooks`, `clientprefs`, `zombiereloaded` (used for zombie-hit detection driving the hitmarker-on-zombie-hit feature).

## Duplicate note

This repo contained an earlier plugin in the same family, `bhud_redux.sp` (v2.4, same authors minus Cruze — "BossHud" without hit markers). This file (`bhud3_2.sp`, "BossHud + Hit Markers," v2.4.3) is documented here because it's `bhud_redux` plus the full hitmarker system, a more robust admin-check retry loop for cookie loading, and the HUD-channel cvar. `bhud_redux.sp` is archived under `/legacy`.
