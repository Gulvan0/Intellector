# Deferred entries from the Profile search feature

See `[[profile_search_plan]]` for what's actually being built this pass: `GET /player/search`
(MySQL ngram FULLTEXT relevance ranking, tie-broken by games played then account age), a new
backward-compatible cancellation extension to `http`/`easyrest`, a new generic
`haxefolio.components.AutoComplete&lt;T&gt;`, and the Player Profile overlay wiring it all together.

## 1. Real avatar retrieval

**Why deferred:** explicit user instruction — a stub/placeholder avatar image ships this pass.
Also consistent with the wider state of the project: avatar upload is unimplemented server-side
(`POST /player/{login}/avatar` returns `501` today) and `Player` has no avatar column at all.

**How to apply:** once server-side avatar storage exists, `PlayerSearchResult` gains an avatar
field (URL or asset id) and `PlayerSearchResultRow` swaps the placeholder `Image` for it. No
other part of this feature's design should need to change.

## 2. Rate limiting on `/player/search`

**Why deferred:** explicit user instruction — tracked as the user's own separate initiative, not
scoped here.

**Existing state:** confirmed there is genuinely zero rate-limiting infrastructure anywhere in
`IntellectorServerV2` today (`src/main.py` only registers `CatchExceptionsMiddleware` and a
wide-open `CORSMiddleware`) — this isn't specific to search, so whatever gets built should probably
land as general middleware, not a search-specific guard.

**How to apply:** the minimum-query-length short-circuit (`ngram_token_size`, currently 2) already
in the plan is a mechanical floor, not a throttle — don't mistake it for rate limiting when this
item gets picked up.

## 3. Batched "best ranked stats" fetch

**Why deferred:** premature optimization at current scale. The plan fans out
`get_overall_ranked_game_stats` with `asyncio.gather` over the ≤`limit` (proposed 10) result rows
per search request — bounded, not linear in table size.

**How to apply:** if `limit` grows much larger, or search request volume gets high enough for the
per-row DB round-trips to matter, replace with a single batched query using window functions
(`ROW_NUMBER() OVER (PARTITION BY login, time_control_kind ORDER BY ts DESC)` to get latest-per-kind,
then a second pass approximating `RankedGameStats.is_better_than`'s tie-break order —
`ORDER BY is_provisional ASC, elo DESC, ranked_games_played DESC` per login). Needs MySQL 8+ window
function support (assumed available, not verified against the deployed server version).

## 4. Migration tooling for the FULLTEXT index

**Why deferred:** out of scope for a single feature. The server has no Alembic (or equivalent) —
schema comes entirely from `SQLModel.metadata.create_all` on startup — so the plan's `ALTER TABLE
... ADD FULLTEXT INDEX ... WITH PARSER ngram` has to be bootstrapped as a one-off idempotent raw DDL
statement alongside `create_all` in `net/core.py`, which is a workaround, not a fix.

**How to apply:** if/when the server adopts real migrations, move this index creation into that
system instead of the raw-DDL bootstrap.

## 5. "Watch Player" menu item

**Why deferred:** `Main.hx`'s `onWatchPlayerPressed` stub (the sibling of `onPlayerProfilePressed`,
same `[[menu_deferred]]` item 2) is not wired up by this pass. Unlike Player Profile (search →
navigate to the already-registered `player/{login}` route), Watch Player needs to find a *specific
player's current live game*, not just their profile — that's the `StartedPlayerGames` WS channel
already flagged as broken and unused in `[[home_page_deferred]]` ("Bugs found, not fixed this
pass": `StartedPlayerGamesStateRefresh`/`GameStarted` DTO mismatches).

**How to apply:** once that channel is fixed and wired to some page, Watch Player can likely reuse
the same `PlayerSearchOverlay`/`AutoComplete&lt;PlayerSearchResult&gt;` built here, just with a
different on-select action (look up the player's current game, navigate to `live/{gameID}` if one
exists, otherwise show some "not currently playing" state — that last part isn't designed at all
yet).

## 6. Keyboard accessibility

**Why deferred:** explicit user instruction — not needed for this feature. Noting it as a
deliberate scope decision (not an oversight) since every other list/search UI pattern in the
industry defaults to arrow-key navigation + Enter-to-select; if that expectation changes later,
`AutoComplete&lt;T&gt;` would need real key handling added (it has none today, mouse-click-only).

## 7. Match highlighting / richer result cards

**Why deferred:** never requested. Noting only because it's a common typeahead affordance (bolding
the matched substring within the nickname) that was consciously left out rather than forgotten, in
case it comes up later.
