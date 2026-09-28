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
pass (no premove), the promotion/chameleon `MoveRules` split with `intellectorboard`,
`MovePromptOverlay` (functional but visually generic - see §2.2), piece assets, and
`BoardCoordinatesMode` as an `enum abstract` in `client.datatypes`. Also fixed along the way, in
`intellectorboard`: the hex-stepping geometry, several dead-code-since-nothing-called-it bugs in
the movement/ply-application packages, and (in `haxefolio`) two `SvgSurface` sizing/coordinate
bugs (pinned height on resize; screen-coordinate mismatch under `Toolkit.scale`).

Not done, and the subject of this doc: everything in §2 below, in the order given in §3.

## 1. Architecture, condensed

(Full rationale for rejecting the old `Board`/`SelectableBoard`/`GameBoard` inheritance chain and
`State`×`Behavior` cross-product lives in git history for this file - the short version: it didn't
compose, the resulting classes were 400-500+ lines, and it let networking/preferences/dialog
concerns leak into rendering code. Not being re-litigated.)

- **`BoardSurface`** is the only thing that always exists - geometry, rendering, and (now) the
  glyph/tint/hit-testing primitives. A non-interactive preview is a bare `BoardSurface`.
- **Controllers** are small standalone classes attached to a `BoardSurface`, never subclasses of
  it: `MoveInteractionController` (done, core pass), `HexAnnotationController` (RMB marks, §2.5),
  `PositionEditorController` (§2.6). Config values (allowed-to-move color, premove on/off, etc.)
  select behavior - not separate classes.
- **Non-overlapping ownership, not runtime arbitration:** left-button gestures belong to
  move/editor interaction, right-button to `HexAnnotationController`; only one "state" controller
  (`MoveInteractionController` XOR `PositionEditorController`) is ever attached; `BoardSurface`'s
  glyph API hands back raw handles and keeps no ownership map, so each controller tracks only what
  it created.
- **Mandatory interruption contract:** a new `Position` or a new controller config must cleanly
  abort any gesture in flight. Implemented for `MoveInteractionController`
  (`notifyPositionChanged`/`notifyConfigChanged`); not yet covered by an automated test (§2.7).
- **Game-rules queries are injected, not imported** - `MoveInteractionController` has no
  compile-time dependency on `intellectorboard`; `MoveRulesAdapter` (same package as
  `BoardSurface`, which already depends on `intellectorboard`) is the real implementation.
- **Ply history/navigation lives outside the board entirely** (§2.4), in a session-level datatype
  the page owns.

### Locked-in hex tint palette

| Signal | Light hex | Dark hex | Note |
| --- | --- | --- | --- |
| Hover (transient) | `#83ACD4` | `#6F8EAC` | Implemented. |
| Selected / drag departure | `#E56A00` | `#E56A00` | Implemented. |
| Premove | `#869E60` | `#648039` | Not yet used - §2.4. |
| Last move | `#FDD340` | `#BE9C26` | Not yet used - needs §2.3's session datatype to know what the last move was. |
| RMB mark, legacy fill (preference-gated) | `#FF6955` | `#BE3726` | Not yet used - §2.5. |
| RMB mark, new default | ring, stroke `#FF0000` | ring, stroke `#FF0000` | Not yet used - §2.5. |

Fill priority (highest wins; only one state controller ever writes it): **hover → selected/drag
departure → premove → RMB legacy-fill (if that preference is on) → last move → base.** Markers and
RMB rings are separate shapes outside this list.

## 2. Remaining work

### 2.1 Marking auto-updates on preference change

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

Wire this into `AnalysisPage` now; repeat at each future call site (challenge preview, live game
page, list rows that end up interactive) as they're built. Don't extract a shared helper until a
second real call site actually needs the identical wiring - one call site doesn't justify the
abstraction yet.

### 2.2 `MovePromptOverlay`: theme conformance

`MovePromptOverlay` (promotion picker, chameleon yes/no) is functional but was built without
attention to `[[intellector-style]]`. Two different levels of work here:

- **Probably already free:** `assets/styles/main.css` themes HaxeFolio's own overlay chrome
  classes (`.haxefolio-overlay-frame`, header, action bar, `ActionButton`) globally - the same
  mechanism `LoginOverlay` already benefits from without any per-overlay styling. `MovePromptOverlay`
  already uses `Header`/`Actions`/`ActionButton`, so the frame, title, and the chameleon prompt's
  yes/no buttons likely already inherit theme colors correctly - **verify this by rendering it**,
  don't assume.
