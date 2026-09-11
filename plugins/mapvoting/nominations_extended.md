# Map Nominations Extended

**Version:** 1.10.0 · **Author:** Powerlord/AlliedModders (adapted)

## What it does

Lets players nominate a map for the next vote via chat or menu, feeding [MapChooser Extended](mapchooser_extended.md)'s nomination pool. Adds a credits-economy layer on top of the stock plugin: non-VIP players spend in-game credits (via this repo's Store plugin) to nominate, VIP/admins with a custom flag nominate for free, and each player gets one nomination they can switch once. The menu shows status (current map, recently played, already nominated) pulled from MapChooser Extended's exclude list.

## Commands

- `sm_nominate` — console; opens the nomination menu, or nominates directly by name/partial match. Also triggered by typing "nominate" in chat.
- `sm_nominate_addmap <mapname>` — admin (`ADMFLAG_CHANGEMAP`); forces a map into the vote.

## ConVars

| CVar | Default | Purpose |
|---|---|---|
| `sm_nominate_excludeold` | `1` | Exclude recently-played maps |
| `sm_nominate_excludecurrent` | `1` | Exclude the current map |
| `sm_nominate_vip_perk` | `1` | Gate free nominations behind a VIP/admin flag |
| `sm_nominate_vip_price` | `50` | Credit cost for non-VIP players |
| `sm_nominate_players` | `0` | Minimum players online before nominations open |

## Dependencies

Its own `mapchooser` include, this repo's `mapchooser_extended` include, `colors_csgo`, and `store` (this repo's credits/economy plugin) — calls Store and MapChooser Extended natives directly with no fallback, so it requires both to be loaded.

## Notable

The source contains large blocks of commented-out legacy code (an older nomination command and a duplicate menu handler) left in alongside the active implementation — worth knowing about as known cruft rather than a second code path in use.
