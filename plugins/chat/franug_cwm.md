# SM FPVMI - Custom Weapons Menu

**Version:** 3.2 · **Authors:** Franc1sco franug, Romeo, Strellic

## What it does

Lets players pick a custom viewmodel/worldmodel/drop-model "skin" and equip sound for each weapon from a KeyValues-configured catalog, optionally gated per-skin by admin flag. Selections persist in a SQL database (MySQL or SQLite) keyed by SteamID and are applied automatically through the [FPVM interface](../hud/fpvm_interface.md) plugin.

## Commands

- `sm_cw` — console; opens the custom weapon menu.
- `sm_reloadcw` — admin (`ADMFLAG_ROOT`); reloads the KeyValues config and database connection.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_customweaponsmenu_spawnmsg` | `0` | Show a spawn-time chat reminder about the menu |

## Dependencies

`sdktools`, `sdkhooks`, this repo's [`fpvm_interface.sp`](../hud/fpvm_interface.md) (a **hard** dependency — must be loaded for model changes to actually apply), `multicolors` (chat-color library). Needs a SourceMod database entry (`databases.cfg`) and reads `configs/franug_cwm/configuration.txt` plus a `downloads.txt` fastdownload list.

## Notable

The most complex plugin in the chat/cosmetics group — a full async SQL layer, admin-gated cosmetic access, and custom per-weapon equip sounds via temp-entity hooks. Won't do anything useful without `fpvm_interface.sp` loaded alongside it.
