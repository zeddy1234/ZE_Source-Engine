# ZCmds (zeddy_zcmds)

**Version:** 1.0 · **Author:** Strellic

## What it does

Adds purchasable abilities on top of ZombieReloaded's economy. Humans can buy temporary infinite reserve ammo, or a limited-use breach charge (a native CS:GO explosive placed in the C4 slot, retuned via cvars for damage/radius/burn duration, used to clear zombies out of a chokepoint). Zombies earn kill-streak-gated skills — a menu offering a temporary speed boost or temporary invisibility, unlocked once a zombie racks up enough kills, each usable once per life.

## Commands

- `sm_zammo` — buy temporary infinite reserve ammo (humans only, costs money, once per round).
- `sm_breachcharge` / `sm_breach` / `sm_charge` / `sm_bc` — buy a breach charge (humans only, costs money, limited uses per round).
- `sm_skill` / `sm_skills` — open the zombie skill menu (zombies only; it also pops up automatically once a kill threshold is reached).

## ConVars (selected)

| CVar | Default | Purpose |
|---|---|---|
| `sm_zcmds_zammo_cost` / `_duration` | `20000` / `10.0` | Cost and duration of `!zammo` |
| `sm_zcmds_zspeed_killcost` / `_duration` / `_zspeed` | `8` / `5.0` / `1.8` | Kills required, duration, and speed multiplier for the zombie speed skill |
| `sm_zcmds_zinvis_killcost` / `_duration` / `_amount` | `5` / `5.0` / `100` | Kills required, duration, and alpha (0–255) for the zombie invisibility skill |
| `sm_zcmds_breach_cost` / `_amount` / `_uses` | `20000` / `1` / `1` | Cost, ammo given, and per-round use limit for breach charges |
| `sm_zcmds_breach_duration` / `_damage` / `_radius` / `_volume` | `4.0` / `50.0` / `200.0` / `0.4` | Burn duration, damage multiplier, radius multiplier, and beep volume |
| `sm_zcmds_zammo_status` / `_zspeed_status` / `_zinvis_status` / `_breach_status` | `1` | Per-feature enable/disable switches |

## Dependencies

`sourcemod`, `cstrike`, `sdkhooks`, `sdktools`, `zombiereloaded` (required — hooks `ZR_OnClientInfected`, calls `ZR_IsClientHuman`/`ZR_IsClientZombie`), `colors_csgo`. Requires ZombieReloaded loaded.

## Duplicate note

This repo contained two copies, `zeddy_zcmds.sp` and `broken_zeddy_zcmds.sp`. The latter is confirmed non-functional, not just suspiciously named: its charge-explosion sound code references an undeclared variable (`g_fBreachVolumeUser`), which fails to compile as written. It also attempts a fuller breach-charge effect (a custom beam-ring explosion with per-target volume falloff) that this version doesn't have, but since it doesn't compile, it can't have been the version actually running. It's archived under `/legacy` as-is.
