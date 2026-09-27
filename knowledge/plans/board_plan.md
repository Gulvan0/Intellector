# Board component plan

Discussed and scoped with the user before any code was written — this doc captures the agreed
architecture for the whole board component family, even though only the first slice
(`BoardSurface`) is being built now. See `[[board_deferred]]` for everything explicitly not part of
this pass.

## Why not a straight port of the old `Board`/`SelectableBoard`/`GameBoard` hierarchy

The old repo (`C:/Users/mitmi/Documents/GitHub/Intellector/src/gameboard`) uses a 3-level
inheritance chain (`Board` → `SelectableBoard` → `GameBoard`), crossed with a second, separate
`State` × `Behavior` hierarchy (5 states × ~8 behaviors) for interaction handling. Rejected for
this port, per the user's explicit reasoning:

1. Inheritance doesn't compose — combining features (e.g. "selectable but not a full game board")
   only works because it happens to sit on the one inheritance path that was built; anything off
   that path can't be assembled. The State × Behavior cross-product is the same problem twice over
   (25–40 meaningful combinations, most unused, each pair having to know about the other).
2. Class sizes (`Board.hx` 547 lines, `GameBoard.hx` 403 lines) are themselves evidence of
   over-accumulated responsibility, and a direct symptom of (1) — there was nowhere smaller to put
   the logic once inheritance was the only decomposition tool.
3. `GameBoard` owns ply history (`plyHistory:PlyHistory`, `GameBoard.hx:54`) and drives navigation
   (`prev`/`next`/`home`/`end`, `GameBoard.hx:214-240`) itself — game/session state that shouldn't
   live inside a rendering+interaction component.
4. `GameBoard`/`IBehavior` import `net.shared.board.Rules`, `Preferences`, `Dialogs`, `Audio`,
   `net.shared.ServerEvent`, `LoginManager` directly (`PlayerMoveBehavior.hx`,
   `EnemyMoveBehavior.hx`). Same class of problem `[[feedback_service_module_coupling]]` already
   flags for service modules — a UI component must not import `net.*`/`Preferences`/`Dialogs`
   itself; it receives pure state and emits pure events.
5. Mid-gesture interruption (opponent's move arrives while the player is mid-drag, a rollback
   arrives, editor mode changes) was handled ad hoc, scattered across every `ServerEvent` case in
   every behavior (e.g. `EnemyMoveBehavior.hx:91-99` calling `state.exitToNeutral()` inline). Needs
   to be a single, guaranteed contract instead.

## Revised architecture: composition, not inheritance

**`BoardSurface`** (this pass) is the only thing that always exists. It owns geometry and rendering
for a given `Position` — nothing else. A non-interactive preview (challenge overlay, incoming
challenge widget, game/study list rows) *is* a bare `BoardSurface`; there is no separate
"non-interactive board" class to keep in sync with it.

Everything interactive is a **controller** (deferred, not built this pass) — a small standalone
class holding a reference to `BoardSurface` plus its own config, attached only where needed:

- `MoveInteractionController` — click/drag-to-move, premove marking, promotion/chameleon
  disambiguation. One private internal mini-state (idle/selected/dragging), not a swappable
  polymorphic `IBehavior`; the differences between "it's my turn" / "premoving" / "spectating" /
  "history-browsing" collapse to a handful of config values (allowed-to-move color, premove
  enabled, markers enabled, hover enabled) that the page sets — not separate classes.
- `HexAnnotationController` — RMB rings/arrows (the old `SelectableBoard` slice).
- `PositionEditorController` — free move / place / clear modes for the analysis position editor.

Ply history and move navigation move **out of the board entirely**, into a session-level datatype
(`client.datatypes`, name TBD — `GameSession`/`AnalysisSession` or similar) owned by the page. Each
navigation step hands `BoardSurface` a `Position` + "previous move's from/to hexes" to display; the
board never remembers a history of its own.

Game-rules queries (`intellectorboard`'s `MoveDestinations.getPossibleDestinations`,
`PremoveDestinations.getPossiblePremoveDestinations`, `CoreRules`) are **injected into
`MoveInteractionController` at construction**, not imported by it — a small typedef bundling
legal-destination lookup, premove-destination lookup, and promotion/chameleon-eligibility
predicates. Real call sites pass a thin adapter delegating to `intellectorboard`; the controller
itself has no compile-time dependency on that library.

