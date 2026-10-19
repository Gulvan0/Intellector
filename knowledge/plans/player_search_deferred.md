# Player search overlay: deferred

Plan: `[[player_search_plan]]`.

## 1. Other call sites

**Why deferred:** only Find player (Social → Player Profile) is in scope. The design also names
"Choose opponent" (challenge creation) and "Choose player to watch" (Watch → Watch Player, still a
stub in `Main.hx`).

**How to apply:** call `PlayerSearchOverlay.present` with the call site's title, `excludeOwn = true`
and its own `onPicked`. Watching needs the watch system first.

## 2. Rate limiting on `/player/search`

**Why deferred:** a separate initiative of the user's; the server has no rate limiting anywhere.

**How to apply:** general middleware rather than a search-specific guard. The client's 250 ms
debounce is not a throttle.

## 3. `LIKE` scans the whole player table

**Why deferred:** a substring `LIKE` can't use an index; the table is small enough today.

**How to apply:** if search gets slow, prefilter with an ngram FULLTEXT index (`WITH PARSER ngram`)
and keep the `CASE` ranking on the candidates. The server has no migrations, so the index needs an
idempotent DDL at startup.

## 4. Stale requests run to completion

**Why deferred:** decided: stale answers are ignored, not aborted.

**How to apply:** if it ever matters, add a cancellable request path to `http`'s provider and
`easyrest.RestClient` (the JS `HttpJs` already has `cancel()`), and cancel from `TimedLoad`.

## 5. Status and relation don't update live

**Why deferred:** as on the profile (`[[profile_deferred]]` item 2), statuses are read once per answer.

**How to apply:** follows the profile's fix.
