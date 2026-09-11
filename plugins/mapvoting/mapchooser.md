# MapChooser

**Version:** tracks the SourceMod build (`SOURCEMOD_VERSION`) · **Authors:** AlliedModders LLC & Strellic

## What it does

The stock AlliedModders end-of-map voting plugin, with light CS:GO-flavored additions (colored chat, a time-played command, timed warnings at 10/5/1 minutes). It tracks time, rounds, win-limit, and frag-limit remaining, and once a threshold is crossed it opens a vote menu built from player nominations plus randomly-picked maps (excluding the N most recently played). Supports "Extend Map" and "Don't Change" options, an optional runoff vote if no map wins by a set margin, and a random pick if nobody votes. It persists recently-played maps across map changes and exposes the `mapchooser` native API and library that other plugins in this repo (nominations, RTV) build on.

## Commands

- `sm_mapvote` — admin (`ADMFLAG_CHANGEMAP`); force-starts a map vote now.
- `sm_setnextmap <map>` — admin (`ADMFLAG_CHANGEMAP`); manually sets next map.
- `sm_timeplayed` — console; prints time elapsed on the current map.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_mapvote_endvote` | `1` | Enable the end-of-map vote |
| `sm_mapvote_start` | `3.0` min | When to trigger the vote |
| `sm_mapvote_exclude` | `5` | Maps excluded from the vote (recently played) |
| `sm_mapvote_include` | `6` | Maps shown in the vote |
| `sm_mapvote_extend` | `0` | Map extensions allowed |
| `sm_mapvote_runoff` / `_runoffpercent` | `0` / `50` | Runoff-vote behavior |

## Dependencies

Its own `mapchooser` include, `nextmap` (this repo's [nextmap.sp](nextmap.md)), `colors_csgo`.

## Relationship to MapChooser Extended

`mapchooser.sp` and [`mapchooser_extended.sp`](mapchooser_extended.md) are **alternatives, not companions** — they register the same `mapchooser` library name and native set, and MapChooser Extended explicitly refuses to load if it detects this plugin is already running. Only one could have been active on the live server; MapChooser Extended is documented as the likely primary engine since the nominations/RTV plugins in this repo call its specific natives directly, but both are kept here (not archived) since they aren't a confirmed duplicate pair, just mutually-exclusive alternatives.
