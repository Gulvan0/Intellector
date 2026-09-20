# Home page (Main Menu) transition plan

Source: `C:/Users/mitmi/Documents/GitHub/Intellector/src/gfx/screens/MainMenu.hx` and its
subcomponents in `gfx/main/` (`OpenChallengesTable.hx`, `CurrentGamesTable.hx`,
`ChallengeModeRenderer.hx`, `TimeControlRenderer.hx`), plus their layout XML under
`assets/layouts/main_menu/`.

This is the first page ever built in this project — no `client/ui` package and no registered
page existed beforehand in `src/Main.hx`.

Scope for this pass (narrowed with the user up front; see `[[home_page_deferred]]` for what was
cut and why):
- **Create Game button**: rendered, click is a stub no-op.
- **Changelog**: a label with placeholder text, no click behavior, no real changelog wiring.
- **Open Challenges table**: fully real (REST load + WS live updates). Row click fires the real
  REST lookup but does not navigate (no-op on response).
- **Current Games table**: fully real (REST load + WS live updates), same row-click stub.
- **Recent/Past games list**: dropped entirely for this pass.
- **Custom starting position preview tooltip**: dropped — a plain non-tooltip badge icon instead.
- No login/auth UI, no challenge-params dialog, no menu bar.

## Step 0 — prerequisite bug fixes

Found while researching the real DTOs/WS events this page needs; fixed as part of this pass
because the page can't compile/deserialize real server data otherwise (see
`[[home_page_deferred]]` for the *other* instances of these bug patterns that were left alone
because nothing in this pass touches them):

1. `net.models.common.TimeControl` is imported/used in 7 files but doesn't exist — only
   `net.models.common.FischerTimeControl` does. Fixed in: `net/models/challenge/ChallengePublic.hx`,
   `ChallengeCreateDirect.hx`, `ChallengeCreateOpen.hx`, `net/models/game/GameSummaryPublic.hx`,
   `GamePublic.hx`, `GameStartedBroadcastedData.hx`, `net/models/game/external/ExternalGameCreatePayload.hx`
   — rename the import and every `Null<TimeControl>` to `Null<FischerTimeControl>`.
2. `net.ws.events.NewRecentGame`'s payload was declared `GameEndedBroadcastedData`; the server
   (`IntellectorServerV2/src/pubsub/outgoing_event/update.py:103`) actually sends `GameSummaryPublic`.
3. `net.models.game.CurrentGameListStateRefresh.games` was declared `Array<GamePublic>`; the server
   (`IntellectorServerV2/src/pubsub/models/state.py:15-16`) sends `list[GameSummaryPublic]`.

## `Main.hx` bootstrap

`Rest.init(...)`/`PubSub.start(...)` were never called anywhere; both singletons crash on first
use if uninitialized. No login flow exists, so bootstrap as an unauthenticated guest:

```haxe
Rest.init(() -> null);
PubSub.start(() -> null, () -> null);
// ...existing HaxeFolioConfigBuilder chain...
.addPage("home", params -> new HomePage(), true)
```

## New page architecture

First use of `@:build(haxe.ui.ComponentBuilder.build("assets/layouts/..."))` XML-defined
components in this project (no prior precedent in this repo or in `haxefolio` itself). Verified
`ComponentBuilder.build` resolves paths relative to the project root when run via
`haxe build.hxml`, so no build.hxml/classpath changes are needed.

```
src/client/ui/home/HomePage.hx
src/client/ui/home/OpenChallengesTable.hx
src/client/ui/home/CurrentGamesTable.hx
src/client/ui/home/OpenChallengeRow.hx
src/client/ui/home/CurrentGameRow.hx
src/client/ui/home/TimeControlCellData.hx        (shared interface for the Time column renderer)
src/client/ui/home/renderers/ChallengeModeRenderer.hx
src/client/ui/home/renderers/TimeControlCellRenderer.hx

assets/layouts/home/home_page.xml
assets/layouts/home/open_challenges_table.xml
assets/layouts/home/current_games_table.xml
assets/layouts/home/renderers/challenge_mode_renderer.xml
assets/layouts/home/renderers/time_control_cell_renderer.xml

assets/images/home/reload.svg
assets/images/home/challenge_modes/{white,black,random,custom_position}.svg
assets/images/common/time_controls/{hyperbullet,bullet,blitz,rapid,classic,correspondence}.svg
```

