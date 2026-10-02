# Board component plan

What's left to fully implement the board component family, and a provisional order to build it
in. Supersedes this file's previous content (the original architecture pitch and the
`BoardSurface`-only scoping) - see git history for that discussion if the *why* behind a decision
below needs re-deriving. `[[board_deferred]]` still holds the detailed record of what shipped in
the `BoardSurface`/`MoveInteractionController` core-click-drag passes and the bugs found along the
way; this doc doesn't repeat that.

## 0. Where things stand

Done: `BoardSurface` (static rendering + the glyph/tint/hit-testing API
`MoveInteractionController` needs), `MoveInteractionController`'s core click/drag/click-to-select
pass, premove (§2.4: queue, tints, `notifyMovePlayed`/`notifyPositionReplaced` contract, `HexTint` palette
in `BoardSurface`), the promotion/chameleon `MoveRules` split with `intellectorboard`, the
board-anchored promotion fan and capture-morph popovers (`client.ui.common.board.move_prompt`, §2.2),
the live board's `boardCoordinates` preference subscription on `AnalysisPage` (§2.1), piece assets,
and `BoardCoordinatesMode` as an `enum abstract` in `client.datatypes`. Also fixed along the way, in
`intellectorboard`: the hex-stepping geometry, several dead-code-since-nothing-called-it bugs in
the movement/ply-application packages, and (in `haxefolio`) two `SvgSurface` sizing/coordinate
bugs (pinned height on resize; screen-coordinate mismatch under `Toolkit.scale`).

Not done, and the subject of this doc: the remaining items in §2 below, in the order given in §3.

## 1. Architecture, condensed

(Full rationale for rejecting the old `Board`/`SelectableBoard`/`GameBoard` inheritance chain and
`State`×`Behavior` cross-product lives in git history for this file - the short version: it didn't
compose, the resulting classes were 400-500+ lines, and it let networking/preferences/dialog
concerns leak into rendering code. Not being re-litigated.)

- **`BoardSurface`** is the only thing that always exists - geometry, rendering, and (now) the
  glyph/tint/hit-testing primitives. A non-interactive preview is a bare `BoardSurface`.
- **Controllers** are small standalone classes attached to a `BoardSurface`, never subclasses of
  it: `MoveInteractionController` (done, core pass plus the pending-choice state for the popovers), `HexAnnotationController` (RMB marks, §2.5),
  `PositionEditorController` (§2.6). Config values (allowed-to-move color, premove on/off, etc.)
  select behavior - not separate classes.
- **Non-overlapping ownership, not runtime arbitration:** left-button gestures belong to
  move/editor interaction, right-button to `HexAnnotationController`; only one "state" controller
  (`MoveInteractionController` XOR `PositionEditorController`) is ever attached; `BoardSurface`'s
  glyph API hands back raw handles and keeps no ownership map, so each controller tracks only what
  it created.
- **Mandatory interruption contract:** a new `Position` or a new controller config must cleanly
  abort any gesture in flight - including a pending promotion/chameleon choice, whose popover is
  closed and whose visuals are reverted. Implemented for `MoveInteractionController`
  (`notifyPositionReplaced`/`notifyConfigChanged`/`dispose`); not yet covered by an automated test (§2.8).
- **Game-rules queries are injected, not imported** - `MoveInteractionController` has no
  compile-time dependency on `intellectorboard`; `MoveRulesAdapter` (same package as
  `BoardSurface`, which already depends on `intellectorboard`) is the real implementation.
- **Ply history/navigation lives outside the board entirely** (§2.7), in a session-level datatype
  the page owns.

### Locked-in hex tint palette

