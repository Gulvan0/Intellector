# Profile search (search-as-you-type "find a player") plan

A new feature, not a port — the old frontend never had player search
(`C:/Users/mitmi/Documents/GitHub/Intellector/src/gfx` has no matching screen/component). Discussed
and scoped with the user first; see `[[profile_search_deferred]]` for what's explicitly cut.

**Confirmed scope:** a global "find a player" search box, imprecise (substring) matching, results
sorted by match quality, MySQL-backed, no keyboard a11y needed. It resolves the still-open half of
`[[menu_deferred]]` item 2 (`onPlayerProfilePressed` in `Main.hx` — previously a plain
`Dialogs.prompt` login-input, currently a no-op stub) by giving it a real overlay to open. The
sibling stub `onWatchPlayerPressed` is **not** wired up by this pass — see deferred doc.

## Backend (`IntellectorServerV2`)

### New endpoint

`GET /player/search?q=&limit=` in `player/routes.py`, following the existing flat-list/
`offset`+`limit` convention (`/challenge/public`, `/player/{login}/followers`) minus `offset` — a
typeahead box doesn't paginate, the user just retypes to refine.

### Matching &amp; ranking — one query does the sortable part

MySQL has no `pg_trgm`; the equivalent for indexed, scalable substring matching with a built-in
relevance score is an **n-gram FULLTEXT index**:

```sql
ALTER TABLE player ADD FULLTEXT INDEX ft_nickname (nickname) WITH PARSER ngram;
```

Boolean mode (not natural-language mode) is required — natural-language mode silently drops any
term appearing in &gt;50% of rows, a real risk on a small nickname table. `MATCH()` returns a
relevance float usable directly in `ORDER BY`, no hand-rolled scoring `CASE`.

Per the user's tie-break rule (relevance, then games played, then newer account), games-count and
`joined_at` must be **in the same query**, before `LIMIT` truncates — not computed after the fact
on a possibly-wrong candidate set. Games count is a simple correlated subquery (same shape as
`game/methods/get.py:get_overall_player_game_counts`, just not grouped by time control):

```sql
SELECT
    p.login, p.nickname, p.joined_at,
    (SELECT COUNT(*) FROM game g
     WHERE g.white_player_ref = p.login OR g.black_player_ref = p.login) AS games_count,
    MATCH(p.nickname) AGAINST (:wildcard_term IN BOOLEAN MODE) AS relevance
FROM player p
WHERE MATCH(p.nickname) AGAINST (:wildcard_term IN BOOLEAN MODE)
ORDER BY relevance DESC, games_count DESC, p.joined_at DESC
LIMIT :limit;
```
`:wildcard_term` = `*term*` (boolean-mode wildcard both sides, ngram-tokenized under the hood).

`ngram_token_size` (default 2) is the mechanical floor for a matchable query — short-circuit
(return `[]`) below that length rather than firing an unmatchable `MATCH()`. Not a throttle (the
user is fine with enumeration) — WHERE it becomes one is `[[profile_search_deferred]]` (rate
limiting, separate initiative).

### Rating — reuse the profile page's exact "best" logic, batched over the page

"Best ELO ... prepended by the respective time control kind icon" is precisely
`PlayerGameStats.best_ranked` + `by_time_control[best_ranked].elo`, already computed per-login by
`player/methods.py:get_overall_ranked_game_stats` (latest `PlayerEloProgress` row per
`time_control_kind`, then `RankedGameStats.is_better_than` picks the best — non-provisional beats
provisional, then elo, then ranked-games-count). That comparison logic doesn't reduce to a plain SQL
`MAX(elo)`, so it isn't part of the `ORDER BY` above (rating is display-only, never a sort key) —
but it does need to run for every returned row.

Since it's bounded by `limit` (not by how many rows matched `MATCH()`), reuse
`get_overall_ranked_game_stats` as-is, fanned out with `asyncio.gather` over the ≤`limit` result
logins, rather than inlining a window-function rewrite. Flagged as a later optimization in
`[[profile_search_deferred]]` if `limit` ever grows large enough for this to matter.

### Response DTO

```python
class PlayerSearchResult(CustomModel):
    login: str
    nickname: str
    joined_at: datetime
    games_count: int
    best_elo: int | None
    best_elo_time_control_kind: TimeControlKind | None
```
New method `player/methods.py:search_players(session, main_config, q, limit) -> list[PlayerSearchResult]`
combining the two steps above; new route in `player/routes.py`.

### Schema bootstrapping note

