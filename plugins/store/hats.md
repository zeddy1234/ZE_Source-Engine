# Hats

**Version:** not specified in source (Store item-handler module)

## What it does

A handler module for this repo's Store economy framework — not a standalone plugin, it registers itself via `Store_RegisterHandler` — that lets players wear cosmetic hats attached to their player model. Hats are positioned and angled per-item from a KeyValues config, optionally bone-merged, hidden from the wearer's own first-person view, automatically re-equipped on spawn, and removed on death or team change. If a player's current model can't support the hat attachment, the plugin can force-swap them to a hat-compatible default model.

## Commands

None — a passive Store handler with no chat/console commands of its own.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_store_hats_default_t` | `models/player/t_leet.mdl` | Fallback T model that supports hats |
| `sm_store_hats_default_ct` | `models/player/ct_urban.mdl` | Fallback CT model |
| `sm_store_hats_skin_override` | `0` | Force-override a player's model if it can't support hats |

## Dependencies

`store` (required — this repo's economy framework), `sdktools`, and a `store.gamedata` file for an SDK signature lookup. Optionally integrates with a separate "hide" plugin if present, for hiding hats in first-person. Reads per-item hat definitions (model, position, angles, attachment point, team, slot) from KeyValues config.

## Notable

Explicitly disables itself on Team Fortress 2. Requires the Store framework to be loaded to do anything, since it's a handler rather than a standalone plugin.
