# Board component plan

The full design of the board component family and the order to build it in. This file absorbed
`board_interaction_architecture.md` (the rethink discussion; deleted after the merge, never
committed). Everything in §1 is decided by the user unless marked otherwise. `[[board_deferred]]` still
holds the detailed record of what shipped in the `BoardSurface`/`MoveInteractionController`
core-click-drag passes and the bugs found along the way.

## 0. Where things stand

Built (the old structure, which §1 replaces):

- `BoardSurface`: one SVG doing everything (hexes, labels, pieces, markers, tints, hit-testing,
  prompt-placement geometry), every color a constant in it, a full `redraw()` on every
  `setPosition`/`setOrientation`/`setCoordinatesMode`.
- `MoveInteractionController`: click/drag/click-to-select, premove (`PremoveQueue`,
  `notifyMovePlayed`/`notifyPositionReplaced`/`notifyConfigChanged`), the `HexTint` palette in
  `BoardSurface.setHexTint`, fill priority by hand (`restoreHexFill`).
- Board-anchored promotion fan and capture-morph popovers (`client.ui.common.board.move_prompt`).
- The promotion/chameleon `MoveRules` split with `intellectorboard`; piece assets;
  `BoardCoordinatesMode`; the `boardCoordinates` preference subscription on `AnalysisPage`.
- Fixed along the way: `intellectorboard`'s hex-stepping geometry and several dead-code bugs;
  two `SvgSurface` sizing/coordinate bugs in haxefolio.

Details of what was built and verified: §2. Nothing in §1 is implemented yet. Build order: §3.

## 1. Architecture

### 1.1 Why it's split by concern

The previous plan split board interaction **by use case** (`MoveInteractionController`,
`HexAnnotationController`, `PositionEditorController`), each self-contained, with the rules that
kept them from conflicting written as conventions in docs. The user's objection: the approach
isn't flexible or decomposable enough. `MoveInteractionController` alone bundles five concerns:
turning pointer events into hex gestures; picking up and putting down pieces with their visuals;
deciding what's allowed; finishing a move (promotion/chameleon); deciding what happens to the
result. Each new use case would re-bundle all five.