SVGs copied/adapted from `Intellector/assets/symbols/main_menu/{reload.svg, challenge_modes/*.svg}`
and `Intellector/assets/symbols/time_controls/*.svg` (skipping the incomplete `monochrome/`
variants — no dark theme yet). Time-control icons go under `assets/images/common/` since the next
pages (challenge creation, game view) will reuse them; challenge-mode icons stay under
`assets/images/home/`.

### `HomePage.hx`

`PageBase` subclass. `init()` wires the Create Game button (stub `onClick`), builds the two
tables, calls `.load()` on each once. `onResize(width, height)` toggles one breakpoint (aspect
ratio `< 1.2`) between side-by-side (50/50 width, `HorizontalLayout`) and stacked (100/100,
`VerticalLayout`) — mirrors the old screen's breakpoint condition but with **no font-size
recomputation** (all font sizes are fixed XML constants, per CLAUDE.md's rejection of
`ResponsiveToolbox`). `onClose()` detaches both tables' WS subscriptions.

### `OpenChallengesTable.hx` / `CurrentGamesTable.hx`

Both extend `haxe.ui.containers.VBox`, built from their own XML (title + reload button +
`tableview`). Each:
- Subscribes to its WS channel in the constructor; exposes `detachSubscription()` for
  `HomePage.onClose()`.
- Exposes `load()`, called once from `HomePage.init()` and again on Reload click — **no cooldown
  timer** this time (the old 5s disable rate-limited REST as the *only* refresh path; now WS push
  already keeps the table live, so manual reload is just a force-resync).
- Tracks a local `Array<Int>` of displayed ids only (nothing needs full DTOs back) to dedupe adds
  and resolve removals.
- Row click (`table.onChange`, reading then resetting `table.selectedIndex`) fires the real REST
  lookup (`GET_CHALLENGE` / `GET_GAME`) with an empty `onResponse` — no navigation.

**OpenChallengesTable** — REST: `RestOperationRegistry.GET_PUBLIC_CHALLENGES`
(`UnserializableArray<ChallengePublic>`, via `.parsed`). WS: `PubSub.sub(new PublicChallengeList())`
chained with `.onEventLight(NewPublicChallenge, ...)` (`ChallengePublic`),
`.onEventLight(PublicChallengeCancelled, ...)` / `.onEventLight(PublicChallengeFulfilled, ...)`
(`net.models.common.Id`, field `id:Int`), `.onEventLight(PublicChallengeListRefresh, ...)`
(`ChallengeListStateRefresh { challenges }`, hard clear+rebuild).

Note: subscribing to `PublicChallengeList`/`CurrentGameList` also triggers an immediate targeted
`*ListRefresh` server-side (`IntellectorServerV2/src/pubsub/ws_handlers.py`), racing harmlessly
with this page's own initial REST call — every add path is id-deduped and both `*ListRefresh`
handlers do a full clear+rebuild.

