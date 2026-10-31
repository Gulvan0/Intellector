# Bot games: deferred

Plan: `[[bot_games_plan]]`.

## Weakness

**Why deferred:** the engine is still being refined; how weakness weakens the search isn't designed.

**How to apply:** `HxcondaEngine.searchByDepth` already takes `weakness` (centiprogressors, strength
1..9 → 200..0 in steps of 25) and passes it to the worker; apply it inside the search, measured
the way `[[hxconda_improvement_plan]]` prescribes.

## Bot styles

**Why deferred:** same as weakness; the five styles exist only as names and descriptions.

**How to apply:** `HxcondaStyle` is already passed with every search; make the evaluation depend on
it (Trailblazer: progressor advance and Intellector march; Vrezh: checks and sacrifices; Fortress:
defended pieces; Unchained: trades and long-range mobility).

## Leaving during the bot's turn

**Why deferred:** accepted for now. In a timed game, if no tab is computing (the user closed the tab or
reloaded without reopening the game), the server keeps the bot's clock running and flags it, so the
user wins on time. Unrated, so exploitable but harmless. Part of the wider "long disconnects" topic.

**How to apply:** e.g. external clocks pause while no uploader is connected (server-side timeout
handling), or the bot side gets a bounded clock credit on resume.

## Thinking progress display

**Why deferred:** not designed.

**How to apply:** `BotMoveSearch` already receives `onDepthReached`; show it on the game page (e.g.
in the bot's player bar), never as chat messages.