- **Needs actual work:** the promotion picker's 4 piece-choice buttons are plain
  `haxe.ui.components.Button`s with no theme-aware styling (no selection/hover treatment matching
  §5.1's "selection is outlined" rule, no confirmed `accent`/`surfaceSunken` treatment). These need
  a small component-level style pass - likely a dedicated CSS class (e.g.
  `move-prompt-piece-choice`) giving each button the outlined-chip look on hover/focus, sized/
  spaced per §4.2's token scale, not ad hoc pixel values.

### 2.3 `MovePromptOverlay`: must not become a mobile sheet — design not yet decided

**Requirement:** on mobile/collapsed viewports, the promotion/chameleon prompt must not cover the
whole screen the way `OverlayController.present`'s default `SheetPresentation` does - the player
needs to keep seeing the board (or most of it) while choosing.

**This is explicitly not resolved by this doc** - stated here as a to-do, not a decision, per
instruction while this plan was being written. What's known so far, as leads for whoever picks
this up (research done, not committed to):

- `OverlayController.present` picks `SheetPresentation` (covers the full viewport, fully modal,
  `ResponsivityController.isCollapsed`-driven) vs `DialogPresentation` (centered, scrim at 35%
  opacity so the background stays visible-but-dimmed, `applySize()` already shrinks the frame to
  fit a narrow viewport down to a floor) purely off `isCollapsed`, with **no existing per-overlay
  override** to force one or the other.
- `AppearanceOverrides` already has exactly one field documented as "only meaningful for a
  per-overlay override, ignored theme-wide" (`styleClass`) - a hypothetical new field forcing
  dialog-style presentation would follow that precedent, but this needs a real design pass (does
  it belong on `AppearanceOverrides`, as a separate `present()` parameter, or somewhere else
  entirely?), not just bolting on a boolean.
- Open questions still to work out, not just the mechanism above: does the *content* also need a
  mobile-specific layout (the promotion picker's 4 buttons in a row may not fit a narrow dialog
  width - `MovePromptOverlay` doesn't currently supply a `mobileContentFactory`), and is a
  modified `DialogPresentation` actually the right answer at all, versus something else entirely
  (e.g. a non-modal anchored popover near the moved piece)? Come up with the actual design - a
  mock, not just a mechanism - before implementing.

This item touches `haxefolio` (a shared library), not just app code, if the `AppearanceOverrides`
route is the one chosen - same review bar as any other framework-level change.

### 2.4 Premove

`MoveInteractionController` config needs a premove-enabled flag; `MoveRules` needs a
premove-destination query parallel to `getLegalDestinations`, backed by
`intellectorboard.movement.rules.PremoveDestinations` - **which currently has its own
never-compiled-because-never-called bug**, same class as the ones already fixed elsewhere this
pass: `getPossiblePremoveDestinations` references an undeclared `piece` (should be `movingPiece`)
and is missing a semicolon. Fix this as part of starting this item, not before - no point fixing
dead code ahead of its first real caller.

Needs its own queue/state (a premove is provisional until the real move happens or is invalidated)
and the `#869E60`/`#648039` tint from the locked palette. Interacts with the interruption
contract: an opponent's move arriving while a premove is queued either fires the premove (if still
legal) or clears it - this is new behavior the contract doesn't cover yet.

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

The contract itself is implemented and manually verified, not covered by an automated test.
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

1. **§2.1 marking auto-update** - small, standalone, no dependencies on anything else in this
   list. Quick to ship correctly.
2. **§2.2 `MovePromptOverlay` theme conformance** - standalone visual work, makes the existing
   promotion/chameleon flow production-quality before more gets built that depends on it.
3. **§2.3 `MovePromptOverlay` mobile presentation** - do the actual design work here (explicitly
   deferred by this doc, see above), then implement. Sequenced after §2.2 so the visual design
   isn't done twice.
4. **§2.4 premove** - extends the controller that already exists; fixes the
   `PremoveDestinations` bug as part of the work.
5. **§2.5 `HexAnnotationController`** - independent of §2.4; could trade places with it.
6. **§2.7 session-level datatype** - needed before either real page (`LiveGamePage` or a
   `AnalysisPage` beyond a smoke test) can exist; natural next step once single-board interaction
   (§2.4-§2.5) is solid.
7. **§2.6 `PositionEditorController`** - depends on §2.7 existing, and benefits from §2.4 being
   done first (see the shared-plumbing question in §2.6).
8. **§2.8 automated interruption-contract tests** - retrofit once §2.4/§2.6/§2.7 give it real
   scenarios to test against.
9. **§2.9 revisit `BoardSurface`'s size** - opportunistic, once its API's real shape is settled by
   §2.4-§2.6 actually using it.

Each numbered item, when its turn comes, likely deserves its own scoping pass (the way
`BoardSurface` and `MoveInteractionController`'s core pass were each scoped down from the full
architecture) rather than being built in one shot against this doc's necessarily-provisional
description of it.
