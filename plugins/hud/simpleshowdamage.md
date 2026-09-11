# Show Damage [Multi methods] (simpleshowdamage)

**Version:** 2.0.1 · **Authors:** ZeddY^, TheBΦ$$♚#2967 (rewritten by Grey83), Strellic

## What it does

Shows each attacker how much damage they just dealt, in one of three styles the player can pick for themselves: floating "fortnite-style" particle damage numbers near the victim, a hint-text message (optionally including the victim's remaining HP), or synced HUD text in the corner of the screen. The chosen style is saved to a client cookie. Shotgun blasts are batched into a single combined number shortly after firing rather than showing one popup per pellet.

## Commands

- `sm_hits` — opens a menu letting the client pick their damage-display style (Fortnite / HintText / HUD / Disable).

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_show_damage_enable` | `1` | Master on/off switch |
| `sm_show_damage_mode` | `1` | `0` = damage only, `1` = damage + remaining HP (hint-text mode) |
| `sm_show_damage_hit_distance` | `50.0` | (CS:GO only) offset distance between the victim and the floating numbers |
| `sm_show_damage_fortnite_distance` | `-1` (disabled) | Distance past which floating numbers reposition near the attacker instead of the victim |
| `sm_show_damage_fortnite_distance_modifier` | `70 70 75` | Forward/right/up offset used for that repositioned display |

## Dependencies

`sourcemod`, `clientprefs`, `sdkhooks`, `sdktools_entinput`, `sdktools_functions`, `sdktools_stringtables`, and conditionally `sdktools_variant_t` on newer SourceMod builds. CS:GO or CS:Source only — the plugin calls `SetFailState` on any other engine. No ZombieReloaded dependency.

## Duplicate note

This repo contained two versions of this plugin, both v2.0.1: `SimpleShowDamage.sp` and `SimpleShowDamage - with_distance.sp`. This is the "with_distance" version, documented here because it adds the distance-modifier repositioning described above — in the plain version, damage numbers simply stop appearing entirely once the victim is farther away than `sm_show_damage_fortnite_distance`; this version instead repositions them near the attacker's own view so feedback stays visible at any range. It also fixes an inconsistency in the plain version, where the display-mode switch order in code didn't match its own cvar description text. Trade-off: this version drops the plain version's `sm_show_damage_default` cvar (a server-wide default display style for clients with no saved preference yet) and uses a different client-cookie name, so any previously saved per-client preference wouldn't carry over. The plain version is archived under `/legacy`.