### Why controllers won't fight each other

Not runtime arbitration — non-overlapping ownership by construction:

1. **Input-channel partitioning.** Move/editor interaction owns left-button gestures;
   `HexAnnotationController` owns right-button gestures. `BoardSurface` refuses to attach two
   controllers claiming the same channel.
2. **Single writer for hex fill.** Only one "state" controller is ever attached at a time —
   `MoveInteractionController` XOR `PositionEditorController`, never both (editor mode *replaces*
   move interaction). `HexAnnotationController` never touches fill, only its own ring/arrow glyphs.
3. **Self-tracked glyphs.** `BoardSurface`'s glyph API creates/removes primitives and hands back a
   raw handle; it holds no shared per-hex ownership map. Each controller tracks only the handles it
   created.
4. **Mandatory interruption contract.** Feeding `BoardSurface` a new `Position` or feeding a
   controller a new config must cleanly abort any gesture in flight (piece snaps back, selection
   clears) — a documented, tested guarantee, not a per-`ServerEvent`-case afterthought like the old
   code.

## Rendering: one SVG surface, not one component tree per hex

Traced why the old renderer is heavy (see `[[board_deferred]]` item 1 for the full old-vs-new DOM
count comparison): each `Hexagon` pre-creates 7 full hex shapes (one `haxe.ui.components.Canvas`/
inline-`<svg>` per selection state, `Hexagon.hx:105-141`) plus a label/dot/circle canvas — 10
DOM subtrees per hex, always present, toggled via `.hidden` — and `Hexagon.resize()` tears down and
rebuilds all of them, for all 59 hexes, on every resize (`Hexagon.hx:68-79`).

This is fixable structurally rather than by micro-optimizing the old shape:

- `haxe.ui.backend.html5.svg.SVGPathBuilder.fill()`/`.stroke()` (confirmed in
  `C:/HaxeToolkit/haxe/lib/haxeui-html5/git/haxe/ui/backend/html5/svg/SVGPathBuilder.hx:105-123`)
  are plain `element.setAttribute(...)` calls on a real `PathElement` — restylable after the fact,
  if the caller keeps the element handle. One hex needs **one path, drawn once**, restyled via
  attribute writes for every later state change — not 7 duplicate pre-drawn shapes.
- A fixed internal `viewBox` scales for free via CSS (`width:100%;height:100%` on the SVG root,
  `aspect-ratio` on its container) — no JS resize listener, no debounce timer, no path
  recomputation on resize at all. This replaces `Board.hx`'s `ResizeData`/`Timer.delay` machinery
  entirely.
- Per the user's explicit choice, this is **not** built on `haxe.ui.components.Canvas` (which would
  need `@:access` hacks to reach per-shape restyling, same as the old `ArrowCanvas.getBuilder()`
  pattern) but on a **new generic primitive in HaxeFolio**: `haxefolio.graphics.SvgSurface` (new
  `haxefolio.graphics` package — no prior art in the library; closest sibling is
  `haxefolio.structure`). A HaxeUI-tree-compatible component wrapping a raw `<svg>` element with a
  fixed `viewBox`, exposing typed child-element builders (path/image/text) that return live handles
  for later attribute updates. Reusable by any future page needing custom vector graphics, not
  Intellector-specific. The exact low-level mounting mechanism (how a HaxeUI component's native
  element becomes an `<svg>` rather than a `<div>` under the HTML5 backend) is implementation work
  for when this is actually built — flag back to the user if it turns out not to be straightforward.
- Pieces and coordinate labels also live **inside** the same SVG (`<image href="...svg">` / `<text>`
  elements), not as separate HaxeUI `Image`/`Label` components layered on top — so they scale with
  the board for free too, and dragging a piece (later, in `MoveInteractionController`) is just an
  `x`/`y` attribute write.
- Hex border overlap is preserved unchanged: each hex still draws its own full centered stroke: at
  a shared edge, both neighboring hexes' strokes land on the exact same coordinates and coincide
  (not double up); at the outer edge, the lone hex's stroke is the same thickness. Not "optimized"
  into single-drawn shared edges — that would thin outer edges relative to internal ones.

### Geometry

