# BossHUD-Modified (zeddy_bhud3)

**Version:** 3.1.1 · **Authors:** Strellic/AntiTeal (original), Koen (modifications)

## What it does

A more advanced boss-HP HUD than `zeddy_bhud2`, built around a per-boss `enum struct` (up to 64 tracked bosses at once). Supports decreasing or increasing HP-bar modes, a "force bars" display style, and an optional multi-boss cycling display (`MultBoss` config option) that rotates the HUD between several active bosses. Shows a top-damage leaderboard in chat and HUD text when a boss dies, gives every top contributor a personal "your damage" popup, and shows hitmarkers both for damaging a tracked boss/breakable and for zombies hitting human "item" props (detected via a ZombieReloaded zombie check on `player_hurt`). It also recalibrates its internal "highest HP seen" tracking on the fly, to smooth out inconsistent starting HP values between different boss configs. A fallback "simple HUD" shows the live HP of any breakable/counter a player damages, even without a boss config entry for it.

## Commands

- `sm_bosshud`, `sm_bosshmarker`, `sm_bosshitm`, `sm_bosshm`, `sm_bosshitmarker`, `sm_bhitmarker`, `sm_bhm`, `sm_bhud` — aliases that toggle the HUD and hitmarkers for the caller.
- `sm_currenthp`, `sm_subtracthp <hp>`, `sm_addhp <hp>` — admin (`ADMFLAG_GENERIC`); inspect/adjust the HP of the entity currently being tracked for that admin.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_bhud_updatetime` | `0.75` | HUD refresh interval |
| `sm_bhud_zombie_hitmarker_vmt` / `_vtf` | `overlays/AA/hitmarker_tiiko_boss.*` | Hitmarker shown to a zombie that hits a human item |
| `sm_bhud_boss_hitmarker_vmt` / `_vtf` | `overlays/AA/hitmarker_tiiko_zombie.*` | Hitmarker shown when damaging a boss/breakable |

## Dependencies

`sourcemod`, `sdktools`, `sdkhooks`, `clientprefs`, `zombiereloaded` (used only for the zombie-hit-marker detection), `colors_csgo`, and optionally the third-party `outputinfo` extension (soft dependency — marked optional via `MarkNativeAsOptional`, falls back to a raw entity-data read if the extension isn't loaded). Expects boss config files at `addons/sourcemod/configs/bosshud/<mapname>.txt`.

## Duplicate note

This repo contained two near-identical copies of this plugin (`zeddy_bhud3.sp` and `zeddy_bhud3_modified.sp`, both v3.1.1). This plain version is documented here rather than the "modified" one — the modified file's own description admits "(some missing) extended features," and a line-by-line diff confirms an actual regression: in `HUD_BossForceBars`, the modified copy collapses both circle-size branches to the same `fontSize-l` value, losing the size distinction this version keeps for large bar counts. The modified copy is archived under `/legacy`.