There's no Alembic/migration framework in this server (`SQLModel.metadata.create_all` on startup
handles table creation only) — a `FULLTEXT ... WITH PARSER ngram` index isn't something
`create_all` will emit from a plain SQLModel field declaration. Simplest path: an idempotent raw
`CREATE FULLTEXT INDEX IF NOT EXISTS` (or catch-and-ignore the duplicate-index error) executed
alongside `create_all` in `net/core.py`'s lifespan hook. Introducing real migration tooling is out
of scope for this feature — flagged in `[[profile_search_deferred]]`.

## Frontend (`Intellector Frontend v3.0`)

### DTO + REST operation

`net/models/player/PlayerSearchResult.hx` mirrors the server DTO (`joined_at` via
`morestd.DateTime` + `@:jcustomparse(jsonmodel.StdParsers.parseDate)`, same pattern as
`PlayerPublic.joined_at`; `best_elo_time_control_kind` via the existing
`net.models.common.TimeControlKind`/`TimeControlKindMapper`). New
`RestOperationRegistry.SEARCH_PLAYERS = new GetOperaton<UnserializableArray<PlayerSearchResult>>("/player/search")`.

### `http`/`easyrest`: additive, backward-compatible cancellation

Traced the call chain: `easyrest.RestClient.execute` → `http.HttpClient.makeRequest` →
`http.providers.DefaultHttpProvider` → `haxe.Http` (= `haxe.http.HttpJs` on the JS target, vendored
inside the `http` haxelib). `HttpJs` **already has a working `cancel()`** (`req.abort()`) — nothing
above it exposes that capability today: `IHttpProvider.makeRequest`/`HttpClient.makeRequest` both
return a bare `Promise&lt;HttpResponse&gt;`, `RestClient.execute` returns `Void`.

Backward compatibility means not touching the existing `IHttpProvider`/`HttpClient.makeRequest`/
`RestClient.execute` signatures or behavior at all — add alongside them:

- `http.IHttpProvider` stays untouched. New optional marker interface
  `http.ICancellableHttpProvider { function cancel(request):Void; }` — `DefaultHttpProvider`
  implements it under `#if js` only (this project is HTML5-only per CLAUDE.md, so no need to solve
  cancellation for `sys`/`nodejs` targets), backed by the `HttpJs` instance's existing `.cancel()`.
- `http.HttpClient` gets a new `makeCancellableRequest(...)` returning
  `{promise:Promise&lt;HttpResponse&gt;, cancel:()->Void}`. The returned `cancel` has two cases: the
  request is still sitting in the internal `NonQueue` (not yet dispatched) → remove it from the
  queue; already dispatched → `Std.downcast(provider, ICancellableHttpProvider)?.cancel(request)`,
  no-op if the provider doesn't support it. Existing `makeRequest` is unchanged (can even delegate
  to the new method and discard the handle, to avoid duplicating the queueing logic).
- `easyrest.RestClient` gets a new `executeCancellable&lt;...&gt;(...)` mirroring `execute`'s
  signature/body but returning the cancel handle. Existing `execute` untouched.

This is a third-party-library change (`http` is one of the libraries CLAUDE.md calls out
explicitly, alongside HaxeUI/hxWebSockets/json2object) — flagging that plainly rather than treating
it as routine, even though the user has already approved doing it. `easyrest` itself is one of the
project's own freely-editable libraries, so its half of this is unremarkable.

### `haxefolio.components.AutoComplete<T>` — new generic component