| Signal | Light hex | Dark hex | Note |
| --- | --- | --- | --- |
| Hover over a departure candidate (own piece, nothing selected) | `#E56A00` | `#E56A00` | Implemented. Same orange as the selected departure. |
| Anchor of a pending promotion/chameleon prompt | `#C79A56` | `#C79A56` | Implemented. Theme token `accentMuted`; literal `accent` would hide black pieces. |
| Selected / drag departure | `#E56A00` | `#E56A00` | Implemented. Stays tinted from selection until the move happens or the gesture is cancelled (through dragging, and after a plain click on the departure). |
| Hover over a legal destination (drag or click-selected) | `#FFE4C8` | `#D9A068` | Implemented. Normal fill with HSL lightness +0.08, uniform delta on light/dark. Non-destination hexes get no hover tint. |
| Hover in position editor | `#E56A00` | `#E56A00` | Not yet used - orange like the departure hover; apply when the position editor's controller is built. |
| Premove | `#869E60` | `#648039` | Implemented (`HexTint.Premove`). |
| Last move | `#FDD340` | `#BE9C26` | Not yet used - needs §2.7's session datatype to know what the last move was. |
| RMB mark, legacy fill (preference-gated) | `#FF6955` | `#BE3726` | Not yet used - §2.5. |
| RMB mark, new default | ring, stroke `#FF0000` | ring, stroke `#FF0000` | Not yet used - §2.5. |

Fill priority (highest wins; only one state controller ever writes it): **hover → selected/drag
departure → premove → RMB legacy-fill (if that preference is on) → last move → base.** Markers and
RMB rings are separate shapes outside this list.

## 2. Remaining work

### 2.1 Board coordinates auto-update on preference change - DONE for `AnalysisPage`

Currently a page reads `Preferences.boardCoordinates.get()` once, at construction, and passes the
resolved mode into `BoardSurface`'s constructor - changing the preference elsewhere (the
preferences window) does nothing to an already-open board.

`BoardSurface` must not import `Preferences` itself (architecture rule in §1 - it receives pure
state). So each page hosting an interactive/live board subscribes itself:

```haxe
private var coordinatesModeHandle:Detachable;
...
coordinatesModeHandle = Preferences.boardCoordinates.onChange(mainBoard.setCoordinatesMode);
```

and detaches in `onClose` - the pattern `Preference.onChange`'s own doc comment already names as
canonical, just not yet used anywhere in this codebase (first real call site).

Only the *live* board a page is actually showing should subscribe. `AnalysisPage`'s current
preview row deliberately shows all three modes side by side at once - those three boards must
stay fixed at `NONE`/`FILES_ONLY`/`ALL` regardless of the live preference, or the demo loses its
point.

Wired into `AnalysisPage` (subscription detached in `onClose`; the three preview boards stay fixed).
Repeat at each future call site (challenge preview, live game
page, list rows that end up interactive) as they're built. Don't extract a shared helper until a
second real call site actually needs the identical wiring - one call site doesn't justify the
abstraction yet.

### 2.2 / 2.3 Promotion fan and capture-morph popovers - DONE

Replaced `MovePromptOverlay` (deleted) with board-anchored, non-modal popovers:
`client.ui.common.board.move_prompt.MovePrompt` (+ `PromptButton`), styled by `.intellector-prompt-*`
in `main.css`. The design doc `promotion-and-morph-popovers.md` holds the spec, with a "Revisions"
section listing where the implementation supersedes it - that section, not the original text, is
current. Summary of the state of things:

- **Promotion fan:** four options plus a cross (cancel) on an arc around the hex, opening toward the
  board's interior; button diameter is 0.9 x the hex's on-screen height (min 44 px), so everything
  scales with the board. Files b-h: symmetric arc (40 degree steps), leaning toward the board's
  centre only as far as needed to fit the viewport (cap 60 degrees). Files a/i: a quarter circle
  toward the centre, on its own (larger) radius.
- **Capture morph:** 390 px wide (1.5x the original spec), header "Use aura?" + close button,
  "Become X"/"Stay Y" buttons in the capturing piece's colour, 94% opaque surface, placed on the
  side of the hex facing the board's centre.
