# ZombieReloaded (vendored dependency)

This folder is a vendored copy of the ZombieReloaded SourceMod base mod — specifically the Franug edition fork:

**https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition**

It's third-party code, not something written for this server. It provides the underlying infection/survival game-mode framework — player classes, weapons, damage handling, admin tools, sound/visual effects, and map trigger volumes — that the plugins in [`/plugins`](../plugins) are built on top of. It's included here as-is because the top-level plugins depend on it to run, not as an example of this repo's own work, so individual `.inc` files aren't documented one by one.

The plugin that loads this framework is [`plugins/core/zombiereloaded.sp`](../plugins/core/zombiereloaded.md) (v3.4 Franug edition).

## Layout

Roughly 40 loose `.inc` files at the top level (cvars, config, damage, event, infection, logging, menus, models, etc.), plus five subsystem folders:

- `api/`
- `playerclasses/`
- `soundeffects/`
- `visualeffects/`
- `volfeatures/`

No README, license, or changelog ships with the vendored copy — the version string (`3.4 Franug edition`) and the upstream link both live in the loader plugin's `myinfo` block.

A stray backup file that was sitting in this folder (`infect.inc.bk`) has been moved to [`/legacy`](../legacy) along with the rest of this repo's archived/superseded files.
