# Pets

**Version:** not specified in source (Store item-handler module)

## What it does

A Store economy handler module, like [Hats](hats.md), that spawns a follower prop near the player as a purchasable cosmetic pet. It switches between idle and running animations based on the player's movement speed, and recreates the pet on spawn while cleaning it up on death, team change, or disconnect.

## Commands

None.

## ConVars

None.

## Dependencies

`store` (required), `sdktools`. Optionally integrates with a "hide" plugin if present. Reads per-item pet definitions (model, idle/run animation names, position, angles) from KeyValues config.

## Notable

Explicitly disables itself on Team Fortress 2. One animation-attachment string in the code (`"letthehungergamesbegin"`) looks like a leftover placeholder name from a previous author rather than a real attachment point.