- **Cancelling:** cross / close button, a press outside, or Esc - all abandon the move.
- **Interaction:** while a choice is pending the moving piece is drawn on the anchor hex, any
  captured piece is hidden, and the anchor gets the `#C79A56` fill; everything reverts on choice,
  cancel or interruption. The pending choice is an `InteractionState` case (`AwaitingChoice`), so
  `notifyPositionReplaced`/`notifyConfigChanged`/`dispose` close the popover.
- **Not built, by decision:** keyboard focus, arrow keys, focus rings (dropped project-wide).
- **Supporting changes:** `haxefolio.ElementShadow` is public (returns a `Detachable`);
  `SvgSurface` gained `viewBoxPointToClient`/`viewBoxUnitInPixels`; `BoardSurface` gained
  `movePieceToHex`, `setPieceVisible`, `hexClientCenter`, `hexClientHeight`, `horizontalPosition`,
  `isInLowerHalf`, and a public `pieceAspectRatio`.
- **Locale:** global `intellector.piece.<kind>.<case>` names (nominative, instrumental); the
  `intellector.board.prompt.*` templates name the case they need via a `.case` key.

Verified in-browser (with a temporary hand-built position, since removed): promotion and capture by
click; picking an option; cancel by Esc, outside press, cross and close button; navigating away
with a prompt open; a promotion on files a, c and i and a capture near the centre; both prompts
following a viewport resize. **Not verified:** the drag (rather than click) route into a prompt,
the position-changing-under-an-open-prompt interruption (only navigating away was tried),
following page scroll, a phone-width (~390 px) viewport, and long Russian labels wrapping. The
fan looks worst for a corner hex on a wide board (the a/i quarter circle is large).

### 2.4 Premove - DONE in `MoveInteractionController` (not yet wired into a real page)

Built: `MoveInteractionConfig` is `{allowedToMove: Null<PieceColor>, premovesEnabled: Bool}` -
`allowedToMove` is the color the user plays (constant across the opponent's turn, `null` for
spectating/history), and whose turn it is is read off the position, so premove mode is derived:
`premovesEnabled` and not the user's turn. `MoveRules.getPremoveDestinations` (backed by
`PremoveDestinations`, whose bugs - undeclared `piece`, missing semicolon, missing `using Lambda` -
are fixed). A plain FIFO queue of `RawPly`; a queued premove is drawn as already played
(`shownPosition` = real position with the queue transposed onto it, no validation) so the same piece
can be premoved again from its destination, while firing validates only the head against the real
position. Promotion is chosen at queue time; chameleon is never asked (plays as no-morph). No move
markers in premove mode (as in the old version).

Tints: the palette moved out of the controller into `BoardSurface.setHexTint(coords, HexTint)`
(`Departure`, `DestinationHover`, `PromptAnchor`, `Premove`), which picks the light/dark shade itself;
future writers (annotations, last move) add enum cases there. Fill priority stays the controller's
job (`restoreHexFill` replaces `resetHexFill` for gesture reverts so premove tints survive hovering).

Page contract: `board.setPosition`, then `notifyMovePlayed` (a move by either side, including the
controller's own fired premove - queue kept, and if the turn has come to `allowedToMove` the head is
validated and played via `onMoveChosen`, else the whole queue is dropped) or `notifyPositionReplaced`
(anything else: rollback, history, reset - queue discarded). `notifyConfigChanged` only needs calling
when the config actually changes; changing `allowedToMove` or setting `premovesEnabled` to false
drops the queue. A click on a hex that starts no gesture also drops it.

Verified in-browser with a temporary harness (random Black replies after 4 s, constant config): queue
+ tint on light and dark hexes, void-click clear, chaining the same piece (one premove fires per
reply), invalid head dropped with everything behind it (confirmed as intended), `notifyPositionReplaced`
discarding the queue, no dependence on the page re-sending its config (an earlier design lost the
queue when the handover config omitted `premoveColor`), markers back on the user's own turn.
**Not verified by me:** drag route, premove interrupted by the position changing mid-prompt.

### 2.5 `HexAnnotationController` (RMB rings/arrows)

