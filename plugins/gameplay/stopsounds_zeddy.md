# Stop Weapon Sounds

**Version:** 1.0 · **Author:** GoD-Tony

## What it does

Lets each client choose, via a preference menu (also reachable from SourceMod's built-in client-settings cookie menu), whether to hear other players' weapon sounds normally, not at all, or replaced with a quiet "silenced" sound. Shotgun sounds are handled separately via temp-entity interception. A player who is spectating someone still hears that person's real weapon sounds regardless of their own preference.

## Commands

- `sm_stopsound`, `sm_stopsounds` — console command (no admin flag); opens the preference menu (Disable / Stop Sound / Silencer Sound).

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_stopsounds_silencer_volume` | `0.5` (range 0.0–1.0) | Volume used for the replacement "silenced" sound |

## Dependencies

`sdktools`, `clientprefs`, `colors_csgo`. No ZombieReloaded dependency — standalone.

## Notable

Preference persists via a client cookie, defaulting new/uncached clients to the "silenced" option. Implementation is fairly low-level: direct sound-hook client-list manipulation and temp-entity re-broadcasting for shotguns.
