# Deferred entries from the Home Page (Main Menu) transition

Source: `C:/Users/mitmi/Documents/GitHub/Intellector/src/gfx/screens/MainMenu.hx` and its
subcomponents/popups (`gfx/main/*`, `gfx/popups/LogIn.hx`, `ChallengeParamsDialog.hx`,
`ChangelogDialog.hx`). See `[[home_page_plan]]` for what was actually built this pass.

Already resolved and built this pass: the page shell, the Open Challenges and Current Games
tables (real REST load + real WS live updates, dedup/removal by id), the Mode and Time column
renderers, and three prerequisite bug fixes in `net.models`/`net.ws` (`TimeControl` rename across
7 files, `NewRecentGame` and `CurrentGameListStateRefresh` payload-type corrections).

Everything below is still open.

## 1. < Removed >

## 2. Challenge-creation dialog

**Why deferred:** the old `ChallengeParamsDialog` (time control presets/manual editor, ranked
checkbox, color choice, and a custom-starting-position board editor) is a large separate
subsystem; the board editor specifically depends on board-rendering UI that doesn't exist yet.

**How to apply:** build as a `HaxeFolioApp.showOverlay()` overlay (per CLAUDE.md's
dialog-to-overlay migration rule, not a ported `BaseDialog`), triggered from the Create Game
button after login. `RestOperationRegistry.CREATE_OPEN_CHALLENGE`/`CREATE_DIRECT_CHALLENGE`
already exist and are unused so far.

## 3. Challenge-joining screen / Live game screen (row-click navigation targets)

**Why deferred:** neither destination page exists yet.

**How to apply:** `OpenChallengesTable.onRowSelected` / `CurrentGamesTable.onRowSelected` already
fire the real REST lookup (`GET_CHALLENGE` / `GET_GAME`) but discard the response. Once the target
pages exist, replace the empty `onResponse` callback with real `HaxeFolioApp.navigateTo(...)`
calls based on the response.

## 4. Real changelog

**Why deferred:** explicit user instruction for this pass — placeholder text only, no click
behavior, changelog system itself untouched.

**Existing but unused:** `assets/resources/changelog.json` was already migrated in an earlier
commit and is not read by anything yet.

**How to apply:** `changelogLabel` should show the latest entry (`htmlText`, per the old
`Changelog.getFirst()`) and clicking it should open an overlay listing every entry
(`Changelog.getAll()`). No dynamic font-shrink-to-fit formula, though (see CLAUDE.md's rejection
of `ResponsiveToolbox`) — needs its own non-continuous sizing approach if the single-line
constraint still matters.

## 5. Custom starting position preview tooltip (board mini-preview)

**Why deferred:** needs a board-rendering component, which belongs with the future Game/Analysis
page work, not the Home page.

**How to apply:** currently just a plain non-interactive badge icon plus a text tooltip
(`intellector.common.custom_starting_position`). Once a board-preview component exists, revisit
`ChallengeModeRenderer` and reference the old `gfx.main.ChallengeModeRenderer.hx` /
`gfx.common.SituationTooltipRenderer.hx` for what the richer tooltip looked like.

## 6. Recent / Past games list

**Why deferred:** the old `PastGamesList` embeds a `GamesList`/`GameWidget` component shared with
the (not yet transitioned) Profile page. Rather than build a one-off version just for Home, this
whole feature was explicitly dropped from this pass's scope.

**How to apply:** build once a shared game-row/list component naturally becomes needed (Profile
will need one too — build it there, or promote it to `client.ui.common` if Profile turns out to
need the exact same thing Home would). Data sources are already half-wired:
`CurrentGamesTable` already consumes `NewRecentGame` (payload `GameSummaryPublic`, post this
pass's bug fix) but only to *remove* the game from Current Games — the same event is exactly the
live-update source a Recent Games list would need. `RestOperationRegistry.GET_RECENT_GAMES` exists
and is unused so far.

## 7. < Removed >

## 8. Live locale rebinding for table-row text

**Why deferred (a real limitation, not just an unbuilt feature):** `Label.text`'s `"{{key}}"`
auto-resolution is a compile-time XML macro feature (`haxe.ui.macros.ComponentMacros.assignField`),
not generic runtime behavior — confirmed by reading `TextBehaviour.validateData`, which does a
verbatim `getTextDisplay().text = '${_value}'`. So `OpenChallengeRow.bracket` /
`CurrentGameRow.bracket` and the two custom renderers' `.tooltip` strings are resolved **once**,
at row-construction/render time, via `LocaleManager.instance.lookupString(...)`. Already-rendered
rows will not retranslate on a language switch without a table reload.

**How to apply:** not urgent since no language switcher UI is wired up yet either (see item 7).
If/when it matters, either have the tables re-`load()` on a `Preferences.language` change, or
design a general reusable "live-rebinding table cell" pattern before the next page that needs a
data-driven table (there will be several: challenge lists, game lists, study lists all follow the
same shape).

## Bugs found, not fixed this pass

Same bug pattern as two of the three fixes made for Home page (`GamePublic` used where the server
actually sends `GameSummaryPublic`), found in files unrelated to Home:

- `net/models/player/StartedPlayerGamesStateRefresh.hx`: `current_games:Array<GamePublic>` should
  be `Array<GameSummaryPublic>` (server: `IntellectorServerV2/src/pubsub/models/state.py:19-20`,
  `current_games: list[GameSummaryPublic]`).
- `net/ws/events/GameStarted.hx`: `IEvent<GamePublic, StartedPlayerGames>` should be
  `IEvent<GameSummaryPublic, StartedPlayerGames>` (server:
  `IntellectorServerV2/src/pubsub/outgoing_event/update.py:42`,
  `OutgoingEvent[GameSummaryPublic, StartedPlayerGamesEventChannel]`).

**Why not fixed now:** both belong to the `StartedPlayerGames` channel (watching a specific
player's live games) — a Profile-page feature, not touched by Home page at all.

**How to apply:** fix alongside whichever page first wires up the `StartedPlayerGames` channel
(likely Profile). Worth a full audit of every remaining `net.models`/`net.ws` DTO tied to a WS
refresh/update event against the actual server contract at that point, too — this bug (and the
unrelated `TimeControl`/`FischerTimeControl` naming bug fixed this pass) both suggest the
`net.models`/`net.ws` package was generated/copied with some systematic mismatches, not just
isolated typos, so more may be lurking in channels no page has exercised yet.
