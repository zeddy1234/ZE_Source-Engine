# ZE_Source-Engine

A collection of SourcePawn (SourceMod) plugins written and adapted for **ZeddY^ Gaming**'s CS:GO Zombie Escape (`ze_`) server. These are CS:GO-era plugins, published here for portfolio purposes rather than as active production code.

The server this ran on is no longer up. Where this repo contained two versions of the same plugin, both are noted below and in the plugin's own doc — the more complete/functional version (judged from the code itself) is documented as the one kept, and the other is preserved unmodified under [`/legacy`](legacy) rather than deleted.

## Plugins by category

### HUD

- [zeddy_bhud2](plugins/hud/zeddy_bhud2.md) — configurable boss/breakable health HUD with hitmarkers and admin HP tools
- [zeddy_bhud3](plugins/hud/zeddy_bhud3.md) — more advanced boss HUD with multi-boss cycling and per-boss HP-bar modes
- [bhud3_2](plugins/hud/bhud3_2.md) — earlier-generation boss HUD (game_text/center-text) with hit markers
- [countdownhud](plugins/hud/countdownhud.md) — server-driven countdown timer HUD
- [fpvm_interface](plugins/hud/fpvm_interface.md) — vendored API for per-weapon custom view models (third-party)
- [simpleshowdamage](plugins/hud/simpleshowdamage.md) — configurable floating/hint-text/HUD damage numbers

### Gameplay

- [ammo_refill](plugins/gameplay/ammo_refill.md) — effectively infinite reserve ammo
- [auto_particle_precacher](plugins/gameplay/auto_particle_precacher.md) — restores CS:GO's missing per-map particle manifest
- [default_glove_blocker](plugins/gameplay/default_glove_blocker.md) — blocks default glove models via engine detour
- [sm_molotov](plugins/gameplay/sm_molotov.md) — buyable incendiary grenade for humans
- [stopsounds_zeddy](plugins/gameplay/stopsounds_zeddy.md) — per-client weapon-sound preferences
- [zeddy_zcmds](plugins/gameplay/zeddy_zcmds.md) — purchasable human/zombie abilities (ammo, breach charges, speed, invisibility)

### Admin

- [adminroom](plugins/admin/adminroom.md) — teleport to a per-map admin room and trigger level buttons
- [sm_score](plugins/admin/sm_score.md) — manually set/override team scores

### Map voting

- [mapchooser](plugins/mapvoting/mapchooser.md) — stock end-of-map voting (alternative to mapchooser_extended)
- [mapchooser_extended](plugins/mapvoting/mapchooser_extended.md) — feature-rich end-of-map voting (likely the active engine)
- [nextmap](plugins/mapvoting/nextmap.md) — map-cycle tracking/advancement
- [nominations_extended](plugins/mapvoting/nominations_extended.md) — map nominations with a credits cost
- [rockthevote_extended](plugins/mapvoting/rockthevote_extended.md) — player-triggered early map vote (`!rtv`)

### Chat & cosmetics

- [saycolor](plugins/chat/saycolor.md) — colorizes server-console chat announcements
- [franug-colors](plugins/chat/franug-colors.md) — player model color picker
- [franug_cwm](plugins/chat/franug_cwm.md) — custom per-weapon model/sound picker (needs fpvm_interface)

### Store (in-game shop)

- [hats](plugins/store/hats.md) — cosmetic hat handler for the Store framework
- [pets](plugins/store/pets.md) — cosmetic pet handler for the Store framework
- [sm_buycommands2](plugins/store/sm_buycommands2.md) — full buy-menu replacement for ZombieReloaded humans
- [spectate_zeddy](plugins/store/spectate_zeddy.md) — `!spectate` command with a spectator cap and mother-zombie cooldown

### Core / vendored framework

- [zombiereloaded](plugins/core/zombiereloaded.md) — loader plugin for the vendored ZombieReloaded framework
- [`/zr`](zr/README.md) — the vendored ZombieReloaded (Franug edition) framework itself; third-party code, not documented file-by-file

## Legacy / archived

[`/legacy`](legacy) holds superseded or non-functional duplicates found during cleanup, kept for reference rather than deleted:

- `zeddy_bhud.sp` — superseded by `zeddy_bhud2.sp`
- `zeddy_bhud3_modified.sp` — a regressed copy of `zeddy_bhud3.sp` (its own description admits missing features, confirmed by a code diff)
- `bhud_redux.sp` — superseded by `bhud3_2.sp`
- `broken_zeddy_zcmds.sp` — doesn't compile (references an undeclared variable); superseded by `zeddy_zcmds.sp`
- `spectate_zeddy.sp` — the repo-root copy; doesn't compile (references an undefined variable) despite looking like the newer edit; superseded by `plugins/store/spectate_zeddy.sp`
- `SimpleShowDamage.sp` — superseded by `plugins/hud/simpleshowdamage.sp` ("with_distance" version)
- `compile.dat` — a leftover local SourceMod compiler cache, not project content
- `zr_infect.inc.bk` — a backup file from inside the vendored ZombieReloaded framework

No one currently involved with this repo can confirm which side of each duplicate pair was actually running on the live server — the git history doesn't help either, since almost everything landed in a single bulk import. Each call above was made by reading the code itself (feature completeness, version comments, and in two cases, an outright compile error), not from guessing based on filenames.