Owns right-button gestures only (input-channel partitioning, §1). Two RMB modes per the locked
palette: new default is a red ring outline (`#FF0000`, matching the arrow color); a preference
(name/location TBD, likely alongside `Preferences.boardCoordinates`) switches to the legacy
pinkish fill, which then occupies the fill-priority slot between premove and last-move. Arrow
geometry ports from the old repo's `ArrowCanvas.hx:25-82` (pure math) onto `SvgSurface`'s path
builder.

Independent of §2.4 (different input channel, no shared state) - the two could be built in either
order or swapped in the build order below without consequence.

### 2.6 `PositionEditorController` (analysis position editor)

Free move / place / clear modes, replacing `MoveInteractionController` when attached (never both).
Old reference: `EditorBehavior`/`EditorFreeMoveBehavior`/`EditorDeleteBehavior`/`EditorSetBehavior`
- shape of the three modes only, not their dialog/event coupling. Worth deciding, once
`MoveInteractionController` premove work (§2.4) is also done and both controllers' click/drag
plumbing can be compared side by side, whether "free move" shares a base/helper with
`MoveInteractionController` or duplicates it.

Depends on §2.7 existing first: a real position editor is what finally turns `AnalysisPage` from a
smoke test into the actual page, which needs somewhere to hold the position being edited.

### 2.7 Session-level ply history / navigation datatype

New `client.datatypes` type (name TBD - `GameSession`/`AnalysisSession` or similar), replacing the
old `GameBoard.plyHistory`. Owns move history and the current navigation pointer; on each
navigation step, hands `BoardSurface` a fresh `Position` plus the previous move's from/to hexes
(for the last-move tint, still unused - see §1's palette table). Move sounds
(old `Audio.playPlySound`) belong at this level or in the page, not in the board.

This is the last piece needed before `LiveGamePage` can exist at all, and before `AnalysisPage`
can hold more than one position.

### 2.8 Automated interruption-contract tests

The contract itself (including the premove queue's survive/discard rules) is implemented and manually verified, not covered by an automated test.
Retrofit once there's something real to interrupt *with* - an opponent-move-mid-drag test needs
§2.7 (a session feeding real position updates), a rollback test needs the same, and an
editor-mode-switch test needs §2.6. Writing this test now, against only the core click/drag pass,
would just re-verify what's already been checked by hand.

### 2.9 Revisit `BoardSurface`'s size

Flagged (by the user, in passing) as having grown large over the `MoveInteractionController` pass
- currently ~300 lines covering static rendering, the glyph/tint API, and hit-testing together.
Not addressed by this doc: revisit once §2.4-§2.6 have all landed and used the API for real, so
any split (e.g. separating static rendering from the interactive glyph/hit-testing surface) is
based on how the API is actually exercised, not a guess made before the remaining controllers
exist.

## 3. Provisional build order

Done: §2.1 (coordinates auto-update), §2.2/§2.3 (promotion and morph popovers), §2.4 (premove).

1. **§2.5 `HexAnnotationController`** - independent of §2.4 (now done).
2. **§2.7 session-level datatype** - needed before either real page (`LiveGamePage` or a
   `AnalysisPage` beyond a smoke test) can exist; natural next step once single-board interaction
   (§2.4-§2.5) is solid.
3. **§2.6 `PositionEditorController`** - depends on §2.7 existing, and benefits from §2.4 being
   done first (see the shared-plumbing question in §2.6).
4. **§2.8 automated interruption-contract tests** - retrofit once §2.4/§2.6/§2.7 give it real
   scenarios to test against.
5. **§2.9 revisit `BoardSurface`'s size** - opportunistic, once its API's real shape is settled by
   §2.4-§2.6 actually using it. (It has grown by the popover-support methods above.)

Each numbered item, when its turn comes, likely deserves its own scoping pass (the way
`BoardSurface` and `MoveInteractionController`'s core pass were each scoped down from the full
architecture) rather than being built in one shot against this doc's necessarily-provisional
description of it.