Hex-center-pixel math (`Board.hx:378-400`'s `absHexCoords`) is pure, DOM-free math and ports
directly into a small geometry helper (exact placement TBD — likely
`client.ui.common.board.BoardGeometry`, colocated with `BoardSurface` since nothing outside the
board package needs it yet). Since sizing is now viewBox-driven, this helper only needs to compute
hex-center-in-viewBox-units and (for future pointer interaction) viewBox-units → screen-pixels via
`getBoundingClientRect()` read on demand — no cached "current size" state to keep in sync,
unlike the old `Board.dimensions`/`resize()` pair.

## Hex tint palette (locked in for when `MoveInteractionController` is built — not used by
`BoardSurface` itself)

Chosen to stay clearly distinguishable by hue (several can be visible at once) and to avoid
colliding with nearby UI semantics — accent brass (`#8a5a1f`, intentionally board-echoing per
`[[intellector-style]]`) and the product-wide green=win/red=loss convention:

| Signal | Light hex | Dark hex | Note |
| --- | --- | --- | --- |
| Hover (transient) | `#83ACD4` | `#6F8EAC` | Cool blue — the only cool hue on the board, so pointer feedback can't be mistaken for a committed state. |
| Selected / drag departure | `#E56A00` | `#E56A00` | Kept from the old palette, uniform across dark/light (a "you're holding this" state). |
| Premove | `#869E60` | `#648039` | Unchanged from the old palette. |
| Last move | `#FDD340` | `#BE9C26` | Unchanged from the old palette. |
| RMB mark, legacy fill mode (preference-gated) | `#FF6955` | `#BE3726` | Unchanged from the old palette — "how it works now," opt-in via preference. |
| RMB mark, new default | ring, stroke `#FF0000` | ring, stroke `#FF0000` | Matches the arrow color (`Colors.arrow = 0xFF0000` in the old repo) rather than the legacy pinkish fill — outline, not a fill, so it never competes for the fill-priority slot below. |

Resolved priority for the fill slot (highest wins; only `MoveInteractionController` XOR
`PositionEditorController` ever writes it): **hover → selected/drag departure → premove → RMB
legacy-fill (only if that preference is on) → last move → base.** Destination dot/circle markers
and both RMB ring modes are drawn as separate shapes, outside this list, so they can coexist with
any resolved fill state.

## This pass: `BoardSurface` only

Scope, matching what `[[todo]]` already lists as next (challenge-creation overlay preview,
incoming-challenge notification widget) and what game/study list rows need — none of which require
interaction:

- Package: `client.ui.common.board` (shared across pages, per CLAUDE.md's `client.ui.common`
  convention — not page-specific).
- Inputs: `Position` (from `intellectorboard`), orientation (`PieceColor`), coordinate-marking mode
  (reading `Preferences.boardCoordinates` — `all`/`files_only`/`none`, already renamed per
  CLAUDE.md's vocabulary section).
- Renders: hex fills/borders (base dark/light only — no tint API yet, nothing calls it), coordinate
  labels per marking mode, piece images, at whatever size its container gives it (percentage-sized,
  aspect-ratio preserved via CSS, per `[[intellector-style]]` §7's "size children in percentages"
  rule).
- No tint-setting API, no pointer handling, no resize-triggered redraw logic (view-box scaling
  makes that unnecessary) — deliberately not building unused API surface ahead of the controller
  that would call it, per `[[feedback_service_module_coupling]]`'s "don't build unused scaffolding"
  lesson.
- Depends on the new `haxefolio.graphics.SvgSurface` primitive (built alongside `BoardSurface`,
  since nothing else needs it yet — but written and reviewed as HaxeFolio-owned, generic code, not
  tailored to the board).

## Verification

1. `haxe build.hxml --debug` — zero errors.
2. A throwaway test page (or a temporary mount inside an existing stub page) rendering
   `BoardSurface` with the default starting `Position`, both orientations, and all three
   `boardCoordinates` modes — visual check against the old board's look (`Colors.hx`'s base fill
   values are unchanged: light `#ffcf9f`, dark `#d18b47`, border `#664126`).
3. Resize the browser window / the board's container — confirm the whole board scales smoothly with
   no flash/redraw artifact, at both a small (~150px, list-row-sized) and large (fills available
   space) rendered size.
4. Confirm adjoining hex borders read as a single, uniform-thickness line matching the outer board
   edge — the overlap behavior described above, carried over unchanged.
5. Confirm piece images and coordinate labels scale in lockstep with the hex grid (same SVG
   viewBox), not independently.
