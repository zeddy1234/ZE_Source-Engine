# SayColor

**Version:** 1.0 · **Author:** Strellic

## What it does

Intercepts `say` messages sent from the server console — an RCON or admin console announcement — and rebroadcasts them to all players wrapped in colored decoration (`+++ message +++` in green/red) instead of the plain default. Player-typed chat passes through unaffected.

## Commands

None — a listener on the existing `say` command, not a new command.

## ConVars

None.

## Dependencies

`sdktools`, `colors_csgo` (chat-color library, required to compile). No ZombieReloaded dependency.

## Notable

A small utility plugin (~34 lines).
