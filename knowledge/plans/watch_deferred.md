# Watch system: deferred

Plan: `[[watch_plan]]`.

## The watched player's games ending

**Why deferred:** not designed; nothing is announced when a watched game ends.

**How to apply:** `OngoingGameEnded` on the watch subscription; dismiss that game's pending
announcement at least.
