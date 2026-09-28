# Deferred entries from the board component pass

Source: `C:/Users/mitmi/Documents/GitHub/Intellector/src/gameboard` (old renderer/interaction) and
`C:/Users/mitmi/Documents/GitHub/Libraries/intellectorboard` (rules/geometry primitives). See
`[[board_plan]]` for the architecture actually agreed and for what `BoardSurface` itself covers.

`BoardSurface` (static rendering) and the core click/drag pass of `MoveInteractionController` (item
1 below) are done. Everything else below is still open.

## 1. `MoveInteractionController` (click/drag-to-move, premove, promotion/chameleon disambiguation)

**Done, core pass:** click/drag and click-to-select-then-click-to-move both work end to end -
`src/client/ui/common/board/MoveInteractionController.hx`, its own idle/selected/dragging
mini-state (not a subclass), taking legal-destination/promotion-eligibility/chameleon-eligibility
lookups via the `MoveRules` typedef, with `MoveRulesAdapter.DEFAULT` (same package) as the real
`intellectorboard`-backed implementation - the controller itself imports no `intellectorboard`
rules code, per `[[board_plan]]`. `BoardSurface` gained the glyph/tint/hit-testing API this needed
(`setHexFill`/`resetHexFill`, `addMoveMarker`, `movePieceTo`/`resetPiecePosition`,
`bringPieceToFront`, `hexAtScreenPoint`/`screenPointToBoardPoint`), and `haxefolio.graphics.SvgSurface`
gained `svgCircle` and `screenPointToViewBox` (generic, not board-specific). Promotion/chameleon
disambiguation is `client/ui/common/overlays/move_prompt/MovePromptOverlay.hx`, built on
`HaxeFolioApp.present`/`OverlayContent` per CLAUDE.md's dialog-replacement rule (not the old
`Dialogs.getQueue().add(new PromotionSelect(...))`/`Dialogs.confirm(...)` calls) - deliberately
minimal (no keyboard-modifier shortcuts to skip the prompt, unlike the old dialogs). Verified
in-browser on `AnalysisPage`'s local hot-seat smoke test: hover/selection/marker tints, drag
follow, click-to-select, and turn/color gating (wrong-color piece under cursor does nothing) all
confirmed. The promotion/chameleon overlay path itself compiled and type-checks but wasn't
exercised in-browser (reaching either state needs a longer, specific move sequence) - worth a
dedicated check before this is called fully done.

**Still deferred:** premove (needs `PremoveDestinations` wired into a `MoveRules`-like typedef, a
premove queue, and the `#869E60`/`#648039` tint from `[[board_plan]]`'s palette - none of that
exists yet) and the mandatory interruption contract's *automated* test coverage (the contract
itself is implemented - `notifyPositionChanged`/`notifyConfigChanged` both abort any gesture in
flight unconditionally - but only manually verified so far, not covered by an opponent-move-mid-
drag/rollback/editor-switch test).

**Unplanned but required:** building this exposed that `intellectorboard`'s
`movement`/`plyapplication` packages (`HexCoordsNavigation`, `DirectionGroups`, `MoveDestinations`,
`CoreRules`, `MaterializedPly`, `PlyPerformer`, `PlyRules`) had never actually compiled - nothing in
the frontend called them before `MoveRulesAdapter`/`PlyPerformer` usage in this pass, so Haxe's dead
code elimination let them sit broken indefinitely (instance methods called as static,
`PieceColor`/`Hex` vs `HexCoords` mixups, bare `turnColor` where `position.turnColor` was meant, an
`Array<RawPly>` vs `RawPly` mismatch in `performRandomPly`). Fixed in place, mechanically - a real
compile-error repair, not a game-rules design change - with the user's explicit go-ahead given the
scale. Also carried over: three pre-existing uncommitted `intellectorboard` fixes to `Position`/
`PieceArrangement`/`OccupiedHexesIterator` from the earlier `BoardSurface` pass that were never
committed at the time.

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

**Why deferred:** `AnalysisPage` only mounts a `BoardSurface` smoke test (a static preview at
several sizes/orientations/`boardCoordinates` modes, interim until this lands); no position editor
UI exists yet to drive an actual editable board.

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

**Done for the 6 kinds `intellectorboard.PieceKind` currently has** (`Progressor`, `Aggressor`,
`Dominator`, `Liberator`, `Defensor`, `Intellector` × White/Black = 12 files), copied unchanged
from `C:/Users/mitmi/Documents/GitHub/Intellector/assets/pieces/{Kind}_{Color}.svg` to
`assets/images/common/board/pieces/` (mirroring the existing `assets/images/menubar/`
subfolder-per-owning-area convention — `board` isn't a "page" so it doesn't fit the per-page
image-folder convention directly; `common` is the closest existing analogue to how
`client.ui.common.board` is placed in the source tree). Read via `client.Assets.pieceImage`.

**Resolved:** the old asset set also has a `Yapper_White.svg`/`Yapper_Black.svg` pair with no
corresponding `PieceKind` case (only 6 of the old repo's 7 piece kinds exist in
`intellectorboard.PieceKind`) - confirmed with the user: `Yapper` is an asset for a piece planned
for a future ruleset addition, not yet part of the game. Not copied, and `PieceKind` gets no 7th
case until that piece actually ships in the v3.0 rewrite - revisit then, not as part of any board
rendering/interaction pass.

Each kind's own SVG has a fixed, slightly-different-per-color-variant aspect ratio (its own
viewBox's width/height); `BoardSurface.pieceAspectRatio` hardcodes one constant per kind (from the
White variant) rather than measuring at runtime, since the couple-percent difference between color
variants isn't visually distinguishable and the old runtime-image-load-then-measure approach
(`Piece.hx`'s `onImageLoaded`) is unneeded complexity for static SVG assets whose dimensions are
already known.

## 6. Non-interactive arrows/hex-highlights

**Why deferred:** explicitly deprioritized by the user ("highly compelling but I can live without
it") in favor of scoping this pass to plain `BoardSurface`.

**How to apply:** if wanted later, `HexAnnotationController` (item 2) should already be attachable
to a `BoardSurface` used in a preview context — nothing in the composition design prevents it, it
just isn't exercised by any current call site (challenge overlay preview, incoming-challenge
widget, game/study list rows all show a single static position with no user-drawn marks).
