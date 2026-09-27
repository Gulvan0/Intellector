# Deferred entries from the board component pass

Source: `C:/Users/mitmi/Documents/GitHub/Intellector/src/gameboard` (old renderer/interaction) and
`C:/Users/mitmi/Documents/GitHub/Libraries/intellectorboard` (rules/geometry primitives, read-only
reference — not modified by this pass). See `[[board_plan]]` for the architecture actually agreed
and for what `BoardSurface` itself covers.

Only `BoardSurface` (static rendering of a `Position`, no interaction) is being built now.
Everything below is still open.

## 1. `MoveInteractionController` (click/drag-to-move, premove, promotion/chameleon disambiguation)

**Why deferred:** needs `BoardSurface`'s glyph/tint API to exist first, and no page currently
consuming it (`LiveGamePage`/`AnalysisPage` are still title-only stubs).

**How to apply:** per `[[board_plan]]`'s composition design — a standalone controller, not a
subclass, holding its own idle/selected/dragging mini-state, taking legal-destination /
premove-destination / promotion-eligibility / chameleon-eligibility lookups as injected callbacks
(adapter delegating to `intellectorboard`'s `MoveDestinations`/`PremoveDestinations`/`CoreRules`) —
not importing that library directly. Old reference for the click/drag mechanics themselves (the
*shape* of the state machine, not its coupling) is
`C:/Users/mitmi/Documents/GitHub/Intellector/src/gameboard/states/{NeutralState,SelectedState,DraggingState}.hx`.
Promotion/chameleon disambiguation UI (old `BasePlayableState.askMoveDetails`,
`gameboard/states/BasePlayableState.hx:12-42`) should become a `HaxeFolioApp.showOverlay()` overlay
per CLAUDE.md's dialog-replacement rule, not the old `Dialogs.getQueue().add(new PromotionSelect(...))`/
`Dialogs.confirm(...)` calls.

Must implement the mandatory interruption contract from `[[board_plan]]`: an external `Position` or
config change always cleanly aborts an in-flight drag/selection, tested explicitly (opponent move
arriving mid-drag, a rollback, editor-mode switch).

## 2. `HexAnnotationController` (RMB ring/arrow marks)

**Why deferred:** no interactive board exists yet to attach it to.

**How to apply:** owns right-button gestures only (per `[[board_plan]]`'s input-channel
partitioning). Two RMB fill/ring modes per the locked-in palette in `[[board_plan]]` — new default
is a red (`#FF0000`) ring outline matching the arrow color; a preference toggles back to the old
pinkish fill behavior (`#FF6955`/`#BE3726`), which then sits in the fill-priority list between
premove and last-move. New preference needs registering (name/location TBD — likely alongside
`Preferences.boardCoordinates` in `src/Preferences.hx`; not scoped by this pass). Arrow-drawing
geometry (the triangle/trunk math) ports directly from
`C:/Users/mitmi/Documents/GitHub/Intellector/src/gameboard/components/graphics/ArrowCanvas.hx:25-82`
— pure math, no rendering-technology dependency, just needs to target `SvgSurface`'s path builder
instead of `SVGBuilder` directly.

## 3. `PositionEditorController` (free move / place / clear modes, analysis page)

**Why deferred:** `AnalysisPage` is still a title-only stub; no position editor UI exists to drive
it.

**How to apply:** old reference for the three edit modes (Move/Delete/Set) is
`C:/Users/mitmi/Documents/GitHub/Intellector/src/gameboard/behaviors/{EditorBehavior,EditorFreeMoveBehavior,EditorDeleteBehavior,EditorSetBehavior}.hx`
— again, only the *shape* of the three modes, not the direct `PeripheralEvent`/dialog coupling.
Per `[[board_plan]]`, this replaces `MoveInteractionController` when attached (never both at once),
so it can reuse most of that controller's click/drag plumbing for its own "free move" sub-mode
rather than reimplementing it — worth deciding whether that's a shared base/helper or literal
duplication when both controllers actually exist to compare.

## 4. Session-level ply history / navigation datatype

**Why deferred:** no page yet needs to feed a history of positions into the board — moved out of
scope for `BoardSurface` deliberately (see `[[board_plan]]`'s reasoning), but something still needs
to own it once `LiveGamePage`/`AnalysisPage` are built.

**How to apply:** new `client.datatypes` type (name TBD — `GameSession`/`AnalysisSession` or
similar), replacing the old `GameBoard.plyHistory`/`PlyHistory` (not read in detail this pass — old
file not located/inspected, only referenced via `GameBoard.hx`'s usage). Owns move history and
current navigation pointer; on each navigation step, hands `BoardSurface` a fresh `Position` +
"previous move's from/to hexes." Whatever plays move sounds (old `assets.Audio.playPlySound`,
referenced in `PlayerMoveBehavior.hx:80`/`EnemyMoveBehavior.hx:43`) belongs at this level or in the
page, not in the board — not designed at all this pass.

## 5. Piece asset migration

**Why deferred:** not needed until `BoardSurface` actually renders pieces; flagging now since it's
a straightforward, separable prep task and the mismatch below needs a human decision.

**How to apply:** old assets at
`C:/Users/mitmi/Documents/GitHub/Intellector/assets/pieces/{Kind}_{Color}.svg` — 7 kinds × 2 colors
= 14 files, naming pattern `${PieceType}_${PieceColor}.svg` (e.g. `Progressor_White.svg`). Current
`intellectorboard.primitives.piece.PieceKind` only has **6** values (`Progressor`, `Aggressor`,
`Dominator`, `Liberator`, `Defensor`, `Intellector`) — the old asset set also has a `Yapper_*.svg`
pair with no corresponding `PieceKind` case. Needs a decision before copying: is `Yapper` a
deprecated/renamed piece (skip it), or does `intellectorboard.PieceKind` need a 7th case that just
hasn't been ported yet (out of scope for `intellectorboard` changes without separate approval, per
CLAUDE.md's third-party/library-change rules — though `intellectorboard` is one of the project's own
freely-editable libraries, not third-party, so this is a smaller ask than it might look, just not
one to make silently inside a board-rendering pass).

Proposed target location (not yet created): `assets/images/common/board/pieces/`, mirroring the
existing `assets/images/menubar/` subfolder-per-owning-area convention — `board` isn't a "page" so
it doesn't fit the per-page image-folder convention directly; `common` is the closest existing
analogue to how `client.ui.common.board` is placed in the source tree.

## 6. Non-interactive arrows/hex-highlights

**Why deferred:** explicitly deprioritized by the user ("highly compelling but I can live without
it") in favor of scoping this pass to plain `BoardSurface`.

**How to apply:** if wanted later, `HexAnnotationController` (item 2) should already be attachable
to a `BoardSurface` used in a preview context — nothing in the composition design prevents it, it
just isn't exercised by any current call site (challenge overlay preview, incoming-challenge
widget, game/study list rows all show a single static position with no user-drawn marks).
