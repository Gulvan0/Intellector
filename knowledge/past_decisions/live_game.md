# Live game page

Source design: the "Intellector game page" canvas (https://claude.ai/artifact/2RpJ51udqkotP3YA4AAHWN)

## Decisions

1. **Add time** is one button; the server adds its configured `secs_added_manually`. No picker bar.
2. **Online dots** mean "has this game open": the page subscribes to `SubscriberList(Game)` and
   lights a player's dot while their user ref is among the subscribers.
3. **Ratings** are the players' ratings at the game's start, never their current ones (server
   change below). Unrated games show them too; a player with no rating for that time control shows
   none. Provisional ratings get a `?` suffix.
4. **Analyze, Share, Play from here, Rematch** are shown but do nothing yet
   (`[[live_game_deferred]]` 1). Rematch: past games the user played.
5. **Action sets**: playing a live game: Flip, Offer draw / Cancel offer, Take back / Cancel
   request, Resign (Abort before both sides moved), Add time (timed games only). Watching a live
   game or any past game: Flip, Analyze, Share, Play from here (+ Rematch, decision 4).
   Offers follow the server's rules: draw from ply 2, takeback after the user's first move.
6. **Incoming offers** show as bars over the board's top edge (design `g-reqs`), with Decline /
   Accept. Resign / Abort asks for confirmation in the same kind of bar. An incoming draw offer
   disables Offer draw; an incoming takeback disables Take back.
7. **Game end**: resolution line updates, the action set switches to the past one, offer bars go,
   and an auto-expiring notice states the result (and the user's rating change, if rated).
8. **Clocks** show the time right after the shown ply. At the latest ply: a live game's clocks tick;
   a past game's show the time at the end. Below 60 s the clock turns danger-coloured. When the
   ticking clock reaches 0, the page calls `CHECK_TIMEOUT` once.
9. **Server time**: clocks extrapolate with a global server-time offset (`[[deferred]]` item 5),
   fed by an `X-Server-Time` header; the ongoing games widget switches to it too.
10. **Layout**: wide = three columns (312 px info + chat | board | 312 px moves + actions). Compact =
    HaxeFolio's collapsed breakpoint: header line, move strip, board with bars, action row, chat
    peek, Chat / Moves / Info tabs that open a sheet above the tabs.
11. **Chat**: newest at the bottom. Spectator messages are italic with a "spectator" tag. While the
    user plays an ongoing game, spectator messages are filtered out client-side too (`GET /game`
    returns them to everyone). Enter or Send posts; the input clears on success.
12. **Moves list** uses `PlyFormatter.toNotation`; clicking a move navigates to it. The opening name
    under the players comes from `client.openings.OpeningTree` (custom starting position: none).
13. **Navigation** keeps `followLatestMove` semantics through `PlyHistory`.
14. **Orientation**: the user's colour when playing, else White. Flip toggles it; player bars swap.
15. **Sounds** (`client.ui.Sounds`, the previous iteration's files): notify on opening an ongoing
    game and when it ends, move/capture on every new ply, low time once when the user's own clock
    drops below a minute (games starting with 90 s or more).
16. **Board policy**: `LiveGameMovePolicy` with premoves while playing at the latest ply;
    `InertMovePolicy` otherwise.
