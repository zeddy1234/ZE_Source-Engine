# Nextmap

**Version:** tracks the SourceMod build (`SOURCEMOD_VERSION`) · **Author:** AlliedModders LLC

## What it does

Stock SourceMod plugin that tracks and advances the map cycle. It loads the configured `mapcyclefile`, finds the current map's position in it, and once the map has changed as expected, sets the following entry as the next map. It also tracks map history and start times for reporting. Other plugins in this repo ([Rock The Vote Extended](rockthevote_extended.md), the MapChooser family) depend on its API rather than the other way around.

## Commands

- `sm_maphistory` — admin (`ADMFLAG_CHANGEMAP`); prints recent maps played with duration and change reason.
- `listmaps` — console; prints the full map cycle.

## ConVars

None (reads the existing `mapcyclefile` cvar).

## Dependencies

SourceMod core, plus its own `nextmap.inc` API consumed by other plugins in this repo.

## Notable

Includes a compatibility guard that silently disables the plugin on non-CS/HL2-family games — irrelevant on this CS:GO server, but shows this is unmodified stock code.
