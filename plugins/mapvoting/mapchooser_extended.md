# MapChooser Extended

**Version:** 1.10.2 · **Authors:** Powerlord, Zuko, AlliedModders LLC

## What it does

A feature-rich superset of stock MapChooser: the same core end-of-map vote logic (time/round/frag/win-limit triggers, nominations, exclude/include lists, extend/don't-change/random options, runoffs), plus a pre-vote warning countdown, percentage-based vote start timing, an "official maps" list with a reload command, custom-map marking, randomized nomination order, a configurable vote-menu style, optional NativeVotes integration for native TF2/CS:GO vote UI, and game-specific round counting (MvM waves, Arms Race weapon progression, CS:GO intermission/phase handling).

## Commands

- `sm_mapvote` — admin (`ADMFLAG_CHANGEMAP`); force a vote (routed through the warning timer first).
- `sm_setnextmap <map>` — admin (`ADMFLAG_CHANGEMAP`).
- `mce_reload_maplist` — admin (`ADMFLAG_CHANGEMAP`); reloads the official maps list file.
- `sm_timeplayed` — console.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `mce_endvote` | `1` | Enable the end-of-map vote |
| `mce_starttime` | `10.0` min | When to trigger the vote |
| `mce_include` / `mce_exclude` | `6` / `5` | Maps shown / excluded |
| `mce_runoff` / `_runoffpercent` | `1` / `50` | Runoff-vote behavior |
| `mce_warningtime` | `15` s | Pre-vote countdown warning |
| `mce_menustyle` | `0` | Vote menu UI style |

## Dependencies

Its own `mapchooser` include, `nextmap`, `sdktools`, `colors_csgo`, and optionally `nativevotes` (soft dependency, only used if that plugin happens to be loaded).

## Relationship to MapChooser

This is documented as the likely-active map-vote engine in this repo. On load, it explicitly checks whether stock [MapChooser](mapchooser.md)'s library is already registered and aborts with "MapChooser already loaded, aborting" if so — it's a drop-in replacement, not a companion, registering the identical `mapchooser` library and native set. The two are mutually exclusive by design. This plugin is treated as primary here because it's the newer, actively-maintained superset, and because [`nominations_extended.sp`](nominations_extended.md) and [`rockthevote_extended.sp`](rockthevote_extended.md) in this repo call its specific natives (`CanNominate`, `GetExcludeMapList`, etc.) directly with no fallback to plain MapChooser. Plain `mapchooser.sp` is kept alongside it as the stock plugin it was built from — not archived, since the two aren't a confirmed duplicate pair, just mutually-exclusive alternatives.