**CurrentGamesTable** — REST: `RestOperationRegistry.GET_CURRENT_GAMES` with `body: null` (the
server's `GameFilter` has no callable Haxe constructor, and an absent body already means
"no filter" server-side) and `queryParams: ["limit" => 50]` (this route defaults to `limit=10`,
unlike `/challenge/public` which defaults to 50 — verified against
`IntellectorServerV2/src/game/routes/common.py`). WS: `PubSub.sub(new CurrentGameList())` with
`.onEventLight(NewActiveGame, ...)` (`GameStartedBroadcastedData`),
`.onEventLight(CurrentGameListRefresh, ...)` (`CurrentGameListStateRefresh { games:Array<GameSummaryPublic> }`,
post-fix), `.onEventLight(NewRecentGame, ended -> removeById(ended.id))` (`GameSummaryPublic`,
post-fix — a game ending just removes it from Current Games; Recent Games itself isn't built).

### Row types and column binding

HaxeUI's `ItemRenderer` auto-binds a nested component's `id` to `Reflect.field(rowObject, thatId)`
(verified in `ItemRenderer.updateValues`), and every column's renderer receives the *entire* row
object as `data` (verified in `TableView`'s internal `CompoundItemRenderer.onDataChanged`) — so
row classes are plain Haxe classes whose top-level field names match column ids:

```haxe
class OpenChallengeRow implements TimeControlCellData
{
    public var id:Int;
    public var mode:OpenChallengeModeData;   // {color:ChallengeAcceptorColor, hasCustomPosition:Bool}
    public var time:client.datatypes.TimeControl;
    public var player:String;                // caller.nickname, plain
    public var bracket:String;               // resolved "Rated"/"Unrated" text, see locale note below
}

class CurrentGameRow implements TimeControlCellData
{
    public var id:Int;
    public var time:client.datatypes.TimeControl;
    public var players:String;               // "white vs black", plain
    public var bracket:String;
}
```
`TimeControlCellData` is a one-field interface (`var time:client.datatypes.TimeControl`) letting
`TimeControlCellRenderer` be shared with a real typed cast instead of `Dynamic`/`Reflect`. Both
DTO→row conversions build `time` via
`net.models.common.mappers.TimeControlMapper.dtoToDatatype(dto.fischer_time_control)`.

**Reused existing utility (found mid-planning, not written new):**
`src/client/formatters/TimeControlFormatters.formatTimeControl(TimeControl):String` plus
`net.models.common.mappers.TimeControlMapper`/`TimeControlKindMapper` — no new formatting code
needed. `client.datatypes.TimeControl`'s own `TimeControlExtension.getKind()` gives the icon
lookup key.

**Locale-resolved fields — important limitation, see `[[home_page_deferred]]` item "Live locale
rebinding for table-row text":** `Label.text`'s `"{{key}}"` auto-resolution is a compile-time XML
macro feature (`ComponentMacros.assignField`), not generic runtime behavior (confirmed by reading
`TextBehaviour.validateData`, which does a verbatim `getTextDisplay().text = '${_value}'`). So
`row.bracket`/renderer `.tooltip` strings are resolved **once**, at row-construction/render time,
via `haxe.ui.locale.LocaleManager.instance.lookupString("intellector.home.bracket.rated")` — they
will not retranslate live on a language switch without a table reload.

### `ChallengeModeRenderer.hx` (Mode column, Open Challenges only)

`ItemRenderer` subclass. Casts to `OpenChallengeRow`, sets a color icon
(`assets/images/home/challenge_modes/{white,black,random}.svg` by `row.mode.color`) with a
resolved tooltip (`intellector.home.color_tooltip.{white,black,random}`), and toggles a second
`custom_position.svg` badge (`image.hidden = !row.mode.hasCustomPosition`) with tooltip
`intellector.common.custom_starting_position` (already existed) — no board-preview, per scope.

### `TimeControlCellRenderer.hx` (Time column, both tables)

Casts `data` to `TimeControlCellData`, sets an icon by `data.time.getKind()` and label text via
`TimeControlFormatters.formatTimeControl(data.time)`.

## Locale keys added

Under the existing flat `intellector.common.*`-style convention (confirmed from the current
`.properties` files — not the unrelated `page.<slug>.*` convention seen in the separate
`haxefolio` sample project):

```
intellector.home.create_game_button
intellector.home.changelog_placeholder
intellector.home.open_challenges.title
intellector.home.current_games.title
intellector.home.reload_button
intellector.home.column.{mode,time,player,players,bracket}
intellector.home.bracket.{rated,unrated}
intellector.home.color_tooltip.{white,black,random}
```
Plus `intellector.common.correspondence_time_control_name`, which
`TimeControlFormatters.formatTimeControl` already depended on but which didn't exist in either
`.properties` file yet.

## `module.xml`

Updated to register `assets/images` as a resource (needed for the new SVGs) and `ru.properties`
as a locale (it existed on disk but wasn't registered), alongside the existing `assets/locale`
registration. No dedicated CSS file — styling needed (font sizes, text-align) stays inline on XML
`style="..."` attributes per CLAUDE.md's carve-out for short styles.

## Verification

1. `haxe build.hxml --debug` — zero errors.
2. Serve the project root over local HTTP with `IntellectorServerV2` running locally; page loads
   with Create Game button, changelog placeholder, two tables with headers, no console errors.
3. Seed the server with an open challenge and a current game; both tables populate on load
   (`GET /challenge/public`, `POST /game/current?limit=50`).
4. Create/cancel/fulfill a challenge and start/end a game from another client while the page is
   open; rows appear/disappear live without a page reload.
5. Row click in each table fires the REST lookup (Network tab) and does nothing else.
6. Create Game click does nothing.
7. Each Reload button re-fires its REST call and repopulates without duplicating rows.
8. Resize across the aspect-ratio breakpoint; tables toggle side-by-side/stacked, font sizes never
   change.
9. Kill/restart the local server while the page is open; WS reconnects and tables resync via
   `*ListRefresh` without duplicating rows.