No `AutoComplete`/`ComboBox` exists in vendored `haxeui-core` 1.7.0. Per the user's direction this
is a new, app-agnostic widget living in `haxefolio` (new `haxefolio.components` package — no
existing "generic reusable widget" package in the library today; closest prior art is
`haxeui-core`'s own `DropDown`, useful as a structural reference for "trigger + anchored popup
list" but built for a fixed known item set, not an async/changing one).

Constructor-level shape (illustrative, not final):
```haxe
class AutoComplete<T>
{
    public function new(
        fetch:(query:String, onResult:Array<T>->Void, onError:Dynamic->Void) -> {cancel:()->Void},
        rowRenderer:T->Component,
        ?debounceMs:Int = 300,
        ?minQueryLength:Int = 2
    );
}
```
Internally: a `TextField` + a positioned popup list container. On `UIEvent.CHANGE`:
`RefreshableTimer(debounceMs, doSearch).start()` (same debounce idiom already used for resize —
`haxefolio.ResponsivityController`). `doSearch` first cancels any in-flight fetch (via the handle
`fetch` returned last time), then calls `fetch` again with the current text — real network-level
cancellation via the `http`/`easyrest` extension above, not a soft "ignore stale response" hack.
Below `minQueryLength`, no request fires and the popup clears.

Rendering contract, matching the user's explicit "don't flicker" rule: **rows are never touched
while a request is in flight** — the popup keeps showing whatever it last settled on until the new
fetch's callback fires. On settle: non-empty result → replace rows; empty result or error → clear
the popup silently (no inline error UI at all, per explicit instruction).

### App-specific wiring

- `client/ui/common/overlays/playersearch/PlayerSearchOverlay.hx` (mirrors the existing
  `client/ui/common/overlays/login/LoginOverlay.hx` shape), holding an
  `AutoComplete&lt;PlayerSearchResult&gt;` configured with `Rest.client().executeCancellable(SEARCH_PLAYERS, ...)`
  and `PlayerSearchResultRow` as the row renderer. **Remember the explicit fixed-size overlay
  gotcha** already hit once before (`[[feedback_haxefolio_overlay_sizing]]`) — percent-sized
  `OverlayContent` collapses without an explicit modal width/height.
- `Main.hx`: `onPlayerProfilePressed` becomes
  `() -> HaxeFolioApp.showOverlay("player_search", dismiss -> new PlayerSearchOverlay(dismiss))`.
  Selecting a result row navigates to the already-registered `player/{login}` route (`ProfilePage`
  exists as a stub today, same as every other not-yet-built destination page — this pass isn't
  responsible for its content) and dismisses the overlay.
- `client/ui/common/PlayerSearchResultRow.hx` + its layout XML: stub avatar `Image` (generic
  placeholder asset, real avatar retrieval deferred — see `[[profile_search_deferred]]`) on the
  left; right side two lines —
  - nickname, bold, black
  - one detail line, regular, dark grey, assumed to be a single row of the three pieces separated
    by " · " (this exact separator/single-line-vs-multi-line reading is an assumption, flagged
    below, not confirmed):
    `{time control icon} {best elo or "Unrated"} · {games_count} games · Joined on {DD.MM.YYYY}`

  "Unrated" text (reusing the existing Rated/Unrated vocabulary from
  `intellector.home.bracket.unrated`, per `[[home_page_plan]]`) is what's shown — icon and elo
  segment both replaced — when `best_elo_time_control_kind` is `null` (no ranked games in any time
  control). This specific fallback wasn't spelled out by the user; flagged as an assumption too.

- New `client/formatters/DateFormatters.hx` (`formatJoinDate(DateTime):String` → `DD.MM.YYYY`),
  alongside the existing `TimeControlFormatters`/`IdentityFormatters` in the same package.
- Time-control-kind → icon path: no reusable helper exists yet anywhere in the project (only
  `TimeControl` → `TimeControlKind` via `TimeControlExtension.getKind()`); `[[home_page_plan]]`'s
  still-unbuilt `TimeControlCellRenderer` would need the same `TimeControlKind` → `assets/images/common/time_controls/{kind}.svg`
  mapping. Worth extracting as a small shared helper now rather than duplicating it, since this
  pass needs it first.

## Assumptions flagged for confirmation (not silently locked in)

1. Detail-line layout: one row, three segments, " · " separator — see above.
2. "Unrated" text + hidden icon when a player has no ranked games at all.
3. Result popup opens from the existing "Player Profile" menu item as a full-screen-ish overlay
   (matching the old dialog it replaces), not an always-visible inline menu-bar search field.
4. Result count cap: proposing `limit = 10` for a dropdown-style popup — not stated by the user.

## Verification

1. `haxe build.hxml --debug` — zero errors, including the extended `http`/`easyrest` libraries.
2. Seed a handful of players with varying nicknames, game counts, ranks, join dates in the local
   `IntellectorServerV2`; confirm `GET /player/search?q=...` ranks as specified (relevance, then
   games count, then join date) via a raw HTTP call before touching the UI.
3. Open the Player Profile overlay, type a partial/misspelled substring — results appear
   relevance-ranked, rows show avatar stub / nickname / rating+icon (or "Unrated") / games count /
   join date correctly formatted.
4. Type fast through several distinct queries — confirm (Network tab) that earlier in-flight
   requests are actually aborted (not just ignored) when a newer one fires.
5. Clear the box / trigger a query with zero matches / force a server error — popup goes empty
   silently, no error UI, no leftover stale rows.
6. Click a result — navigates to `/player/{login}` and dismisses the overlay.
