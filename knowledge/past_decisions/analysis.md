# Analysis page

Source design: the "Intellector analysis page" canvas (https://claude.ai/artifact/HJeq5PMdPCiaaTTW2DTBEw)
and its handoff (https://claude.ai/artifact/QP7XJ7c4Na9Xp7Nztt9QGQ).

## Decisions

1. **Scope**: the bare `analysis` route only, starting from the default position. `study/{id}`
   keeps opening the same empty board; loading/saving studies, a SIP or game parameter and local
   persistence are deferred (`[[analysis_deferred]]` 1-3).
2. **Views**: the `branching_type` preference picks the view, live: `tree` / `plain_text` (the
   `outline` value is dropped; a stored one falls back to the default). The turn colour preference
   is removed: the colour discs always show.
3. **Colour of a move** is the side that made it (the parent position's turn), not ply parity: a
   custom position may start with Black to move. Ply number = tree depth.
4. **Moving on the board** from the selected node selects the child with the same ply if there is
   one, otherwise adds a new last child (a new variation) and selects it. Children keep creation
   order; the first is the main continuation.
5. **Navigation** (Moves card, strip): along the selected line (root, path to the selection, then
   first children down to a leaf). The position change is a `Move` only when the new selection is
   the old one's child; any other jump is a `Replacement`. The board has no move animation yet
   (backlog), so the cause only drives premoves and annotation clearing for now.
6. **Delete** removes the selection with its subtree and selects the parent. A selection with
   continuations asks first (inline banner in the Variations card).
7. **Position editor**: free move / place / delete-piece tools under the board (rows swap with
   orientation), side to move, Clear board / Reset / Starting position, Import (does nothing yet,
   `[[analysis_deferred]]` 4). Apply is disabled for an invalid position (`Position.isValidStarting`)
   with the reason in place of the consequence hint. Apply with a changed position or side replaces
   the tree with a single root; unchanged, it just closes. Discard leaves everything as it was.
   While editing, Variations and Moves are locked in place. Wide tool card is larger than the
   design canvas (whose board was a small stand-in): 48 px tools, 36 px Intellector art, 150 px
   Free move / Delete piece; compact keeps the canvas's 44 px tools.
8. **Share, Play from here** are shown but do nothing (`[[analysis_deferred]]` 4).
9. **Zoom** (tree view only): -/%/+ buttons over the steps 60/80/100/125/150 %, plus continuous
   pinch (two pointers, or ctrl+wheel for trackpads) clamped to 50-200 %. The tree is laid out at
   100 % and scaled with a CSS transform; the scroll extent follows the scaled size.
10. **Expand** hides the board column and the right column (wide) or the board, strip and actions
    (compact); the Variations card keeps its component, so its scroll survives. Disabled while
    editing. No keyboard handling (`[[analysis_deferred]]` 5).
11. **Layout**: HaxeFolio's breakpoint (`ResponsivityController`) picks wide/compact. Wide: 312 px |
    board | 312 px, the page's height measured like the live game page. Compact: strip, board,
    (tool card), action row, Variations card filling the rest; Moves is a 200 px popover over the
    card's bottom, opened by the strip's current-move button.
