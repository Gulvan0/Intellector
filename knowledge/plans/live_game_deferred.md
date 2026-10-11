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
chat card for the bot's messages (as well as usual informational messages). E

## 4. External games

**Why deferred:** games uploaded by an external client (`external_uploader_ref`) are shown read-only
like a spectated game; the uploader's own controls (append ply, rollback, end) have no UI.

**How to apply:** if ever needed, a separate action set for the uploader.

## 5. Server changes not yet live locally

**Why deferred:** the local server must be restarted to pick up the rating snapshot, the outcome
deltas, `X-Server-Time` and the chat fix, and its DB needs the new nullable columns
(`game.white_elo`, `white_elo_provisional`, `black_elo`, `black_elo_provisional`,
`gameoutcome.white_elo_delta`, `black_elo_delta`). Until then the page shows no ratings and
estimates server time with the local clock.

**How to apply:** stop the server, add the columns (`ALTER TABLE ... ADD COLUMN ... NULL`), start it.
Then check ratings in the bars and info card, the rating line of the game-over notice, and sending
chat messages.

## 6. End-to-end checks not yet run

**Why deferred:** the browser window kept getting hidden during the session, and the server
restart is pending (item 5).

**How to apply:** premoves, timeout (`CHECK_TIMEOUT`), sending chat from the page, spectating a live
game (no requests, spectator chat hidden from players), a reload mid-game, presence dots of a
second open tab.

## 7. HaxeFolio swallows page init errors

**Why deferred:** found in passing: an exception thrown from a page's `init` redirects to the default
page with nothing logged, which hides bugs.

**How to apply:** have `HaxeFolioApp.switchToPage` log the error (with its stack) before redirecting.
