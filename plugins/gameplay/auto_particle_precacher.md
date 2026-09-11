# CS:GO Particle Auto-Precacher

**Version:** 1.2.4 · **Authors:** ZeddY^, Copypaste Slim

## What it does

On map start, looks for a manifest file at `maps/<mapname>_particles.txt` (KeyValues format) and precaches every particle system it lists — restoring the per-map particle manifest system that older Source titles had but CS:GO otherwise lacks. This matters for maps whose logic entities trigger custom particle effects that must be precached in advance or they won't play. Also exposes a manual admin command to precache a single particle path on demand.

## Commands

- `sm_precache_particles <path>` — admin (`ADMFLAG_ROOT`); precaches a single particle file immediately.

## ConVars

None.

## Dependencies

SourceMod core only. No ZombieReloaded dependency. The automatic per-map precaching only does something if the map ships a matching `_particles.txt` manifest.

## Notable

Debug/error output is commented out in the source, so a missing or malformed manifest fails silently rather than logging anything.
