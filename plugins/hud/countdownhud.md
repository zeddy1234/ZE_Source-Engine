# Countdown HUD

**Version:** 1.6 · **Authors:** ZeddY^, AntiTeal

## What it does

Listens for `say` input issued from the server console (not player chat) containing a number followed by `s`/`sec` (e.g. `30s`, `10 sec`) or a bare number, and displays a shrinking countdown in a synced HUD text box to all in-game players, clearing it at zero. It's meant to be driven by server or map logic (e.g. a `logic_*` entity firing `sm_say 30s`) to announce timed events or ability cooldowns — it filters out messages containing "recharge", "recast", "cooldown", or "cool" so it doesn't re-trigger on related chat.

## Commands

None — it hooks the existing `say` command via `AddCommandListener` rather than registering its own.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_cdhud_position` | `-1.0 0.125` | HUD X/Y position |
| `sm_cdhud_color` | `0 255 0` | HUD text RGB color |
| `sm_cdhud_symbols` | `1` | Wrap the countdown in `>>`/`<<` |

## Dependencies

`sourcemod`, `sdktools`. No ZombieReloaded dependency.

## Notable

Only fires on input from the server console (client index 0) — a player typing "30s" in chat won't trigger it. It's designed to be driven by map or server-side logic, not typed directly by players.
