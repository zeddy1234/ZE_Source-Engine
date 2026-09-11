# Default Glove Blocker

**Version:** 0.2 · **Author:** UUZ

## What it does

Uses a low-level engine detour (via DHooks) on `PrecacheModel` to block the game from precaching the stock default glove/arm view models (`models/weapons/v_models/arms/*`). This is the standard technique for forcing a server's custom glove models to be used instead of the built-in ones.

## Commands

None.

## ConVars

None.

## Dependencies

`sdktools`, `sdkhooks`, `dhooks`. Requires a matching gamedata file (`default_glove_blocker.games.txt`) describing the engine interface, function signature, and virtual-table offset it hooks — without that file present, the plugin fails to load. No ZombieReloaded dependency.

## Notable

Inherently fragile: binary signature/offset-dependent code like this can silently go stale across game updates if the gamedata file isn't kept current. The plugin's `description` and `url` fields are left blank in the source.
