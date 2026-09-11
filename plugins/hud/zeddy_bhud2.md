# Configurable Zombie Escape Boss HUD (zeddy_bhud2)

**Version:** 1.10 · **Author:** Tanko

## What it does

Displays boss/breakable-entity health to all players during Zombie Escape boss fights. Reads a per-map boss configuration (KeyValues file at `addons/sourcemod/configs/bosshud/<mapname>.txt`) describing which entity to track, how HP bars should be counted, and display text. It tracks HP through entity outputs (`OnHealthChanged`, `OnBreak`) or `math_counter` `OutValue` outputs, then renders a HUD hint-text health readout (as a bar of filled/empty circles or a raw percentage) that decays a few seconds after the last hit. On a boss's death it shows a "top boss damage" leaderboard of the players who hit it hardest. Players who damage any tracked entity (or, via a fallback "simple HUD," any breakable/counter even without a boss config) also get a hitmarker overlay effect.

## Commands

- `sm_bosshud`, `sm_bhud`, `sm_bhm`, `sm_bosshm`, `sm_bosshmarker`, `sm_bosshitm`, `sm_bosshitmarker`, `sm_bhitmarker` — aliases that toggle the boss HUD and hitmarkers on/off for the calling client (saved to a client cookie).
- `sm_load_boss_file <config_name>` — admin (`ADMFLAG_CHANGEMAP`); manually (re)loads a named boss-HUD config.
- `sm_currenthp`, `sm_subtracthp <hp>`, `sm_addhp <hp>` — admin (`ADMFLAG_GENERIC`); inspect or adjust the HP of the entity the calling admin last damaged, useful for live-tuning a boss fight.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_bhud_updatetime` | `3` | How long the HUD keeps showing an entity's HP after the last hit |
| `sm_bhud_adminonly` | `0` | Restrict the HUD to admins only |
| `sm_bhud_zombie_hitmarker_vmt` / `_vtf` | `overlays/AA/hitmarker_tiiko_boss.*` | Hitmarker overlay shown to zombies who damage a "human item" prop |
| `sm_bhud_boss_hitmarker_vmt` / `_vtf` | `overlays/AA/hitmarker_tiiko_zombie.*` | Hitmarker overlay shown when damaging a boss/breakable |

## Dependencies

`sourcemod`, `sdktools`, `sdkhooks`, `clientprefs`, `zombiereloaded`, `colors_csgo`. Requires ZombieReloaded loaded, plus a per-map boss config file to do anything beyond the fallback simple HUD.

## Duplicate note

This repo contained two versions of this plugin with identical `myinfo` blocks: `zeddy_bhud.sp` and `zeddy_bhud2.sp` (both v1.10, both by Tanko). This one is documented here because it's a clear superset of the other — it adds hitmarkers, colored HTML output, the admin HP-adjustment commands, and the fallback "simple HUD" for entities with no boss config entry, none of which the plain version has. The plain version is archived under `/legacy`.
