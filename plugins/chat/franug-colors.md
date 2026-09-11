# SM Franug Player Colors

**Version:** 1.3 · **Author:** Franc1sco franug

## What it does

Lets human players pick a custom render color for their player model from a 26-color palette via a menu, saved per-player to a client cookie and reapplied after spawning, taking damage, or an infection/humanize event. Only applies to living humans — zombies aren't recolored.

## Commands

- `sm_colors` — console; opens the color-picker menu. Picking a color applies it immediately and reopens the menu.

## ConVars

`sm_fcolors_version` — informational only. The plugin also force-sets the unrelated `sv_disable_immunity_alpha` cvar to `1` if it's present.

## Dependencies

`sdktools`, `clientprefs`, and `zombiereloaded` as a soft/optional include (compiles without it, but needs ZombieReloaded loaded at runtime for `ZR_IsClientHuman` and its infection forwards to actually work). Requires a `franug_colors.phrases` translation file.

## Notable

Written in older, legacy SourcePawn syntax (`public Plugin:myinfo`, `Handle:` declarations) unlike most other plugins in this repo — an older, unmigrated codebase, consistent with its shared authorship with the vendored ZombieReloaded fork in `/zr`.
