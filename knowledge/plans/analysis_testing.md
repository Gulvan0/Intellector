# Analysis page: testing log

First full pass: 2026-10-16. Driven in Chrome with synthetic pointer events against the debug build
(wide 1440×900, medium 1100×800, compact 390×844 / 500×844), English and Russian. Second pass the
same day re-checked the open findings, compact at an emulated 3× DPR. Third pass the same day went
through the "still to test" list in DevTools-emulated viewports (mobile 390×844 / 390×560 at 3× with
touch), real CDP mouse hover, and the live game page against the local server (tabtester/tabrival).

## Verified working

- Unit tests: all pass.
- Playing moves; branching from any node (same move reselects the existing child, a new one adds a
  last child); hint counts (moves · lines); off-line / selected styling in both views.
- Navigation: Moves card buttons, move cells, strip; disabled states at the ends; the board always
  shows the selected node, including rapid jumps across branches.
- Delete: disabled at the root, a leaf deletes at once, continuations ask in a banner, Cancel,
  the banner closes on a selection change, the selection moves to the parent.
- Zoom: −/%/+ steps and limits, ctrl+wheel (continuous, clamped 50–200 %, default prevented).
- Drag panning; the click ending a drag is swallowed; a plain click still selects.
- Expand / collapse (wide, medium, compact).
- Plain view: live preference switch both ways, rails and elbows, selection, delete.
- Editor: free move (drag and tap), place, delete piece, capture by moving, side to move, Clear /
  Reset / Starting position enablement, invalid positions (two Intellectors, one on its last row,
  empty board), Apply (changed resets the tree, unchanged just closes), Discard, locks on the
  tree / moves / strip / expand / delete, tool rows swap after flipping.
- Custom position with Black to move: discs, Moves table offset.
- Medium tier: tabs, tab switch from the strip, editor, expand.
- Compact tier: Moves popover, selection from it, editor (page scrolls), icon-only actions.
- Leaving the page and coming back: old page detached, its board ignores input, no errors.
- Promotion in analysis: prompt, different promotions branch, the same one reselects.
- Board coordinates preference (all / files only / none) in wide, medium and compact, editor open
  and closed: board aspect exact, the tool card fits under the board, nothing overlaps.
- Annotations: arrows and hex marks; clear on a board click (default) and on any position change
  (move, navigation, editor move) with the preferences on; kept through all of them with both off,
  including drawing inside the editor and across Apply.
- Tier changes (wide, medium, compact, both ways) with the editor and its draft, Expanded, the
  Moves popover (closes, doesn't reopen), the delete banner (stays, still deletes). The medium Moves
  tab resets to Variations after a round trip through wide (minor).
- Short windows: wide 450 px tall keeps the 520 px minimum and scrolls; compact 560 px keeps 640 px
  and scrolls, the editor's Apply is reachable.
- Large trees: a 104-ply line and 9 lines; reveal-selected in both views, the sticky gutter numbers,
  plain-view wrapping, the Moves card scrolling to the current move. A move and a selection each
  cost ~50 ms at 104 plies (finding 15).
- Plain view expanded and collapsed (wrapping), on a Black-to-move start; Moves table offset.
- Live language switch with the delete banner open: every visible label and tooltip switches; no
  text overflows in RU in any tier (banner, editor, invalid hint, Moves popover, tabs, expanded).
- Promotion cancel by ✕, Escape and a click outside; Shift auto-promotes; the control row's
  auto-promote toggle; the aura (chameleon) prompt: both choices branch, the same one reselects,
  ✕ cancels. Progressors correctly get no aura prompt.
- `study/{id}` opens the same empty board ("Study 42 | Analysis Board"); a non-numeric id falls back
  to the plain title.
- Live game page: spectator and player views, incoming moves (spectator stays put, the player
  follows), takeback (rows removed), RU in all tiers (finding 22), compact control row.
- Hover (real mouse) on tree nodes, tokens, Moves cells, Delete, editor tools, segments; Delete's
  pressed state.

## Findings

Status: **fixed** (verified), **open**.

1. **fixed** - Delete caption unstyled (HBox reusing `.intellector-game-button`; Labels don't
   inherit container text styles). Own caption class with per-state rules. Codebase-wide sweep:
   no other container reuses a Button text class.
2. **fixed** - Delete caption hidden in compact (was per handoff; user wants it shown).
3. **fixed** - RU: "Свободный ход" → "Перемещение".
4. **fixed** - RU action captions overflowed 2-per-row buttons: now Развернуть / Ред. позицию /
   Играть отсюда (Flip and Play-from-here keys are shared with the live game page). All fit in wide
   and medium (tightest: Играть отсюда, 9 px to spare).
5. **dropped** - Action-card captions wrapping onto two lines as a safety net. Every EN/RU caption
   fits in every tier; the buttons keep their fixed 37 px height (HaxeUI's style merge can't clear
   it from a later `height: auto` rule).
6. **fixed** - RU compact editor grid: "Начальная позиция" overflowed by 13 px; compact uses
   `editor.starting_short` = "Начало" (full text stays the tooltip). Paddings 44 / 46 px.
7. **fixed** - Root tree pill was 132 px; "Начальная позиция" overflowed by 2 px. Now a fixed
   150 px (the RU label is 123 px). Side effect: at 150 % zoom a one-move tree is 306 px wide and
   scrolls horizontally in the 284 px wide-tier viewport.
8. **fixed** - Variations hint ("N moves · M lines") and the editor footer hint kept the old
   language after a live language switch. Both now follow EN ↔ RU switches.
9. **fixed** - Compact (mobile): the annotation-controls panel's paddings were uneven (x 0–380 of a
   390 px page). The row was ~380 px wide in a 350 px column: above the board it now spans the
   board's width and its buttons share it (37 px each at 390 px). And haxefolio's `ScrollArea`
   reserved a 10 px lane even where scrollbars overlay the content: it now keeps its thin scrollbar
   only for a fine pointer and pads the contents by the lane's measured width (0 on phones), so
   compact rows sit at 15 px on both sides.
