# [ZR] Reserve Ammo Refill

**Version:** 1.0 · **Authors:** ZeddY^, Strellic

## What it does

Effectively removes reload scarcity. Whenever a player spawns with or equips a primary or secondary weapon, their reserve ammo is zeroed; then on every shot fired, if the clip isn't empty, one round is refunded to reserve. The net effect is that reloading always tops the clip back up from an ever-available "reserve," removing ammo management from the game.

## Commands

None.

## ConVars

None.

## Dependencies

`sdktools`, `sdkhooks`, `cstrike`. Despite the "[ZR]" tag in its name, it doesn't actually include or require ZombieReloaded — it's pure CS:GO weapon logic that would work on any CS:GO server.

## Notable

Minor code smell: the weapon-fire hook doesn't return an explicit action value, though this appears harmless for the hook type used.
