# [ZR] Buy Commands

**Version:** 1.1 · **Author:** unattributed placeholder in source ("Someone, Modified by. Someone")

## What it does

A CS:GO-only buy-menu replacement for ZombieReloaded's human team. Chat/console commands let living humans purchase weapons, armor, and grenades directly with in-game money, with escalating "rebuy penalty" pricing on repeat purchases within a round, a cooldown between purchases, per-round caps on grenades and the Negev, and an option to auto-drop whatever weapon currently occupies that slot before giving the new one.

## Commands

One console command per weapon/item, open to all players (no admin flag) — covering most of CS:GO's catalog, e.g.: `sm_ak`, `sm_m4`/`sm_m4a1`, `sm_m4s`/`sm_m4a1s`, `sm_sg556`, `sm_galil`, `sm_famas`, `sm_aug`, `sm_awp`, `sm_ssg`/`sm_ssg08`, `sm_scar`, `sm_nova`, `sm_xm`, `sm_bizon`, `sm_p90`, `sm_mac10`, `sm_mp9`, `sm_mp7`, `sm_mp5`, `sm_ump`, `sm_m249`, `sm_negev`, `sm_usp`, `sm_glock`, `sm_p250`, `sm_deagle`, `sm_57`, `sm_cz`, `sm_r8`, `sm_elite`, `sm_tec9`, `sm_p2000`, `sm_kev`/`sm_kevlar` (armor + helmet), `sm_he`, `sm_fb`/`sm_flash`, `sm_de`/`sm_decoy`.

## ConVars

A price cvar per weapon (e.g. `sm_gc_ak_p` 2500, `sm_gc_awp_p` 4750, `sm_gc_kev_p` 1000, `sm_gc_he_p` 1000), plus:

| CVar | Default | Purpose |
|---|---|---|
| `sm_Cooltime` | `5` s | Cooldown between rebuys |
| `sm_rebuy_penalty` | `500` | Price added per repeat purchase in a round |
| `sm_SniperEnabled` | `0` | Gates AWP/SCAR/SSG08 purchases |
| `sm_gc_negev_amount` / `_he_amount` / `_flash_amount` / `_decoy_amount` | — | Per-round purchase caps |
| `sm_gc_dropprimary` / `sm_gc_dropsecondary` | `1` | Auto-drop the current weapon in that slot before giving the new one |

## Dependencies

`zombiereloaded` (required — gates purchases to `ZR_IsClientHuman`), `cstrike`, `sdkhooks`, `smlib`.

## Notable

Sets money and armor via raw memory offsets (`FindSendPropInfo`/`FindDataMapInfo`/`SetEntData`) rather than SourceMod's higher-level natives — functional, but more fragile against game updates than the alternative. A `#define DEBUG` flag is left enabled in the shipped source, and the author field is an unedited placeholder.