Rejected: one controller with a mode enum (can't be decomposed); named slots on `BoardSurface`
(it would have to know which behaviors exist); making conflicts impossible by having controllers
claim buttons and tint layers (fixes the symptom, not the decomposition). The old
`Board`/`SelectableBoard`/`GameBoard` inheritance chain and `State`×`Behavior` cross-product
stay rejected too (didn't compose, 400-500+ line classes, networking/preferences/dialog concerns
leaking into rendering).

### 1.2 Overview

```
pointer events
   → BoardGestures        hex-level events; knows nothing about pieces (one per board)
   → tools                interpret gestures, show feedback during them:
        PieceMoveTool     pick/drag/drop; behavior chosen by a policy
        PlaceTool / ClearTool   (editor)
        AnnotationTool
   → intents              typed signals, one per consumer
   → consumers            page/session (moves), Premoves, position editor, BoardAnnotations
   → BoardSurface         displays the position it's given; layers redraw
```

Who's who:

| Piece | Job |
| --- | --- |
| `BoardSurface` | Rendering only. Assembles layers sharing a `BoardProjection`. A non-interactive board is a bare `BoardSurface` (plus `HexTints` + `BoardAnnotations` if annotated). |
| `HexTints` | Tint priority, on top of the grid layer. |
| `BoardPalette` | Every board color. |
| `BoardGestures` | Pointer/key events → hex events. |
| Tools | Gestures → intents. Never apply results. |
| `Premoves` | Owns the premove queue, computes the shown position, fires premoves. |
| `BoardAnnotations` | Annotation model + rendering, usable on any board. |
| `BoardInputOptions` | What the user means (annotation mode, auto-promote, ask about chameleon); filled by modifier keys or the mobile control row. |
| `InteractiveBoard` | Assembler used by every page with an interactive board. |

### 1.3 Rendering: `BoardSurface` and its layers

```
BoardSurface                assembler: owns the SvgSurface, the BoardProjection, the layers
├── HexGridLayer            <g>  hex shapes, border, base fills, per-hex fills
├── CoordinateLabelsLayer   <g>  file letters + row numbers (the coordinates mode)
├── PiecesLayer             <g>  piece images (the position) + gesture changes to pieces
├── GlyphLayer              <g>  move markers
└── AnnotationLayer         <g>  annotation rings and arrows (stacking above pieces assumed; confirm when built)
```

- **Composition, not inheritance:** one class per SVG group, stacked bottom to top as above.
- **Labels are their own layer:** the only thing reacting to the coordinates mode, with their own
  colors, between the fills and the pieces.
- **Each layer stores its state keyed by `HexCoords`, never as positions or SVG handles**, and
  draws only into its own group:
  - `HexGridLayer`: the fill per hex (`null` = base). `setHexFill(coords, color)`,
    `resetHexFill(coords)`.
  - `CoordinateLabelsLayer`: the coordinates mode.
  - `PiecesLayer`: the position, plus temporary gesture changes (a piece drawn on another hex or
    hidden while a prompt is open, the dragged piece's offset, the dragged piece on top).
    `setPosition` clears these.
  - `GlyphLayer`: marker hexes. Coordinate-based API (`addMoveMarker(coords)`,
    `clearMoveMarkers()`) instead of raw SVG handles.
  - `AnnotationLayer`: rings and arrows with their colors; knows no annotation rules.
- **Each layer redraws only when its own state changes.** A new position redraws only
  `PiecesLayer`.
- **`BoardSurface` doesn't import `Preferences`:** it receives plain state.
- **haxefolio additions (general):** `SvgSurface.addLayer()`, returning a `<g>`-backed layer
  with the same `svgPath`/`svgText`/`svgImage`/`svgCircle` builders and its own `clear()`
  (haxeui-html5's `SVGBuilder` can wrap an existing element); `SvgSurface.setViewBox(width, height)`.
- **Bug to fix with it:** the `viewBox` height is fixed in the constructor from the coordinates
  mode at that moment, so switching `boardCoordinates` to or from `none` at runtime leaves an empty
  strip or cuts the file letters off (found by reading the code, not reproduced).

### 1.4 `BoardProjection`, flips and geometry changes

- **`BoardProjection`** is owned by `BoardSurface` and handed to every layer. It holds the
  orientation and the board origin and answers `hexCenter(coords)`, `hexAt(point)`,
  `isInLowerHalf(coords)`, `horizontalPosition(coords)`: today's `BoardGeometry` functions with
  the orientation built in. No layer keeps its own copy of the orientation. Tools' hit-testing
  and `MovePrompt`'s placement go through it (via `BoardSurface`'s public methods).
- **A flip keeps everything:** selection, open prompt and premove queue carry over and are
  redrawn in the new orientation.

```haxe
public function setOrientation(orientation:PieceColor):Void
{
    projection.orientation = orientation;

    for (layer in layers)  // bottom to top
        layer.redraw();

    onGeometryChanged.dispatch();
}
```

- **`BoardLayer`** is a minimal interface, `redraw():Void`: clear the own group, redraw from
  stored state. Layers are called directly (`BoardSurface` created them and knows their order).
- **`onGeometryChanged`** is for outsiders only (today: an open prompt repositioning itself).
  `setCoordinatesMode` fires it too, since the viewBox height changes with it.
- Nothing else needs to know about a flip: `HexTints` holds no positions, and tools hold hex
  coordinates whose next hit-test goes through the updated projection.

### 1.5 `HexTints`: tint priority

- **Neither `BoardSurface` nor any layer knows `HexTints` exists.** It works on `HexGridLayer`
  (exposed as `board.grid`) through `setHexFill`/`resetHexFill`.
- Whoever assembles the board creates `new HexTints(board.grid)` once and hands it to the tools.
  "Tools go through `HexTints`" is a rule in `setHexFill`'s doc comment, not compiler-enforced
  (`@:allow(HexTints)` would be the dependency we're avoiding).
- It holds, per tint, the set of hexes covered. A hex shows the highest-priority tint covering it,
  else the base fill. Interface: `add(tint, coords)`, `remove(tint, coords)`, `set(tint, hexes)`,
  `clear(tint)`. Tools never repaint or restore; `restoreHexFill` goes away. Fills survive redraws
  because the grid layer stores them.
- **A tint is a writer's purpose, not a color;** several share a color. Priority is the
  declaration order of `HexTint`, highest first:
  1. `DepartureHover`, `DestinationHover`, `EditorHover` (only one hover is ever active)
  2. `SelectedDeparture`, `PromptAnchor`
  3. `AnnotationFill(color)` ("select hexes by: tint" mode; one per hex, so no conflict between colors)
  4. `Premove`
  5. `LastMove`
  6. base fill

### 1.6 Colors: `BoardPalette`

- **Defaults in code, not CSS:** `BoardPalette.DEFAULT`, an immutable value holding every board
  color. **Every entry is a plain color**; nothing derives one from another (destination hover's
  "base fill, HSL lightness +0.08" was only how its default was found).
- **Each part reads its slice:** `BoardSurface.setPalette` hands colors to the layers; `HexTints`
  gets its own `setPalette` from its assembler and never needs the base fills. Tools never see
  colors.
- **Later, preference customization:** every color set on its own. An app-level
  `BoardPaletteSource` (wired once in `Main.hx`) gives `DEFAULT` with the user's sparse overrides
  (palette key → color, in `Preferences`) and notifies on change. Boards and `HexTints` take the
  palette as input instead of reading a global, so a preferences-page preview can show an unsaved
  palette. On change the affected layers redraw and `HexTints` repaints. Not scheduled (§3).

Default values:

| Entry | Light hex | Dark hex | Note |
| --- | --- | --- | --- |
| Base fill | `#ffcf9f` | `#d18b47` | |
| Border | `#664126` | | also the file-letter color |
| Row number | `#664126` | `#FFD8B2` | on light / on dark hexes |
| Move marker | `#333333` | | |
| `DepartureHover`, `SelectedDeparture` | `#E56A00` | `#E56A00` | |
| `DestinationHover` | `#FFE4C8` | `#D9A068` | only legal destinations get it |
| `PromptAnchor` | `#C79A56` | `#C79A56` | theme token `accentMuted`; literal `accent` would hide black pieces |
| `EditorHover` | `#E56A00` | `#E56A00` | |
| `Premove` | `#869E60` | `#648039` | |
| `LastMove` | `#FDD340` | `#BE9C26` | |
| `AnnotationFill(red)` | `#FF6955` | `#BE3726` | |
| `AnnotationFill(blue)` | `#83ACD4` | `#6F8EAC` | |
| `AnnotationFill(green)` | `#9DD482` | `#83AC6F` | grass green |
| `AnnotationFill(yellow)` | `#D4C482` | `#ACA06F` | calm yellow |
| Annotation ring/arrow | red `#FF0000`, blue `#0000FF`, green `#00CC00`, yellow `#E6E600` | | vivid; every ring and arrow drawn at 75% opacity (as the old `ArrowCanvas.hx:75`); fills are opaque |

### 1.7 `BoardGestures`

One per board. Turns browser pointer and key events into hex-level events; knows nothing about
pieces, positions or rules. Replaces the window listeners, button filtering and
`hexAtClientPoint` calls `MoveInteractionController` does today.

```haxe
onHoverChanged(hex:Null<HexCoords>)                                                 // only when the hex under the cursor changes
onPress(hex:Null<HexCoords>, button:PointerButton, modifiers:Modifiers)
onDragMove(hex:Null<HexCoords>, boardPoint:{x:Float, y:Float}, modifiers:Modifiers)  // while a button is held
onRelease(hex:Null<HexCoords>, button:PointerButton, modifiers:Modifiers)
onEscape()
```

- **Low-level on purpose:** press, move, release, never "click" or "drag". Meaning belongs to
  tools (e.g. "release on the departure turns a drag into a selection" is `PieceMoveTool`'s; the
  annotation tool reads press+release on one hex as a ring, on two as an arrow).
- **`modifiers`:** Shift and Ctrl as held at that event, read from the `PointerEvent` (no keyboard
  listeners). **Cmd counts as Ctrl.**
- **`hex == null` on a press is an outside press,** reported only when the press's target is the
  page container element itself (§1.16).
- **Handled once, here:** hit-testing through `BoardProjection`; releases outside the board or
  window; suppressing the context menu for the right button; touch (no hover on touch);
  **chorded buttons** (a second button pressed while one is held arrives as `pointermove` with a
  changed `buttons` bitmask; turned into proper per-button press/release events).
- **Subscriptions name an event kind and a button,** made inside a tool's `bind(gestures, button)`,
  so the button is visible at the assembler's call site (`moveTool.bind(gestures, Primary)`).
  Hover and Esc have no button; drag moves fire per held button. Each subscription returns a
  `Detachable`. Two subscribers on the same kind and button are allowed.
- **Esc:** listened to in the bubble phase; any Esc with `defaultPrevented` is ignored, so Esc that
  closed a prompt, overlay (`stopPropagation`) or the sidebar (`preventDefault`) doesn't also act on
  the board. haxefolio's menu dropdown Esc (`MenuBarBuilder.hx:48`) marks nothing yet: it needs a
  small general fix (`preventDefault()` when it actually closed a menu).
- **`suspend():Detachable`:** while held, no tool receives anything (hover and every button
  included). `PieceMoveTool` holds it while a prompt is open. `pointerdown` is listened to in the
  **capture phase**, so the press that cancels a prompt is seen while still suspended and ignored
  through its release, whatever the listener registration order (this replaces the order
  dependency documented in `MovePrompt`'s constructor). Moves and releases stay bubble-phase. One
  suspension at a time for now; returning a `Detachable` keeps call sites unchanged if it becomes
  token-based. No "handled" flag for presses: `preventDefault()` on `pointerdown` suppresses the
  follow-up `mousedown` haxeui-html5's `ScreenImpl` listens for. Rejected alternatives: tools
  checking their own state (an annotation tool would still act on a prompt-cancelling press),
  `stopPropagation()` in the prompt (HaxeUI controls underneath would stop working), an invisible
  blocker element (extra element tracking the board's geometry).

### 1.8 Tools and `PieceMoveTool`

A tool receives `BoardGestures` events, shows feedback during the gesture, and reports intents
when it ends. It never applies the result.

**`PieceMoveTool`'s concerns:**

1. Gesture state: `Idle → Selected(from) / Dragging(from) → AwaitingChoice(…)`.
2. Feedback, and only that: the `DepartureHover`, `DestinationHover`, `SelectedDeparture` and
   `PromptAnchor` tints; move markers; the dragged piece and the piece shown moved/hidden under a
   prompt; the prompt itself, holding `gestures.suspend()` while it's open.
3. The completion step: promotion or chameleon, from the policy, `BoardInputOptions` and the
   modifiers held at completion.
4. Reporting intents.

Not its concern: game rules (policy), the premove queue, firing and the `Premove` tint
(`Premoves`), the position's owner, networking, colors, annotations.

**Policy: what's allowed** (replaces `MoveInteractionConfig`):

```haxe
interface PieceMovePolicy
{
    // Move, Premove, FreeMove, or null (board inert)
    public function pickMode(position:Position):Null<PieceMoveMode>;

    public function canPickUp(position:Position, mode:PieceMoveMode, hex:HexCoords):Bool;

    // null = any hex (editor free move)
    public function destinations(position:Position, mode:PieceMoveMode, from:HexCoords):Null<Array<HexCoords>>;

    // None / Promotion / Chameleon(capturedKind) / PremoveChameleon
    public function completion(position:Position, mode:PieceMoveMode, from:HexCoords, to:HexCoords):CompletionKind;

    public function showsMarkers(mode:PieceMoveMode):Bool;
}
```

| Policy | Pieces you can pick | Destinations | Completion | Result |
| --- | --- | --- | --- | --- |
| Live game, your turn (`Move`) | your color | legal moves | promotion / chameleon prompt | `playMove` |
| Live game, opponent's turn (`Premove`) | your color | geometry only, no markers | promotion chosen up front; optional chameleon prompt (§1.17) | `PremoveIntent.Queue` |
| Analysis (`Move`) | whichever side is to move | legal moves | promotion / chameleon prompt | `playMove` |
| Editor (`FreeMove`) | any piece | any hex | none | `EditIntent.MovePiece` |

- The mode is taken at pick-up and kept, except when a gesture survives a move (§1.11).
- **Whose turn comes from the real position, not the shown one** (queued premoves can flip the
  shown turn): the live-game policy asks `Premoves`.
- **Game-rules queries are injected** (`MoveRules`, implemented by `MoveRulesAdapter`): policies and
  `Premoves` receive them; the tool itself has no rules logic.

**Public interface:**

```haxe
class PieceMoveTool
{
    public function new(board:BoardSurface, tints:HexTints, options:BoardInputOptions, policy:PieceMovePolicy, playMove:Signal<RawPly>, premoveIntents:Signal<PremoveIntent>, editIntents:Signal<EditIntent>)

    // Press/drag/release on `button`, plus hover, Esc and outside presses; detaching aborts any gesture
    public function bind(gestures:BoardGestures, button:PointerButton):Detachable

    // Aborts any gesture in flight, prompt included
    public function setPolicy(policy:PieceMovePolicy):Void

    public function dispose():Void
}
```

- Handlers stay private; `bind` makes the subscriptions. The mobile annotate mode detaches the
  move tool's binding and binds `AnnotationTool` to `Primary`.
- No `notify*` methods: the tool subscribes to `BoardSurface`'s position-changed event and reads
  the shown position from the board. A flip needs nothing from it.
- `CancelAll` (§1.12) comes from the tool because every user-side cancellation rule applies only
  "when nothing is picked up", which is the tool's state.

The editor's place and clear modes are small separate tools emitting `EditIntent`.

### 1.9 Intents and `Signal`

Intents are split by **who consumes them**, so every consumer's `switch` is exhaustive and
compiler-checked; a tool may emit into several.

```haxe
// To the page / game or analysis session. Not an enum: it would have a single case.
// Also dispatched by Premoves when it fires a queued premove.
playMove:Signal<RawPly>

enum PremoveIntent     // to Premoves
{
    Queue(ply:RawPly, morphInto:Null<PieceKind>);
    CancelAll;
}

enum EditIntent        // to the position editor
{
    MovePiece(from:HexCoords, to:HexCoords);
    PlacePiece(hex:HexCoords, piece:PieceData);
    ClearHex(hex:HexCoords);
}

enum AnnotationIntent  // to BoardAnnotations, or later the analysis session
{
    AnnotateHex(hex:HexCoords, color:AnnotationColor);
    AnnotateArrow(from:HexCoords, to:HexCoords, color:AnnotationColor);
    ClearAnnotations;
}
```

Rejected: one enum per tool (`PieceMoveTool` serves the session *and* the editor); a single
`BoardIntent` (impossible cases under `default:` silence the compiler). A wrapper enum can give
one stream later if needed (logging, tests).

**`morestd.Signal<T>`** (new, general; morestd has only `Detachable`):

```haxe
class Signal<T>
{
    public function subscribe(handler:T->Void):Detachable
    public function dispatch(value:T):Void
}
```

`InteractiveBoard` owns `playMove`, `premoveIntents`, `editIntents` and `annotationIntents` and
passes them to the tools it creates. Tools only dispatch; consumers subscribe; pages detach in
`onClose`:

```haxe
// Live game page
playMoveHandle = board.playMove.subscribe(onMoveChosen);

private function onMoveChosen(ply:RawPly):Void
{
    var position:Position = session.applyAndSend(ply);
    board.setPosition(position, Move);
}
```

A fired premove arrives the same way as a normal move; calling `setPosition` in the same handler
means the board never briefly loses it.

### 1.10 `Premoves` and position-change causes

Created inside `InteractiveBoard` when the page enables premoves (live games only); sits between
the real position and the board:

```
page ──setPosition(real, Move | Replacement)──▶ InteractiveBoard ──▶ Premoves ──setPosition(shown, cause)──▶ BoardSurface
                                                                       │  ▲
                                                     premoveIntents (Queue/CancelAll)
                                                                       ▼
                                                         playMove (fired premove) ──▶ page
```

- **Holds `PremoveQueue`** (pure: `add`, `applyTo`, `takeNext`), each entry with its chameleon
  choice.
- **Computes the shown position** (real + queue), passes it to `BoardSurface`, and paints
  `tints.set(Premove, queue.hexes())`. The board simply displays the position it's given; no
  separate premove preview.
- **Fires premoves:** when a real position arrives with cause `Move` and it's the user's turn, the
  head is validated against the real position (including the chameleon rule, §1.17). Valid → to
  `playMove`. Invalid → the whole queue is dropped.
- **Obeys `PremoveIntent`;** clears the queue on a `Replacement`, when premoves are disabled, and
  at game end.
- **Answers whose turn it really is** for the live-game policy.

`BoardSurface`'s position-changed event carries a cause:

| Cause | Comes from |
| --- | --- |
| `Move` | the opponent's move, or the user's own, fired premoves included |
| `Replacement` | history navigation, rollback, reset |
| `PremovesChanged` | a premove queued or cancelled |

Tools keep a gesture only on `Move`; annotations clear on all three. A queue change never happens
mid-gesture, so `PremovesChanged` mainly keeps the event from mislabelling the change.

### 1.11 A gesture in flight when the position changes

- **A drag or a selection survives a `Move`** (as on Lichess): a premove being dragged or selected
  when the opponent's move arrives stays picked up, and completing it plays a normal move. The
  tool re-asks the policy (mode, destinations, markers) and updates hover and markers.
  - Only if the same piece (kind and color) is still on its departure hex in the new shown
    position; otherwise it's aborted.
  - Any other cause aborts it.
- **A prompt is always interrupted:** it closes and that move or premove is dropped.
- **Flip:** keeps everything (§1.4). A policy change (`setPolicy`) or unbinding aborts.

### 1.12 Premove cancellation

User inputs that clear the queue (all via `PremoveIntent.CancelAll` from the tool):

- Esc with no piece picked up and no prompt open.
- A left-click, with no piece picked up, on a hex that doesn't start the next premove: an empty
  hex (in the shown position) or a piece that can't be picked up (e.g. an opponent's). A click on
  one of your own pieces starts the next premove instead.
- An outside press with no piece picked up.

Inputs that leave it alone:

- Right-clicks (they only annotate).
- A left-click on a non-destination while a piece is picked up: only puts the piece down
  (re-selecting another own piece works).
- Esc while a piece is picked up: only puts it down.
- Esc or a press outside an open prompt: only closes it and cancels that move.

Programmatic drops (by `Premoves`): a `Replacement`, premoves disabled, game end, an invalid head
when the turn comes, a chameleon choice impossible when it fires.

### 1.13 Modifiers, `BoardInputOptions`, the mobile control row

Touch screens have no right button or modifier keys; visible UI provides the capabilities and the
keys are desktop shortcuts.

- **`BoardInputOptions`:** annotation mode (off or one of four colors), auto-promote to Dominator,
  ask about chameleon (premoves only). Filled by modifier keys on desktop and by the control row
  on mobile; tools can't tell which.
- **When modifiers are read:** a move or premove at its completion (the drop or the destination
  click); an annotation at its first press, never changed after.
- **Desktop meanings:**
  - Shift on a promotion (move or premove): no prompt, promote to Dominator. Subject to the
    auto-promote preference: `never` ignores Shift, `always` promotes without it.
  - Shift on an eligible premove (§1.17): opens the chameleon prompt. Never conflicts with the
    above (promotions are Progressor moves, which the chameleon prompt excludes).
  - Annotation color from the modifiers at the first press: none → red, Shift → blue, Ctrl →
    green, Shift+Ctrl → yellow.
- **Mobile control row:**
  - **Shown when the primary pointer is coarse** (`(pointer: coarse)`), not by width: a landscape
    phone keeps it, desktop never shows it. Needs a general haxefolio capability: an input-type
    value with a change subscription, next to the width breakpoint (`ResponsivityController`).
  - **Placement:** a thin row above the board; in the wide layout, a thin column to its left.
  - **"Annotations:"** + five toggle buttons, exactly one selected, the cross by default. Cross =
    normal mode (moves). Each colored round button switches `Primary` to annotating in that color
    (the assembler rebinds `AnnotationTool` to `Primary` in place of `PieceMoveTool`).
  - **Auto-promote to Dominator** toggle: moves and premoves; starts at the preference (on only for
    `always`) each time a board opens; never writes back.
  - **Ask about chameleon** toggle: premoves only; starts off; when on, every eligible premove
    opens the prompt.
  - **Preference "Show board controls": auto / always / never** (`auto` = the coarse-pointer rule;
    the others cover touchscreen laptops and tablets with a trackpad).

### 1.14 `InteractiveBoard`

The assembler used by every page with an interactive board (live game, analysis). Holds
`BoardSurface`, `BoardGestures`, `HexTints`, `BoardAnnotations`, the tools, `Premoves` (when
enabled), `BoardInputOptions`, the intent signals and the control row, and lays the row out next
to the board. The control row is an ordinary component in `client.ui.common.board`; it only writes
`BoardInputOptions`.

Public surface (shape, names to settle when built): `setPosition(position, cause)`,
`setOrientation`, `setCoordinatesMode`, the four signals, options for premoves and for page-owned
annotations.

**Preferences:** `InteractiveBoard` subscribes to the board preferences itself (decided):
coordinates, "select hexes by", auto-promote, show board controls, the two annotation-clearing
preferences, premoves. It detaches them on disposal. `BoardSurface` and `BoardAnnotations` keep
receiving plain values, so non-interactive boards (previews) stay fixed unless their owner says
otherwise. Pages no longer subscribe for their interactive board.

### 1.15 Annotations

Usable without `InteractiveBoard` (e.g. a shared or replayed position):

- **`AnnotationLayer`:** draws rings and arrows (§1.3). Arrow geometry ports from the old repo's
  `ArrowCanvas.hx:25-82` (pure math).
- **`BoardAnnotations`:** the model. One hex annotation per hex and one arrow per *ordered* pair,
  each with a color; renders hex annotations as rings (`AnnotationLayer`) or as
  `AnnotationFill(color)` tints (`HexTints`) per the "select hexes by" preference, switching live;
  arrows always on `AnnotationLayer`. Built from a `BoardSurface` and a `HexTints`. A
  non-interactive annotated board is `BoardSurface` + `HexTints` + `BoardAnnotations`.
- **`AnnotationTool`:** reports `AnnotationIntent`s; `InteractiveBoard` routes them to
  `BoardAnnotations` by default, and a page that owns annotations (later the analysis page, per
  ply-tree node) turns that off and subscribes itself. Draws its own feedback (the arrow being
  dragged) on `AnnotationLayer`.

Rules:

- Colors coexist, one annotation per hex and per ordered pair; A→B and B→A are distinct.
- **Toggle:** drawing an annotation already present (hex or same ordered pair) removes it,
  whatever its color, and draws nothing. The rule lives in `BoardAnnotations`.
- **Clearing all**, each preference-gated:
  - *On a click/tap* (preference "clear annotations on left-click / tap in normal mode"):
    `AnnotationTool.bind(gestures, drawButton)` also listens to `Primary` presses and outside
    presses when the draw button isn't `Primary`, and emits `ClearAnnotations`. Desktop: any
    left-click on the board (including one that moves a piece) or outside press. Mobile cross
    mode: any tap. Mobile color mode: taps draw, never clear; outside taps don't clear.
  - *On any shown-position change* (preference "clear annotations when the position changes"):
    moves, replacements, history navigation, premoves queued or cancelled. With "follow latest
    move" off and an older position on screen, a move doesn't change the shown position and so
    doesn't clear. `BoardAnnotations` reacts to the board's position-changed event itself.
- Not kept per position: with the position-change clearing off, annotations just stay.

### 1.16 Outside presses

- Page background only: a press whose target is the page container element itself. Never a
  control, the menubar, the control row, or the board's own non-hex areas.
- Effect: deselects the departure if one is selected, otherwise cancels the premove queue; in both
  cases clears annotations if the click-clearing preference is on.
- Prompts have no notion of outside presses: a press is inside the prompt or on its scrim, and
  neither reaches `BoardGestures`.

### 1.17 Board prompts

**Scrim:** while a promotion/chameleon prompt is open, a very light scrim covers the whole
viewport, board and menubar included: ink `rgba(42,33,26,…)` at about 0.08-0.12, exact value
settled in the browser (the board must stay readable). A press on it only cancels the prompt;
nothing underneath acts. `gestures.suspend()` stays (the scrim doesn't stop `BoardGestures`'
window-level hit-testing). It must stack above the menubar (check HaxeUI's `Screen` order).
Wheel scrolling still scrolls; the prompt already repositions on scroll. Also recorded in
`knowledge/intellector-style.md` §2.5 and `knowledge/past_decisions/promotion-and-morph-popovers.md`.

**Piece ring** (the layout of the promotion prompt and the premove chameleon prompt; replaces the
fan):

```
     [Dom]   [Lib]
 [✕]   (hub)    [Agg]
     [Pro]   [Def]
```

- Six fixed slots at the anchor hex's **vertex angles** (flat-topped hexes: two level, four
  diagonal), the same for every anchor and both prompts. **The Progressor slot stays empty in the
  promotion prompt.** In the chameleon prompt the capturing piece's own kind keeps its slot,
  styled as "stay".
- Button diameter 0.9 × the hex's on-screen height, at least 44 px. Radius =
  max(`diameter + gap`, `side length + diameter / 2 + gap`), gap 6 px.
- **Hub:** a disc showing the moving piece, the size of a ring button, not a button (a press on it
  counts as inside the prompt). Unshifted it sits over the anchor; near a viewport edge the whole
  ring slides inward as a unit (`shiftIntoViewport`) and still reads as a self-contained widget.
  The anchor keeps its tint.
- Rejected edge treatments: sliding without a hub; squeezing into an arc; a connector line;
  reserving margin around the board.
- `fanCenters`, the tilt search and the edge-file quarter circle in `MovePrompt` go away.

**Capture-morph popover** (normal moves): unchanged ("Use aura?" header + close, "Become X" /
"Stay Y", 390 px, placed on the side facing the board's centre).

**Premove chameleon prompt:**

- Opens (Shift on desktop, the toggle on mobile) only for premoves that aren't Progressor moves,
  Intellector moves or the Intellector–Defensor swap (from either side), and only when the aura is
  active in the shown position.
- Options: Dominator, Liberator, Aggressor, Defensor, Progressor (the capturing piece's own kind
  included). Cancel: this premove isn't added; queued ones stay.
- Picking kind K, checked when the premove fires: another kind → if that morph is possible (the
  move captures a K with the aura active), move and morph; otherwise don't move, even if a plain
  capture or another morph is possible, and cancel all queued premoves. The capturing piece's own
  kind → move; if it captures, don't morph.
- The shown position reflects the morph; later premoves of that piece move as the morph-into kind.
- Without the prompt, a premove plays as no-morph (as today).

### 1.18 Preferences

Added to `Preferences.hx` (haxefolio builds the preferences window from the registry; each needs
locale strings):

| Preference | Values |
| --- | --- |
| Show board controls | auto / always / never |
| Auto-promote to Dominator | never / when Shift is held / always (mobile: the first two are the same) |
| Clear annotations on left-click / tap in normal mode | on / off |
| Clear annotations when the position changes | on / off |
| Select hexes by | tint / circle |

Existing ones the board uses: `boardCoordinates`, `premoveEnabled`, `followLatestMove`.

### 1.19 Outside the board

- **Ply history and navigation** live in a session-level datatype the page owns (§3 step 28),
  replacing the old `GameBoard.plyHistory`. On navigation it hands the board a position (cause
  `Replacement`) and the last move's hexes (for `LastMove`). Move sounds belong there or in the
  page.

## 2. Already built (record)

### 2.1 Board coordinates follow the preference (on `AnalysisPage`)

`AnalysisPage` subscribes its live board with
`Preferences.boardCoordinates.onChange(mainBoard.setCoordinatesMode)` and detaches in `onClose`.
The three preview boards stay fixed at `NONE`/`FILES_ONLY`/`ALL` on purpose (side-by-side demo).
Once `InteractiveBoard` exists, it subscribes itself (§1.14) and this page-level subscription goes away.

### 2.2 Promotion fan and capture-morph popovers

`client.ui.common.board.move_prompt.MovePrompt` (+ `PromptButton`), styled by `.intellector-prompt-*`
in `main.css`; spec in `knowledge/past_decisions/promotion-and-morph-popovers.md` ("Revisions" is
current). Fan: four options + cancel on an arc toward the board's interior (being replaced, §1.17).
Capture morph as in §1.17. Cancel by cross/close, outside press, Esc. While a choice is pending, the
moving piece is drawn on the anchor, a captured piece hidden, the anchor tinted. Supporting
changes: `haxefolio.ElementShadow` public; `SvgSurface.viewBoxPointToClient`/`viewBoxUnitInPixels`;
`BoardSurface.movePieceToHex`, `setPieceVisible`, `hexClientCenter`, `hexClientHeight`,
`horizontalPosition`, `isInLowerHalf`, public `pieceAspectRatio`. Locale: global
`intellector.piece.<kind>.<case>` names; `intellector.board.prompt.*` templates name their case via
a `.case` key. Keyboard focus/arrow keys/focus rings: not built, by decision.

Verified in-browser: promotion and capture by click; picking; cancel by Esc, outside press, cross,
close; navigating away with a prompt open; promotion on files a, c, i and a capture near the
centre; following a viewport resize. **Not verified:** the drag route into a prompt, a position
change under an open prompt, page scroll, a ~390 px viewport, long Russian labels.

### 2.3 Premove in `MoveInteractionController` (not wired into a real page)

`MoveInteractionConfig {allowedToMove, premovesEnabled}`; `MoveRules.getPremoveDestinations`
(backed by `PremoveDestinations`, bugs fixed); `PremoveQueue` (pure FIFO of `RawPly`; queued
premoves drawn as already played, so a piece can be premoved again from its destination; firing
validates only the head). Promotion chosen at queue time; chameleon never asked; no markers in
premove mode. Page contract `notifyMovePlayed`/`notifyPositionReplaced`/`notifyConfigChanged`
(replaced by §1.10).

Verified with a temporary harness (random Black replies after 4 s): queue and tint on light and
dark hexes, void-click clear, chaining the same piece, invalid head dropping everything behind it
(intended), `notifyPositionReplaced` discarding the queue, markers back on the user's turn. **Not
verified:** the drag route, premove interrupted mid-prompt.

## 3. Build order

Rules for every step: the project builds, `AnalysisPage` keeps working, and the step ends with a
browser check (listed per step). Temporary harness code (flip button, replies harness, debug
logging) is removed in the step that says so. Each step still gets its own short scoping pass
before implementation, as `BoardSurface` and `MoveInteractionController` did.

**Phase A: rendering foundation** (no behavior change except fixes)

1. **`morestd.Signal<T>`.** Check: builds (first used in step 6).
2. **haxefolio `SvgSurface.addLayer()` and `setViewBox()`.** Check: every existing board renders
   unchanged.
3. **`BoardProjection`** replaces the orientation-taking `BoardGeometry` calls in `BoardSurface`.
   Check: previews in both orientations and hit-testing unchanged.
4. **Layers, part 1: `HexGridLayer` (stored per-hex fills) and `CoordinateLabelsLayer`,** with
   the `viewBox` bug fixed. `BoardSurface`'s public API unchanged (`setHexTint` now writes to the
   grid). Check: toggling the coordinates preference live adds/removes letters and adjusts the
   height; tints still work.
5. **Layers, part 2: `PiecesLayer` (gesture changes stored by hex) and `GlyphLayer`
   (coordinate-based markers);** `setPosition` redraws only the pieces. `MoveInteractionController`
   adapted to the marker API. Check: moves by click and drag, markers, both prompts.
6. **Flip:** `setOrientation` redraws every layer from its state, `onGeometryChanged`, `MovePrompt`
   repositions on it; a temporary flip button on `AnalysisPage`. Check: flip with a selection,
   markers, premove tints, a prompt open; flips mixed with position changes.
7. **`BoardPalette`:** every color moves into `BoardPalette.DEFAULT` (including the entries used
   later); layers read their slice; `setPalette` exists. Check: nothing looks different.
8. **`HexTints`:** the new `HexTint` enum and priority; `MoveInteractionController` migrated
   (`restoreHexFill` and `BoardSurface.setHexTint` removed). Check: hover over premove hexes,
   selection over premove, prompt anchor; §4 items 1 and 3 (without dragging).

**Phase B: input and tools**

9. **`BoardGestures`:** events with modifiers, chorded buttons, context-menu suppression, outside
   press (page container), Esc (bubble phase, `defaultPrevented`), `suspend()` (capture-phase
   `pointerdown`). Not consumed yet. Check: a temporary console logger on `AnalysisPage`, removed at
   the end of the step.
10. **haxefolio menu dropdown Esc fix** (`preventDefault()` when a menu was closed). Check: Esc
    closing a dropdown is marked handled.
11. **Minimal `InteractiveBoard` + `PieceMoveTool` (`Move` mode) + analysis policy + `playMove`.**
    The prompt holds `gestures.suspend()`; the registration-order comment in `MovePrompt` goes.
    `AnalysisPage` switches to `InteractiveBoard`; `MoveInteractionController` stays only until
    step 12. The `boardCoordinates` subscription moves from `AnalysisPage` into `InteractiveBoard`
    (later preferences are subscribed there as their steps add them). Check: click/drag moves,
    promotion and chameleon prompts, every cancel path, outside press deselecting, release outside
    the board, the coordinates preference still followed live.
12. **`Premoves` + live-game policy + `PremoveIntent` + position-change causes**
    (`setPosition(position, cause)`). `MoveInteractionController` and `MoveInteractionConfig`
    deleted. A temporary replies harness on `AnalysisPage` (random replies after a few seconds),
    kept until step 19. Check: everything in §2.3's verified list.
13. **Premove cancellation rules** (§1.12): `CancelAll` from the tool, Esc, the picked-up cases.
    Check: each rule in §1.12.
14. **Gesture survival** (§1.11): drag and selection survive a `Move`, same-piece check, policy
    re-asked; other causes abort; prompts interrupted. Check with the harness; §4 item 2.

**Phase C: prompts and promotion/chameleon options**

15. **Prompt scrim.** Check: a press on the menubar with a prompt open only cancels it; the board
    stays readable; tune the opacity.
16. **Piece ring with hub; promotion migrated** (Progressor slot empty), fan code removed. Check:
    anchors on files a-i, both edge rows, a ~390 px viewport, viewport edges, flip and scroll with
    the ring open.
17. **Auto-promote to Dominator:** the preference, `BoardInputOptions` (desktop source), Shift at
    completion. Check: moves and premoves under all three values.
18. **Premove chameleon prompt, queuing side:** eligibility (aura in the shown position), the ring
    with all five kinds, queue entries carrying the choice, the shown position morphing, later
    premoves moving as the morph-into kind. Check with Shift.
19. **Premove chameleon prompt, firing side:** validation when the premove fires, impossible morph
    cancels everything, own kind = no morph. Check with the harness, which is removed at the end of
    this step.

**Phase D: annotations (desktop)**

20. **`AnnotationLayer` + `BoardAnnotations` (ring mode)**: rings and arrows at 75% opacity, toggle
    and coexistence rules, palette entries. Check: annotations set from code on a *preview*
    (non-interactive) board, then removed.
21. **`AnnotationTool` on the right button + `annotationIntents` + default routing:** color from
    modifiers at the first press, arrow preview while dragging. Check: four colors, toggling,
    A→B next to B→A, one per hex.
22. **Clearing:** on left-click/outside press and on shown-position changes, with both
    preferences. Check: each case in §1.15, including premove queue changes.
23. **"Select hexes by" preference:** tint mode through `AnnotationFill(color)`, switching live.
    Check: §4 item 5, then the whole §4 list.

**Phase E: touch**

24. **haxefolio input-type capability** (coarse pointer, change subscription). Check: devtools
    device emulation.
25. **Control row layout + "Show board controls" preference:** row above, column left in the wide
    layout; buttons not yet wired. Check: visibility under each value, both layouts.
26. **Control row annotation modes:** rebinding `AnnotationTool` to `Primary`, cross-mode tap
    clearing. Check: emulated touch.
27. **Control row toggles:** auto-promote (starts from the preference), ask about chameleon.
    Check: emulated touch, moves and premoves.

**Phase F: sessions and editor**

28. **Session datatype** (§1.19): history, navigation pointer, `Move` vs `Replacement`, follow
    latest move. Prerequisite for `LiveGamePage` and a real `AnalysisPage`.
29. **`LastMove` tint.** Check: navigation and new moves.
30. **Editor free move:** editor policy, `EditIntent.MovePiece`. Check: any piece to any hex.
31. **Editor place/clear tools + `EditorHover` tint.** Check: placing and clearing; switching
    modes mid-gesture aborts cleanly.
32. **Automated tests:** `PremoveQueue` (pure) and the interruption/survival rules. The project has
    no test setup yet; choosing one is part of this step's scoping.

Not scheduled: palette customization through preferences (path in §1.6).

## 4. Verification checklist (user requirement)

1. Resize and redraw: nothing lost, everything resized and repositioned correctly, across window
   resizes, flips, redraws and non-move position updates in any combination.
2. The same while the user is dragging a piece.
3. Move markers (dots and rings) through all of the above.
4. Coordinate labels follow the preference live: drawn or hidden, viewBox height adjusted.
5. Annotated hexes follow the "select hexes by" preference live: tint removed and ring drawn, or
   the reverse.

## 5. Open questions

None at the moment.
