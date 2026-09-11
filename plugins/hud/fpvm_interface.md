# SM First Person View Models Interface (FPVMI)

**Version:** 3.1 · **Author:** Franc1sco franug

## What it does

A vendored third-party API plugin, not custom code written for this server, that lets other plugins assign a custom view model, world model, or drop model per weapon per client. It hooks weapon switch/equip/drop events, swaps the view model's model index, and patches known view-model animation glitches for specific weapons (knife, AK-47, MP7, AWP, Desert Eagle) that come from swapping models at runtime.

## Commands

None — it's a natives/forwards API for other plugins to call (`FPVMI_AddViewModelToClient`, `FPVMI_SetClientModel`, `FPVMI_GetClientViewModel`, and forwards like `FPVMI_OnClientViewModel`), not something with its own chat/console commands.

## ConVars

None beyond an informational `sm_fpvmi_version`.

## Dependencies

`sourcemod`, `sdktools`, `sdkhooks`, and `smlib` (an external SourceMod utility library — not vendored in this repo, must be present at compile time). Doesn't itself require ZombieReloaded, but this repo's [`franug_cwm.sp`](../chat/franug_cwm.md) custom-weapons-menu plugin has a hard dependency on it.

## Notable

Shares an author (Franc1sco franug) with the vendored ZombieReloaded fork in `/zr`, and functions the same way — infrastructure other plugins build on rather than a standalone feature. Its code mixes older and newer SourcePawn syntax, suggesting an older, ported codebase.
