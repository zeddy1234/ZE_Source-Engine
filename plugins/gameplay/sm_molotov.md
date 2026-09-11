# Molotov Command

**Version:** 1.0 · **Author:** Strellic

## What it does

Lets a living human (or any CT, if ZombieReloaded isn't loaded) buy one incendiary grenade per round via chat command, deducting the price directly from their in-game cash balance.

## Commands

- `sm_molo`, `sm_molotov`, `sm_molly` — console command (no admin flag); gives the grenade if the caller is alive, human/CT, hasn't already bought one this round, and can afford it.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_molotov_price` | `15000` | Cost of the grenade |

## Dependencies

`sdktools`, `cstrike`, and an optional soft dependency on `zombiereloaded` — detected at runtime via `LibraryExists`, so the plugin degrades gracefully to a CT-only version if ZombieReloaded isn't loaded rather than failing to compile.

## Notable

The per-round purchase limit resets on `round_start`; money is deducted by writing directly to the `m_iAccount` netprop rather than going through a store API.
