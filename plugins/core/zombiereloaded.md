# Zombie:Reloaded (loader)

**Version:** 3.4 Franug edition · **Authors:** Greyscale | Richard Helgeby, Franc1sco franug, and Strellic

## What it does

The loader/core plugin for the vendored ZombieReloaded framework in [`/zr`](../../zr/README.md). It doesn't implement game logic directly — it `#include`s roughly 40 module files from `/zr` (cvars, config, player classes, weapons, infection, damage, admin tools, sound/visual effects, spawn protection, knockback, map trigger volumes, an API layer) and wires SourceMod's standard forwards (`OnPluginStart`, `OnMapStart`, `OnClientPutInServer`, `OnClientDisconnect`, `OnConfigsExecuted`, etc.) to each module's init/load functions — effectively booting the entire zombie-infection game mode on top of CS:GO.

## Commands (representative — the full module set registers many more)

- `zr_infect` / `zr_human` — admin; force-infect or humanize a player
- `zclass` / `zmenu` — chat keywords; open the class-selection menu / ZR's main menu
- `zr_hitgroup*` — hitgroup damage configuration
- `zr_class_modify` / `zr_class_reload` — live class-attribute tuning
- `zr_config_reload` / `zr_config_reloadall` — reload config files
- `zr_version` — print the running plugin version

## ConVars (representative — dozens exist across the module set)

| CVar | Default | Purpose |
|---|---|---|
| `zr_log` | `1` | Enable event logging |
| `zr_classes_random` | `0` | Random class every spawn |
| `zr_classes_zombie_select` / `zr_classes_human_select` | `1` | Allow players to pick their class |
| `zr_classes_default_zombie` | `"random"` | Default zombie class |
| `zr_weapons` | `1` | Master switch for the weapons module |
| `zr_weapons_restrict` | `1` | Enable weapon restriction system |
| `zr_weapons_zmarket` | `1` | Enable the in-game weapon shop |
| `zr_permissions_use_groups` | `0` | Group-based vs. flag-based admin permissions |

## Dependencies

`sourcemod`, `sdktools`, `clientprefs`, `cstrike`, `emitsoundany`, `colors_csgo`, and either `sdkhooks` or the legacy `zrtools` extension (chosen at compile time via a `USE_SDKHOOKS` toggle). Requires every module file under `/zr` to be present to compile.

## Notable

Keeps a compile-time switch between the modern SDKHooks extension and a legacy ZRTools extension for the same action-return macros — a portability shim left over from the mod's original Half-Life 2 era. It also carries a vestigial Mercurial-based version-info hook from before the project moved to Git.
