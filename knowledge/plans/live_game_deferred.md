# Live game page: deferred

Plan: `[[live_game_plan]]`.

## 1. Analyze, Share, Play from here, Rematch do nothing

**Why deferred:** their targets don't exist: the analysis page is a stub with no route taking a
game or a position, and the challenge overlay has no prefilled entry point (`[[deferred]]` item 2).
The design's Share overlay (Position / Game link) depends on the former for its Position link.

**How to apply:** add an analysis route taking a game id and ply (or a SIP), then wire Analyze and
Share's Position link to it; Share's Game link is `live/<id>`. Play from here and Rematch open the
challenge overlay prefilled (rematch: same opponent, swapped colours, same time control, rated flag
and starting position).

## 2. Bot games

**Why deferred:** no bot engine exists (`[[deferred]]` item 1). The old page ran the bot locally and
showed a bot chat instead of the real one.

**How to apply:** once `client.botengine` exists, the page drives the bot's replies and swaps the
chat card for the bot's messages (as well as usual informational messages). This should be done via external games system.

## 7. HaxeFolio swallows page init errors

**Why deferred:** found in passing: an exception thrown from a page's `init` redirects to the default
page with nothing logged, which hides bugs.

**How to apply:** have `HaxeFolioApp.switchToPage` log the error (with its stack) before redirecting.

## 8. A failed re-sync goes unnoticed

**Why deferred:** once the game is shown, `load()` only re-syncs it (after missed events, a rejected
move, or a player's game ending). If that request fails or times out, the page keeps the stale state
and says nothing: the load status screen would cover the board, and nothing lighter exists yet.

**How to apply:** surface it without hiding the board (e.g. a notification with a retry), or retry
in the background.

## 9. Chameleon/Promotion button icons

Make them more clear. Moreover, clarify the chameleon's tooltip (it doesn't mention premoves)
