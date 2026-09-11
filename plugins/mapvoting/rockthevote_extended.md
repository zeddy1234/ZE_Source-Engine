# Rock The Vote Extended

**Version:** 1.10.0 · **Author:** Powerlord/AlliedModders

## What it does

Lets players request an early map vote with `!rtv`. Once enough connected human players have voted (a configurable percentage), it triggers [MapChooser Extended](mapchooser_extended.md)'s vote — or, if an end-of-map vote already ran, changes to the already-decided next map after a short delay. Tracks per-client vote state across connects/disconnects and enforces cooldowns/delays around votes.

## Commands

- `sm_rtv` — console; casts an RTV vote. Also triggered by typing "rtv" or "rockthevote" in chat.
- `sm_forcertv`, `mce_forcertv` — admin (`ADMFLAG_CHANGEMAP`); force-starts the vote immediately.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_rtv_needed` | `0.60` | Fraction of players required |
| `sm_rtv_minplayers` | `0` | Minimum players before RTV is enabled |
| `sm_rtv_initialdelay` | `30.0` s | Delay after map start before RTV can be used |
| `sm_rtv_interval` | `240.0` s | Cooldown after a failed vote |
| `sm_rtv_changetime` | `0` | When to change map after success (0 instant / 1 round end / 2 map end) |
| `sm_rtv_postvoteaction` | `0` | Behavior once an end-of-map vote already finished |

## Dependencies

Its own `mapchooser` include, this repo's `mapchooser_extended` include, this repo's [`nextmap.sp`](nextmap.md), `colors_csgo`. Functionally requires MapChooser Extended to be loaded.

## Notable

A faithful RTV implementation with instant-change and post-vote-action logic layered on top of the stock plugin; generates its own `rtv.cfg` via `AutoExecConfig`.
