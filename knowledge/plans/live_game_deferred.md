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

## 10. First-move deadline isn't shown

**Why deferred:** the server aborts a timed game when the side to move doesn't make white's first or
black's first move within 30 s (5 min for external games); the page doesn't show this countdown.

**How to apply:** while fewer than two plies are made, show the side to move how long they have left
before the abort, counted from the game start, the first ply, or a rollback into the first two plies.

## 11. No abandonment claim

**Why deferred:** explicit decision. Once both sides have moved, a disconnected player's game goes on
until their clock runs out; nothing shortens that, and correspondence games never end this way.

**How to apply:** server-side, after the opponent has been disconnected for some time, let the other
player claim the win (`OutcomeKind.ABANDON`), plus the page's prompt to do so.