10. **fixed** - Tree gutter: its background and separator stopped at the content height. A static
    rail behind the scroller continues it to the view's bottom.
11. **fixed** - Tree view: the native scroller's contents kept HaxeUI's default 5 px padding, so a
    horizontal scrollbar appeared while the scaled tree still fit. Padding removed.
12. **fixed** - App-wide: HaxeUI `Toolkit.autoScale` defaulted to true; on phones above ~1.5 DPR
    every page rendered at 2×. haxefolio's `HaxeFolioApp.init` now disables it. Verified at 3× DPR.
13. **fixed (no longer reproduces)** - Compact editor tool card was wider than the column. At
    390 px it is now 342 px inside the 350 px column.
14. **fixed (no longer reproduces)** - RU editor invalid hint measured 1 px past its box bottom.
    Now inside its box in wide and compact.
15. **fixed** - Slow at 100+ plies: a selection took ~200 ms and a move ~380 ms, since every
    change rebuilt the whole Moves table and every tree pill and row number (then re-measured all
    their text). `MovesCard.setMoves` now rebuilds from the first changed row only (the live game
    page appends one cell per move); `VariationTreeView` reuses pills and row numbers. Both ~50 ms.
16. **fixed** - Reveal-selected put the last node under the zoom tools. The bottom clearance is now
    a constant 56 px at any zoom, and reveal keeps the node above it.
17. **fixed** - App-wide: once a page overflowed, haxefolio's `ScrollArea` lost a further 15 px of
    width (HaxeUI's native-scroller layout takes a scrollbar's width off percentage-sized contents
    on overflow, on top of the reserved lane), shifting the right column. The contents are now sized
    explicitly to the width less the measured lane.
18. **fixed** - App-wide: `:hover` (and Delete's `:down`) rules on Box/HBox/Label-based controls
    never applied - HaxeUI only maintains them on its interactive components. New
    `ComponentExtension.trackHover` / `trackPress`, used by tree pills, tokens, Moves cells, Delete,
    editor tools, segments (side to move, panel tabs), the live game's peek button and nickname
    link, and the challenge compact row.
19. **fixed** - morestd's `BackoffDelayTimer` never stopped its `haxe.Timer`, so while the game server
    was down the delay kept firing and reconnected over a pending socket: uncaught "Socket
    already connected". It now fires once per `startDelay`.
20. **fixed** - Medium tier, editor open: the Variations/Moves panel was squeezed to ~100 px, the
    zoom tools over the root pill. While editing, the panel now shrinks to its tabs (locked look,
    disabled; the chosen tab is kept for after editing) and the editor takes the height.
21. **fixed** - Compact on short phones (390×560): the 640 px layout minimum left the Variations
    card 136 px. The minimum is now the height that leaves the card 220 px (re-measured after each
    board fit); 390×844 is unchanged.
22. **fixed** - Live game page, RU: "Предложить ничью" overflowed its button by 27 px; now "Ничья?".
23. **resolved** - The board has no move animation; decision 5 now says so, and move animations are
    a backlog item.
24. **open, minor** - Opening the editor clears annotations (with clear-on-position-change on)
    although the position hasn't changed.

## Open design questions (deviations from the handoff)

- Wide: the board keeps its size but moves up ~64 px when the editor opens (the reserved tool-card
  space is split above and below while closed). The handoff says "the board does not move".
- Delete at the starting position is disabled without the handoff's reason ("The starting position
  can't be deleted").
- Locked look: the handoff dims discs to 45 % while locked; not checked.

## Still to test

Only reachable by hand: no real devices or other browsers from the test tooling.

- Real touch devices: pinch zoom on the tree, one-finger native pan, board input, the Moves popover,
  the compact editor's height on short phones; the overlay scrollbars (no lane) on phones.
- Other browsers (Firefox, Safari): native scroller overflow, ResizeObserver, ctrl+wheel, the
  `ScrollArea` lane (Firefox's own thin scrollbar width).
- A real held mouse press (pressed states were checked with synthetic events).
