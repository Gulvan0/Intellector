# Anaconda: a guide to `position.js`

This is a walkthrough of the Intellector bot engine ("Anaconda") that the previous frontend
iteration runs in a browser Web Worker. The file is
`C:/Users/mitmi/Documents/GitHub/Intellector/build/html5/includes/position.js` (3934 lines). Line
references below look like **L1234** and point into that file.

The guide goes bottom-up: board geometry, then move generation, make/unmake, evaluation, the
search, and finally the drivers that turn a search into "the bot's move". Every section ends with a
**Review** block. Those blocks hold my opinion on the implementation: suspected bugs, things to
re-check, and changes that should make the bot stronger or faster. Section 17 collects all of them
into one prioritized list.

## How to read this guide

When a standard chess-programming term first comes up, it is marked **🔎 like this**. The guide
does not define these terms. Look them up before you continue, since the explanation that follows
assumes you know them. Here they are in order of first appearance, so you can look them all up in
one go:

1. 🔎 Web Worker (browser API, not chess)
2. 🔎 Mailbox board representation / 🔎 0x88 / 🔎 bitboards (for contrast)
3. 🔎 Piece list
4. 🔎 Precomputed attack tables / ray tables
5. 🔎 Pseudo-legal vs legal move generation
6. 🔎 Make/unmake move (copy-make vs make-unmake)
7. 🔎 Zobrist hashing
8. 🔎 Static evaluation function
9. 🔎 Piece-square tables (PST)
10. 🔎 Incremental evaluation
11. 🔎 Tapered evaluation
12. 🔎 Texel tuning
13. 🔎 Minimax
14. 🔎 Negamax
15. 🔎 Alpha-beta pruning
16. 🔎 Fail-hard vs fail-soft alpha-beta
17. 🔎 Mate scores and mate-distance scoring
18. 🔎 Repetition detection (two-fold in search)
19. 🔎 Contempt factor
20. 🔎 Graph History Interaction (GHI)
21. 🔎 Quiescence search
22. 🔎 Horizon effect
23. 🔎 Stand pat
24. 🔎 MVV-LVA
25. 🔎 Static Exchange Evaluation (SEE)
26. 🔎 Delta pruning
27. 🔎 Transposition table (TT)
28. 🔎 Exact / lower-bound / upper-bound TT entries
29. 🔎 TT replacement scheme (depth-preferred, always-replace, buckets)
30. 🔎 Hash move
31. 🔎 Move ordering
32. 🔎 History heuristic
33. 🔎 Killer heuristic
34. 🔎 Enhanced Transposition Cutoff (ETC)
35. 🔎 Staged move generation / lazy move sorting ("pick next best")
36. 🔎 Principal Variation Search (PVS) / null-window (scout) search
37. 🔎 Principal variation (PV) and triangular PV table
38. 🔎 Search extensions / fractional plies
39. 🔎 Check extension / recapture extension
40. 🔎 Late Move Reductions (LMR)
41. 🔎 History pruning / history reductions
42. 🔎 Null-move pruning (and its reduction R)
43. 🔎 Zugzwang
44. 🔎 Futility pruning / razoring
45. 🔎 Iterative deepening
46. 🔎 Aspiration windows
47. 🔎 Search instability
48. 🔎 Odd-even effect
49. 🔎 Time management / soft and hard time limits
50. 🔎 Node-count limits (fixed-nodes play)
51. 🔎 Perft
52. 🔎 SPRT / self-play testing

---

## 1. The runtime context

### 1.1 Worker protocol

The file is loaded as a 🔎 **Web Worker** (`new Worker('includes/position.js')` in
`src/engine/engines/Anaconda.hx`). The entry point is `self.onmessage` at L1-15, which accepts two
commands:

| `command`         | Payload                        | Calls                       | Reply                                      |
|-------------------|--------------------------------|-----------------------------|--------------------------------------------|
| `bestMoveByTime`  | `position` (string), `time` ms | `Position.bestMoveByTime`   | partial results, then one with `completed: true` |
| `bestMoveByLevel` | `position` (string), `level`   | `Position.bestMoveByLevel`  | progress strings, then the result (no `completed` flag) |

Each request builds a fresh `Position` from a 60-character string (section 2.3) and runs a search
from scratch. The Haxe side creates a **new Worker for every move** and calls `terminate()` to
interrupt. So nothing survives between moves: not the transposition table, not the history tables,
and not even the Zobrist keys, which are random per instance.

The Haxe bot (`StandardAnaconda.playMove`) only ever uses the time mode. It passes
`BotTimeData.getSecsToMove`, or **120 seconds** when the game has no time control. The level mode
is commented out with "Not working atm". Section 15.4 explains why it fails.

### 1.2 What the reply looks like

`bestMoveInf = { move, mark, depth, progress, bestLine }`:

- `move`: `{from, to, figure}` (section 3.1).
- `mark`: the score in centi-progressors, **from White's point of view** (positive = good for White).
- `depth`: the iterative-deepening iteration that produced it.
- `progress`: how many root moves of that iteration had been searched.
- `bestLine`: the principal variation, **in reverse order** (section 14.3).

> **Review.**
> - A worker per move rules out keeping the TT between moves, and in a game the previous move's
>   TT is the single best move-ordering source you have. In v3.0, keep one long-lived worker per
>   game and send `stop`/`go` messages to it.
> - The mark is White-relative (not side-to-move-relative). Keep this in mind when you display an
>   evaluation bar.

---

## 2. Board representation

### 2.1 Cell numbering

The engine uses a 🔎 **mailbox**-style flat array `fields[0..58]`, one slot per hex. It is not
🔎 **0x88** and not 🔎 **bitboards**. Cells are numbered **column-major, bottom-up**:

```
column:  a(7)  b(6)  c(7)  d(6)  e(7)  f(6)  g(7)  h(6)  i(7)
index:   0-6   7-12  13-19 20-25 26-32 33-38 39-45 46-51 52-58
```

The formula is `index = 13*floor(col/2) + (col even ? row : 7 + row)`, where `col` counts a=0..i=8
and `row` is 0-based from White's side. Example: `b1 = 7`, `c1 = 13`, `e4 = 29` (the center),
`i7 = 58`. `cton`/`ntoc` (L36-178) and the `coords` array (L236) do the string conversion with
giant `switch` statements.

The Haxe wrapper converts between this and `HexCoords` with
`hexCoordsToAnacondaIndex`/`anacondaIndexToHexCoords`. In `HexCoords`, `j` counts from the
**top**, so `6 - j` appears there.

The engine names the six lateral directions by their index in the per-cell ray arrays. You can
read the convention off `mMoves` (decoded from b1 = 7):

| dir | meaning | b1's ray |
|-----|---------|----------|
| 0   | N (up the column)   | 8, 9, 10, 11, 12 |
| 1   | NE                  | 14, 21, 28, … |
| 2   | SE                  | 13 |
| 3   | S                   | – |
| 4   | SW                  | 0 |
| 5   | NW                  | 1 |

### 2.2 Piece codes

`fton`/`ntof` (L180-222) map piece letters to integers:

| code | piece        | letter (W/B) |
|------|--------------|--------------|
| 0/1  | Progressor   | p / P |
| 2/3  | Dominator    | m / M |
| 4/5  | Liberator    | l / L |
| 6/7  | Aggressor    | a / A |
| 8/9  | Defensor     | d / D |
| 10/11| Intellector  | i / I |
| 12   | empty        | e |
| 13   | "v" (unused) | v |

The encoding is chosen so that **`code % 2` is the color** (0 = White, 1 = Black, see `getColor`
L27) and **`changeRegister(code)`** (L31) flips the color while keeping the type (`code ^ 1`
written the long way). Every generator relies on this: "enemy piece" is `fields[x] % 2 !== color`.

There is a trap here: **empty (12) is even**, so `12 % 2 === 0` reads as "White". The generators
always test `=== 12` first, but you need to know this whenever you touch that code.

Lowercase is White, and **White moves up** (towards higher row numbers).

### 2.3 The `Position` state

```
fields          number[59]  piece code per cell
order           0 | 1       side to move (0 = White)
iPos, IPos      index|null  where each Intellector stands, kept up to date incrementally
moveHistory     stack       undo records for unmake (section 4)
positionHistory Map<hash, count>  repetition counter (section 7.3)
zobristTable    number[59][13] + blackMove   random keys (section 4.3)
hash            Map         transposition table (section 9)
history         [from][to][figure] → int     history heuristic (section 10.2)
pruningHistory  [from][to][figure] → {all, best}   statistics for reductions (section 11.2)
```

`iPos`/`IPos` act as a minimal 🔎 **piece list**: only the Intellectors are tracked, because the
search needs fast answers to "is the Intellector adjacent?" (chameleon captures) and "is it
attacked?" (`isCheck`).

The string format (`setPosition`, L1672) is 59 piece letters in index order plus `'w'`/`'b'`.
`setPosition` only checks that the length is 60 and that there is at most one Intellector of each
color. The constructor (L1541) also accepts an already-built `Position`-shaped object (any object
with an `order` field) and copies its fields. That path exists for structured-clone transfers and
is not used by the Haxe wrapper.

The default constructor sets up the standard starting position (L1567-1587). White: progressors on
a2 c2 e2 g2 i2; dominators a1 i1; liberators b1 h1; aggressors c1 g1; defensors d1 f1; Intellector
e1. Black mirrors this on rows 6/7.

> **Review.**
> - A 59-slot mailbox with precomputed rays (section 3) is a reasonable choice for a hex board.
>   Bitboards are possible (59 cells fit in a `BigInt` or in two 32-bit words), but in JS the
>   gain is doubtful and the cost in complexity is real. I would keep the mailbox and spend the
>   effort elsewhere.
> - `fields` is a plain JS array. An `Int8Array(59)` makes the element type explicit to the JIT
>   and is cheaper to copy.

---

## 3. Precomputed movement tables

Rather than walking the hex grid at runtime, the engine hard-codes every ray and jump target for
every cell. These are 🔎 **precomputed attack tables / ray tables** (L250-1431).

| table | shape | content |
|-------|-------|---------|
| `mMoves`      | `[cell][dir 0..5] → ray[]` | **Dominator** slides: six lateral rays, nearest cell first |
| `aMoves`      | `[cell][dir 0..5] → ray[]` | **Aggressor** slides: six *radial* (vertex-to-vertex) rays |
| `lShortMoves` | `[cell] → cell[]`          | the 6 (or fewer) adjacent cells |
| `lLongMoves`  | `[cell] → cell[]`          | cells exactly 2 steps away in a straight lateral line (Liberator jumps) |
| `pMoves` / `PMoves` | `[cell] → cell[]`    | White/Black Progressor targets (N, NE, NW / S, SE, SW) |
| `iMoves`, `dMoves`, `near` | aliases of `lShortMoves` | Intellector steps, Defensor steps, adjacency checks |
| `*MovesCount` | `[cell] → int` | how many targets each table has from that cell **on an empty board** (used only by the evaluation) |

Some non-obvious facts:

- **`aMoves` is filled for only one third of the cells** (L783-1048: most entries are
  `[[], [], [], [], [], []]`). Radial moves never leave their hex "color" (the board is
  3-colorable), and every aggressor in the starting position (c1, g1, c7, g7) stands on the same
  color class. Promotion squares (top/bottom of the 7-cell columns) and chameleon captures of an
  aggressor (which happen on the aggressor's own cell) also stay inside that class. So the
  invariant "aggressors only live on class cells" holds **in real games**.
- `pMoves` is empty for White progressors on row 1 of a 7-cell column (a1, c1, …). A White
  progressor can never get there, because it starts on row 2 and only moves forward. `pMoves[a7]`
  is `[cton('')]`, which is `[undefined]`. Progressors never stand on their promotion row either.
- The final ("promotion" / Intellector-win) cells are the tops of the 7-cell columns,
  `[6, 19, 32, 45, 58]` for White and `[0, 13, 26, 39, 52]` for Black. This matches
  `HexCoords.isFinal` in `intellectorboard`.

> **Review.**
> - **The tables bake in invariants that only hold for positions reached from the standard start.**
>   If the v3.0 analysis board or position editor lets the user put an aggressor on a non-class
>   cell, that aggressor gets **no moves and gives no "check"**. A progressor placed on its own
>   back row or promotion row gets no moves, or a move to `undefined`, which corrupts `fields`.
>   Either validate editor positions before handing them to the engine, or generate the tables
>   programmatically for every cell.
> - The tables are about 1200 lines of hand-typed literals. Generating them at startup from
>   `intellectorboard`'s `HexCoordsNavigation` (or one hex-step function) removes a whole class of
>   typo bugs, and the tables can then be checked against the rules library with 🔎 **perft**.

---

## 4. Moves, make and unmake, hashing

### 4.1 Move representation

A move is a small object `{ from, to, figure }`, where **`figure` is the piece code that will
stand on `to` after the move**. One field covers three cases:

- ordinary move: `figure === fields[from]`
- progressor promotion: `figure` = the chosen piece (one of 2/4/6/8 for White)
- chameleon capture (section 5.3): `figure` = the captured piece's type in the mover's color

Castling (the Intellector↔Defensor swap, "верто" in the comments) is not flagged anywhere.
`moveByRules` recognizes it from the board contents: an Intellector moving onto its own Defensor.

### 4.2 `moveByRules` / `unmoveByRules` (L1804-1865)

This is classic 🔎 **make/unmake** (not copy-make). `moveByRules`:

1. Pushes an undo record `{from, to, fromFigure, toFigure, newFigure}` to `moveHistory`.
2. Updates `iPos`/`IPos`: the moving Intellector moves; a captured Intellector becomes `null`.
3. Writes the board. For a swap, the two pieces exchange places; otherwise `from` becomes empty
   and `to` gets `move.figure`.
4. Flips `order`.
5. If a hash was passed in, increments `positionHistory[hash]` (repetition bookkeeping).

`unmoveByRules(hash)` pops the record, restores both cells and the Intellector positions, flips
`order` back, and decrements the repetition counter.

Note that **"the Intellector was captured" is not a special state.** The board just has no
Intellector, `iPos` is `null`, and the evaluation and `winMark` notice (section 6.4, 7.1).

### 4.3 Zobrist hashing (L1618-1670)

This is standard 🔎 **Zobrist hashing**. There is one random key per (cell, piece) plus one
`blackMove` key, and the hash is the XOR of the keys of all occupied cells, XORed with
`blackMove` if Black is to move.

- `zobristHash()` computes it from scratch (59 iterations).
- `recalculateZobristHash(parent, move)` derives the child's hash incrementally. It flips the
  side, XORs out the old `from`/`to` contents and XORs in the new ones, including the swap case.
  It must be called **before** the move is made, because it reads the current board.

Intellector has no castling rights, en-passant, or fifty-move counter, so pieces plus side to move
fully describe a position, and the hash is complete.

> **Review.**
> - **32-bit keys.** `random32` produces 32 random bits, and XOR in JS works on signed int32. With
>   a TT holding around 10⁶ positions, the chance that a lookup collides with an unrelated position
>   is about 10⁶/2³² ≈ 1/4300 per probe. Over millions of probes per search, collisions *will*
>   happen, and the TT stores no second key to detect them. Use two independent 32-bit halves
>   (one for the index, one stored as a check key).
> - The keys are random per `Position` instance. That is harmless now, but a TT kept between
>   moves (recommended above) needs fixed keys from a seeded PRNG, which also makes searches
>   reproducible for debugging.
> - Every make allocates an undo object, and every generated move is an object too. That is
>   millions of short-lived allocations per search and a lot of GC pressure. Packing a move into
>   one integer (`from | to << 6 | figure << 12`) and keeping undo data in preallocated typed
>   arrays indexed by ply is one of the cheapest speedups available.

---

## 5. Move generation

### 5.1 `getMoves()` (L1911-2112)

This is 🔎 **pseudo-legal move generation**. Intellector has no check rule, so there is no
legality filter: every pseudo-legal move is legal, and "losing the Intellector" is just a capture
that the search scores. The generator walks all 59 cells and dispatches on the piece code to a
local closure per piece type:

| closure | logic |
|---------|-------|
| `getMMoves` (Dominator) / `getAMoves` (Aggressor) | for each ray, emit every empty cell; at the first occupied cell, emit a capture if it is an enemy piece |
| `getDMoves` (Defensor) | each adjacent cell that is empty or holds an enemy piece |
| `getLMoves` (Liberator) | each cell in `lLongMoves` (jump; the cell in between is ignored) if empty or enemy; plus each `lShortMoves` cell if **empty** (the step cannot capture) |
| `getIMoves` (Intellector) | each adjacent empty cell; each adjacent **own Defensor** (swap) |
| `getpMoves` / `getPMoves` (Progressor) | each target that is empty or enemy; on a final cell, emit **four** moves, one per promotion choice (Dominator, Liberator, Aggressor, Defensor) |

### 5.2 `getBeatMoves()` (L2114-2292)

This is a captures-only copy of the same generator, used by the quiescence search. Intellector
moves are skipped entirely: they can never capture, and the swap is not a capture.

### 5.3 Chameleon captures

Wherever a capture is emitted, the generator may add a second, transforming capture (comment
"бой с превращением"). The conditions:

```js
beatingFigure !== changeRegister(figure)      // the captured type differs from the mover's type
&& beatingFigure !== 10 && beatingFigure !== 11  // the captured piece is not an Intellector
&& near[coord].includes(own Intellector pos)     // the mover's departure cell is next to its own Intellector
```

The extra move has `figure: changeRegister(beatingFigure)`, the captured type in the mover's
color. Progressors never chameleon. All of this matches `CoreRules.isChameleonEligible` in
`intellectorboard`.

### 5.4 Castling from the Defensor's side

The rules library also lets a **Defensor** start the swap with its Intellector. The engine only
generates the Intellector→Defensor version. Both produce **the same resulting position**, so the
search loses nothing. The missing move only matters if you want the engine's move list to match
the rules library one-to-one, for example in perft comparisons.

> **Review.**
> - `near[coord].includes(iPos)` is a linear scan inside the capture loop, and so is
>   `[6,19,32,45,58].includes(field)` for promotion. Precompute a `isFinal[color][cell]` table and
>   an `adjacent[cell][cell]` boolean table (59×59 bytes), or check "is my Intellector adjacent"
>   once per piece instead of once per capture.
> - `getMoves` and `getBeatMoves` duplicate about 250 lines with small differences. One generator
>   with a `capturesOnly` flag keeps them from drifting apart.
> - The generator emits moves in board order. That order is used **unchanged** at depth 1
>   (section 10.4), where ordering matters most for cutoffs.

---

## 6. Evaluation

### 6.1 Overview

The 🔎 **static evaluation** is a pure sum of 🔎 **piece-square table (PST)** values:

```
eval = Σ over occupied cells  price[piece][cell]
```

It is computed in **absolute (White-positive)** terms. `price` is built at load time (L1493-1516)
from base material values and the empty-board mobility tables.

### 6.2 Material: `marks` (L248)

| piece | value |
|-------|-------|
| Progressor  | 100 |
| Dominator   | 600 |
| Liberator   | 170 |
| Aggressor   | 200 |
| Defensor    | 150 |
| Intellector | 100 000 |
| empty       | 0 |

Black entries are negative. Note how cheap the Liberator is compared with the Aggressor, and how
expensive the Dominator is (it is the hex "queen", sliding along all six lateral rays).

### 6.3 Positional terms (`kMovesCount = 5`, `kCenter = 5`)

For a White piece on cell `i` (Black entries mirror the signs):

| piece | price |
|-------|-------|
| Progressor  | 100 + 5·pMovesCount[i] + pPromotion[i] |
| Dominator   | 600 + 5·mMovesCount[i] + **5·distanceToCenter[i]** |
| Liberator   | 170 + 5·(lShortMovesCount[i]/2 + lLongMovesCount[i]) + **5·distanceToCenter[i]** |
| Aggressor   | 200 + 5·aMovesCount[i] + 0·distanceToCenter[i] |
| Defensor    | 150 + 5·dMovesCount[i] + **5·distanceToCenter[i]** |
| Intellector | 100 000 + 5·iMovesCount[i] + iPromotion[i] |

- **Mobility**: the number of targets *on an empty board*. This is static mobility (a property of
  the cell), not real mobility in the current position.
- **`pPromotion`/`PPromotion`**: a bonus that grows as a progressor approaches its final row
  (0, 0, 20, 50, 100, 150).
- **`iPromotion`**: the Intellector "march" bonus (0, 5, 10, 20, 50, 100), and **+100 000 on a
  final cell**. Reaching a final cell wins the game, and this is how the evaluation encodes it.
- **`distanceToCenter`**: 0 at e4, 5 in the corners.

### 6.4 Win detection through the score (`fastMark`, L2407)

`fastMark` adds up the board and then clamps it:

```js
if (mark > 0.9 * 100000) mark = 100000;      // Black's Intellector is gone, or White's is on a final cell
else if (mark < -0.9 * 100000) mark = -100000;
```

If Black's Intellector has been captured, the −100 000 term is missing and the sum is about
+100 000. If White's Intellector stands on a final cell, it contributes 2×100 000. Either way the
sum crosses ±90 000 and becomes a clean **win score**. The search compares against `0.9 *
marks[10]` everywhere to mean "this is a decided game".

`fastMark` also adds `variabilityArray[currentLine]` (section 14.5): a random offset per root move
that weakens the bot on purpose.

### 6.5 Incremental update in the quiescence search (`recalculateMark`, L2420)

```
new = old − price[from piece][from] − price[to piece][to] + price[move.figure][to]
```

This is 🔎 **incremental evaluation**, but only inside the quiescence search. The main search
calls `fastMark` from scratch at every quiescence root.

> **Review.**
> - **Possible sign bug: `+ distanceToCenter * kCenter` rewards being *far* from the center.**
>   For the Dominator, the mobility term outweighs it (a1 ≈ 95, e4 ≈ 110). For the **Defensor**
>   the center term wins: a1 = 35, b1 = 45, e4 = 30, so Defensors are pulled to the rim. For the
>   **Liberator** it nearly cancels the mobility term (a1 = 40, e4 = 45). If the intent was "near
>   the center is good", this should be `(5 − distanceToCenter)` or `−distanceToCenter`. Check the
>   intent first. Keeping Defensors near the home row could be deliberate, but a1/b1-style edge
>   cells look accidental.
> - There is **no Intellector safety term**, and that is the biggest strategic gap. Losing the
>   Intellector loses the game, yet the evaluation does not count attackers near it, Defensors
>   next to it, or escape squares. The search only sees danger through tactics.
> - **No threat or hanging-piece terms.** The quiescence search handles this partly, but see
>   section 8.
> - **Static mobility.** A Dominator boxed in by its own progressors scores the same as a free one.
>   Real mobility (counting pseudo-legal moves per piece) is expensive in JS, but a cheap
>   approximation such as "free cells on the first step of each ray" would help.
> - The Intellector march bonus (up to +100 for row 6) is small compared with how decisive a free
>   path to the final row is. A "the Intellector reaches a final cell in N uncontested steps" term
>   would catch wins the search cannot see within its horizon.
> - The constants (5, 5, piece values) look hand-picked. With self-play games available,
>   🔎 **Texel tuning** of the PST and material values is a well-understood way to gain strength.
> - There is no game-phase blending (🔎 **tapered evaluation**). That may not matter much here, but
>   an Intellector march is far more relevant once the Dominators are off the board.

---

## 7. Terminal conditions and special scores

### 7.1 `winMark()` (L2501)

Returns ±100 000 if an Intellector is missing (captured) or stands on its final row, and `false`
otherwise. The search calls it at every node (section 8, step 7). It is cheaper than `fastMark`
because it only reads `iPos`/`IPos`.

### 7.2 `correctWinMark` and mate distance

Each search function defines a local helper:

```js
function correctWinMark(value) {
    if (value >  0.9 * 100000) return --value;
    if (value < -0.9 * 100000) return ++value;
    return value;
}
```

It is applied to every child result. A win found *k* plies down arrives at the root as
100 000 − *k*, so the search prefers faster wins and slower losses. These are 🔎 **mate scores
with mate-distance scoring**. Because the adjustment happens as the score is passed up, a score
stored in the TT is already relative to *that node*, so no ply correction is needed when storing
or probing. That part is correct by construction.

### 7.3 Repetition

`positionHistory` counts how many times each hash has occurred on the current path. A node at
`depth >= repetitionDepth (2)`, other than the root, returns `drawMark = -0.1` if its hash has a
count of 2 or more. That means the position already occurred once before this visit. This is the
usual 🔎 **two-fold repetition detection in search**: one repetition counts as a draw.

Two details matter:

- Positions are only counted when `depth >= repetitionDepth`. Moves are made with `argP =
  undefined` below that (L2767), so **repetitions in the last two plies of the search are
  invisible**.
- `drawMark` is `-0.1` **in White-relative terms**. That is a tiny 🔎 **contempt factor** that
  always slightly favors **Black** regardless of which side the bot plays: White avoids draws,
  Black welcomes them.

### 7.4 What gets passed in

`new Position(string)` resets `positionHistory` to just the current position. **The real game
history is never sent to the engine.** The bot therefore cannot see that a move would complete a
threefold repetition in the actual game. It can walk into a draw while winning, or miss one while
losing.

> **Review.**
> - Send the game's position history (or the hashes since the last irreversible move) along with
>   the position. That is cheap and fixes real misplays.
> - Make the draw score side-relative (`drawMark = order === botSide ? -contempt : +contempt`) or
>   just 0. The current constant is asymmetric by accident.
> - The repetition logic interacts with the TT. A score that depends on a path-specific draw gets
>   stored and later reused for the same position reached by another path. That is the
>   🔎 **Graph History Interaction (GHI)** problem. The code avoids storing a node whose result is
>   exactly `drawMark` (L3412), but the parent of such a node stores a score derived from it. Full
>   GHI fixes are hard. The common compromise is to skip TT cutoffs near the root when the stored
>   score equals the draw score.
> - Intellector has no "no progress" rule (the fifty-move-rule equivalent). If the server has one,
>   the engine knows nothing about it.

---

## 8. Quiescence search: `quiesce2` (L2341-2405)

When the main search reaches depth < 1, it does not evaluate statically. It calls `quiesce2(α, β)`,
a 🔎 **quiescence search** that resolves capture sequences so the leaf score is not distorted by
the 🔎 **horizon effect**.

The structure is a minimax copy for each side (White maximizes, Black minimizes). In the White
branch:

1. `stand_pat = fastMark()` at the first call, or the incrementally updated mark passed down.
   That is the 🔎 **stand pat** score: the side to move can "decline to capture" and keep it.
2. If `|stand_pat|` is a win score, return it immediately.
3. If `stand_pat >= β`, fail high. Otherwise raise α to `stand_pat`.
4. Generate captures (`getBeatMoves`) and order them with `sortBeatMoves` (section 10.3).
5. **Depth throttle:** from quiescence depth `fullDepth = 2` on, a capture is searched only if it
   lands on a cell already captured on earlier in this quiescence line (`beatFields`), or if it
   captures an Intellector. Two plies of free captures are followed by recaptures only.
6. For each capture: compute `newMark = recalculateMark(stand_pat, move)`, make the move, recurse,
   unmake. Return on a β-cutoff, otherwise raise α.
7. Return α. That is 🔎 **fail-hard** on the low side, even though the main search is
   🔎 **fail-soft** (section 12).

> **Review.**
> - The recaptures-only throttle (step 5) is a nice cheap way to stop quiescence explosions.
> - **No stand pat restriction when the Intellector is attacked.** If the side to move has its
>   Intellector under attack, standing pat assumes some quiet move keeps the evaluation, but the
>   quiescence search never checks whether one exists. In chess, the rule is "no stand pat while
>   in check; search evasions instead". The analogue here is: if `isCheck()`, generate all
>   moves (or at least Intellector moves, Defensor swaps, and captures of the attacker).
> - **Quiet game-winning moves are missing.** Neither an Intellector step onto a final cell nor a
>   non-capturing promotion is a capture, so the quiescence search never considers them. A leaf
>   with White's Intellector one step from the final row with nothing in the way scores as
>   "+100 bonus", not as a win. Add "Intellector reaches a final cell" (an instant win) and
>   promotions to the quiescence move list.
> - Captures are ordered by victim minus attacker, but none are *pruned*. 🔎 **SEE** pruning
>   (skip captures that lose material) and 🔎 **delta pruning** (skip a capture if
>   `stand_pat + victim + margin < α`) are the standard ways to cut quiescence nodes, which are
>   usually the majority of all nodes.
> - Quiescence nodes are **not counted** in `this.count`. That matters for the level mode (section
>   15.3): two positions with the same node budget can take very different amounts of time.
> - `beatFields.includes` is another linear scan. Keep a small fixed array plus a length counter,
>   or a 59-entry "captured here" counter array.

---

## 9. Transposition table: `seeHash` / `addToHash` (L2511-2575)

### 9.1 Layout

`this.hash` is a JS `Map<zobrist, record[]>`. Each key can hold **several records**:

```js
{ move, depth, mark, α: trustα, β: trustβ }
```

This is not the usual single-slot 🔎 **transposition table**. It is closer to an unbounded list of
bound entries per position. The `α`/`β` fields record the window the score is trusted within, and
they encode the 🔎 **bound type**:

| search outcome | stored `α` | stored `β` | meaning |
|----------------|------------|------------|---------|
| `mark <= oldα` (fail low)  | `mark`  | `+∞`   | upper bound: true value ≤ mark |
| `mark >= oldβ` (fail high) | `−∞`    | `mark` | lower bound: true value ≥ mark |
| in between                 | `−∞`    | `+∞`   | exact |

The naming is confusing. For a fail-high record, the lower bound is stored in the field called
`β`, and vice versa. Read `seeHash` with that in mind.

### 9.2 Probing: `seeHash(pos, α, β, depth)`

For every record with `record.depth >= depth`:

- Exact (`α < mark < β` in record terms): return `{mark, move}` immediately, which is a cutoff.
- Fail-high record: `hashα = max(hashα, record.β)`, the best known lower bound. Its move is
  remembered.
- Fail-low record: `hashβ = min(hashβ, record.α)`, the best known upper bound.

Then:

- If the current `α >= hashβ`, return `{mark: α}`: the position is known to be no better than α.
- If `β <= hashα`, return `{mark: β}`: the position is known to be at least β.
- Otherwise **narrow the window** to `[max(α, hashα − ε), min(β, hashβ + ε)]` with `ε = 1` and
  return `{newα, newβ}`. The ε keeps the known bounds strictly inside the window, so the bounded
  value still classifies correctly.

### 9.3 Storing: `addToHash`

- Bound entries carrying win scores are **not stored**, only exact ones.
- Before pushing the new record, any existing record with `depth <= newDepth` whose trusted
  interval lies inside the new one is removed. That is a crude dominance-based
  🔎 **replacement scheme**.
- The root search stores with `oldα/oldβ`, the window **before** TT narrowing and mate clamping
  (L2685 `[oldα, oldβ] = [α, β]`).

### 9.4 Other places that read the TT

- `sortMoves` uses child records to order moves (section 10.1).
- The reduction logic uses "does the child have a record with depth ≥ 3" (section 11.3).
- The root driver resets the table: `this.hash = new Map()` per request.

> **Review.**
> - **Memory and speed.** An unbounded `Map` of arrays of objects is the slowest possible TT in JS.
>   Every store allocates, every probe walks an array, and long time controls (120 s) can grow it
>   to millions of entries. Use a fixed-size table in typed arrays (`Int32Array` for check keys,
>   `Int32Array` or `Float32Array` for scores, `Int8Array` for depth and bound type, `Int32Array`
>   for the packed best move), indexed by `hash & mask`, with depth-preferred plus always-replace
>   two-slot buckets.
> - **There is no stored check key** (see 4.3). A collision returns a wrong score, or a "best
>   move" that is illegal in the current position. Today the engine does not use the TT move
>   directly, so an illegal move cannot be played, but a wrong score can.
> - **Classification against `oldα/oldβ` after narrowing.** If the TT narrowed α upward, a
>   fail-soft result between `oldα` and the narrowed α gets stored as *exact* even though it was a
>   fail-low against the narrowed window. ε keeps this rare when searches are consistent, but
>   reductions, null-move, and repetitions make searches inconsistent (🔎 **search instability**).
>   Store with the *effective* window instead.
> - The **best move from the TT is not tried first**. `seeHash` returns `move` only on exact hits,
>   and `sortMoves` instead makes every child and probes the TT for each one (section 10.1). The
>   standard 🔎 **hash move** (store the best move at the node itself and try it before generating
>   anything else) is cheaper and usually better.

---

## 10. Move ordering

The effectiveness of alpha-beta depends almost entirely on 🔎 **move ordering**. The engine
combines four sources.

### 10.1 `sortMoves` (L2577-2657), used at `depth >= sortDepth (2)`

For **each** move: make it, then

1. If `winMark()` says the move wins, its key is the win score, so it sorts first.
2. Otherwise look up the **child** in the TT. Take the deepest record that is exact, or a bound
   that is useful for the mover (a lower bound for White, an upper bound for Black). The key is
   `record.mark + record.depth × 100` (×−100 for Black). **Moves with deeper TT entries are
   strongly preferred**: 100 points per ply of depth, more than most positional differences.

Then unmake. Moves with no TT information get a fallback key:

3. Quiet move: `−100 000 + history/10⁶` for White (mirrored for Black). These come after all
   TT-scored moves and are ordered by the 🔎 **history heuristic**.
4. Capture: `−100 000 + (victim − attacker)`. Good captures sort above quiet moves, and losing
   captures (e.g. Dominator takes Progressor: 100 − 600 = −500) sort below them.

The sort is a **bubble sort** (O(n²)), one copy per side.

This is essentially 🔎 **Enhanced Transposition Cutoff (ETC)**-style lookahead, used for ordering
rather than for cutoffs: "rank moves by what the previous iteration learned about their children".

### 10.2 History heuristic

On a β-cutoff by a non-capture, `history[from][to][figure] += depth²` (L2820). The table is reset
per request, never aged, and only consulted for quiet moves with no TT information.

### 10.3 `sortBeatMoves` (L2304), used in the quiescence search

The key is `−marks[victim] − marks[attacker]`, which works out to **victim value minus attacker
value** for either side, sorted best first. That is a summed variant of 🔎 **MVV-LVA**. (Classic
MVV-LVA is lexicographic: highest victim first, cheapest attacker as the tiebreak.) Capturing an
Intellector always sorts first. The four promotion choices and the chameleon variant of a capture
get the same key.

### 10.4 Depth 1 is unsorted

`sortDepth = 2` means nodes with `depth == 1`, the nodes right above the quiescence search and
the most numerous non-quiescence nodes, **search moves in generator (board) order**. Captures are
not tried first, and nothing else reorders them.

> **Review.** Move ordering is probably the area with the best effort-to-gain ratio:
> - **Order depth-1 nodes at least by captures first (MVV-LVA).** It costs almost nothing and
>   should cut a large share of nodes.
> - Replace "make every child and probe the TT" with a **hash move**. Making and unmaking every
>   move just to sort costs about as much as searching the node one ply deeper with nothing
>   behind it.
> - Add 🔎 **killer moves** (two quiet moves per ply that caused cutoffs at the same depth). This
>   is standard and cheap.
> - Replace the bubble sort with 🔎 **lazy move sorting ("pick next best")**: assign keys once,
>   then at each loop iteration swap the best remaining move to the front. Most nodes cut off
>   after 1-3 moves, so a full sort is wasted work. With 🔎 **staged move generation** (hash move,
>   then captures, then killers, then quiet moves), you often skip generating quiet moves at all.
> - The `+depth × 100` key ranks a move by how deep it was searched before, not by how good it is.
>   Searching a move less deeply usually means a reduction made it look bad, so the two correlate,
>   but a stale shallow refutation can bury the actual best move. Consider ordering by
>   `(exact score, else bound)` with depth only as a tiebreak.
> - In the quiescence search, captures with a Dominator that lose material sort last but still get
>   searched. SEE-based pruning would drop them (section 8).

---

## 11. Selectivity: extensions and reductions

Depth is not decremented by exactly 1 per ply. Each node computes an `ext` for every move and
passes `extension + ext` down. At the start of the child (L2688-2696):

```js
while (extension >= 1)  { depth++; extension--; }
while (extension <= -1) { depth = max(0, depth - 1); extension++; }
```

The fractional remainder is carried further down the line. These are 🔎 **fractional plies**.

### 11.1 Extensions (positive)

```js
const beat  = this.isBeat(move) ? 0.5 : 0;     // capture (Intellector moves excluded)
const check = this.isCheck()    ? 0.5 : 0;     // after the move: is the opponent's Intellector attacked?
let ext = Math.max(beat, check);
```

Each forcing move adds half a ply, a mild form of 🔎 **check extension** and
🔎 **recapture extension**. Two forcing moves in a row add one full ply.

`isCheck()` (L2430) checks whether the side to move's Intellector is attacked. It looks *outward*
from the Intellector's cell along each attack pattern and searches for the matching enemy piece:
adjacent Defensor, Liberator two cells away, Dominator/Aggressor along a ray up to the first
blocker. For progressors it uses the **opposite color's** table (`PMoves` to find White
progressors), because "cells a Black progressor could move to from here" are exactly "cells a
White progressor could attack here from". Intellector has no check rule. "Check" here is an engine
heuristic meaning "the Intellector is under direct attack".

### 11.2 History-based reductions (negative): `pruningHistory`

For each quiet move (no capture, no check), the engine keeps `{all, best}` per
`(from, to, figure)`:

- `all++` every time the move is searched (L2809).
- `best++` when it ends up as a node's best move (L2909).

Once a move has been searched at least `2 × maxDepth²` times, it gets

```js
ext = -1 / (100 * p + 0.5);     // p = best / all
```

| p (how often it was best) | reduction |
|---------------------------|-----------|
| 0      | −2 plies |
| 0.005  | −1 ply |
| 0.01   | −0.67 |
| 0.05   | −0.18 |
| 0.1    | −0.095 |

This is a 🔎 **history pruning / history reduction** scheme. Note that the inner `let p` shadows
the outer `p` (the child hash) only inside that block, so the TT lookup right after it uses the
right variable.

### 11.3 TT-gated late-move reduction

If the node is at `depth >= 2` and **the child already has a TT record of depth ≥ 3**, the move
gets an extra `ext -= i / length`. That is a reduction of up to almost one ply, growing with the
move's position `i` in the sorted list. It is a variant of 🔎 **Late Move Reductions (LMR)**,
gated on the child having been searched deeply before.

### 11.4 Null-move pruning at depth 1 (L2717-2734)

```js
if (depth === 1) {
    flip side;
    White node: null-window search (β−1, β) at depth 0 → if ≥ β, return it (prune)
    Black node: null-window search (α, α+1) at depth 0 → if ≤ α, return it
    flip back;
}
```

This is 🔎 **null-move pruning**, but only at depth 1, reducing straight into the quiescence
search. In effect: "if I pass and the opponent's best capture sequence still leaves me above β,
cut". At this depth it behaves more like a capture-aware 🔎 **futility pruning / razoring** test
than classic null-move pruning with its reduction R.

It runs before `winMark` and **at the root as well** in the first iteration (depth 1 = maxDepth).
If it prunes at the root, the root returns no move, which is why every driver has an "if
`!res.move`, re-search with a full window" fallback (the "НА ЭКСТРЕННЫЙ СЛУЧАЙ" / "for emergencies"
comment, L3732). With an infinite bound, the null move is skipped.

> **Review.**
> - **No re-search for reduced moves.** Standard LMR re-searches a reduced move at full depth when
>   it beats α. Here, once a move is reduced (by history or by position in the list), its reduced
>   score is final. This is the main reason I would expect the bot to miss quiet defensive or
>   preparatory moves: such moves are rarely "best" across the whole tree (p ≈ 0), so they get
>   reduced by **up to 2 plies everywhere**, and when they happen to be the only defense, nothing
>   corrects it. Add a re-search: `if (reduced && score > α) re-search at the unreduced depth`.
> - The history-reduction threshold `2 × maxDepth²` grows with iteration depth (200 at depth 10,
>   450 at depth 15). The statistics accumulate across iterations, so in late iterations most
>   common moves qualify. Consider capping reductions by remaining depth, and never reducing the
>   first few moves, PV nodes, or moves made while the own Intellector is attacked.
> - Reductions are applied at the root too. Most engines exempt root moves.
> - **The "check" extension is only half a ply.** Attacks on the Intellector are winning threats,
>   because the next move captures it. In many lines, half a ply is not enough to see the threat
>   resolved before the quiescence search, which itself does not handle Intellector attacks (section
>   8). Consider a full-ply extension when the opponent's Intellector is attacked, possibly limited
>   to a total extension budget per line.
> - `isCheck()` runs after **every** move at every node, scanning up to 6 rays. That is a
>   noticeable fixed cost. You could compute it lazily, only when `ext` matters (for example
>   `depth ≥ 2`), or derive it from the moved piece's attack pattern alone (a discovered attack
>   needs one ray check from the vacated cell).
> - Null move at depth 1 only is conservative. Real null-move pruning with R = 2-3 at
>   `depth ≥ 3` is a standard large speedup. 🔎 **Zugzwang** is rarer in Intellector than in
>   chess endgames, since there are no "kings must not move into check" constraints and pieces can
>   usually make a harmless move, but verify that on endgame test positions.
> - Null move should be skipped when the side to move's Intellector is attacked. Today it is
>   self-correcting (the opponent captures in the quiescence search), but it wastes a search.

---

## 12. The main search, step by step

There are four almost identical search functions (section 14). This section walks through
**`αβByTime`** (L3089-3418), the one the bot actually uses.

Signature: `αβByTime(α, β, depth, extension, maxDepth, pos, firstDepth)`:

- `depth`: remaining depth in whole plies.
- `extension`: the carried fractional extension.
- `maxDepth`: the iteration's nominal depth. `depth === maxDepth` identifies the root (mostly).
- `pos`: this node's Zobrist hash, computed by the parent incrementally.
- `firstDepth`: true only at the root.

The search is 🔎 **minimax** with 🔎 **alpha-beta pruning**, written as **two explicit branches**
(White maximizes, Black minimizes) rather than 🔎 **negamax**. It is **fail-soft**: `value`
starts at the worst win score and the best child value is returned even if it falls outside
`(α, β)`.

1. **Time check** (L3090). If time is up and `depth > 0 && maxDepth > 1`, return `+∞` when White
   is to move and `−∞` when Black is. The parent of this node is the *other* side, so this value
   is the worst possible for the parent, and the aborted subtree will never be chosen.
2. **Depth normalization**: the extension loops from section 11.
3. **Repetition**: section 7.3.
4. **TT probe** (`depth >= hashDepth (2)`): section 9.2. Either return a cutoff or narrow α/β.
5. **Mate-window clamp** (L3143): α no lower than −100 000, β no higher than +100 000 ("фатовые
   оценки нельзя подрезать", "fatal scores must not be cut").
6. **Null move** (depth 1): section 11.4.
7. **Win check**: `winMark()`. If decided, return ±100 000.
8. **Horizon**: `depth < 1` → `quiesce2(α, β)`.
9. **Move loop** (White branch shown):
   1. `getMoves()`, and `sortMoves()` if `depth >= 2`.
   2. At the root: `currentLine = getMoveNumber(move)`, which selects the variability offset
      (section 14.5).
   3. Compute `beat`, the child hash `p`, make the move (registering `p` in `positionHistory` if
      `depth >= 2`), compute `check`, then compute `ext` with the extensions and reductions from
      section 11.
   4. 🔎 **PVS**: the first move gets the full window `(α, β)`. Later moves get a **null window**
      `(α, α+1)`. If that returns `α+1 <= res < β`, re-search with `(res−1, β)`. Black mirrors
      this with `(β−1, β)` and `(α, res+1)`.
   5. Collect the principal variation into `line` (section 14.3).
   6. Apply `correctWinMark`, unmake.
   7. If this move improved `value`, record `bestLine`. Count `pruningHistory.all` for quiet moves.
      If `value > α`: raise α and record `bestMove`.
   8. If `value >= β`: update the history heuristic and **break** (β-cutoff).
   9. **Root only:** publish a partial result (section 13.3).
10. Count `pruningHistory.best` for the best move.
11. **TT store** if `depth >= 2` and the result is not `drawMark`.
12. Return `{ move: bestMove, mark: result, line: bestLine }`.

> **Review.**
> - The score scale is not integer. PSTs contain halves (the Liberator's `lShortMovesCount / 2`),
>   variability can be any integer, and `drawMark` is −0.1. So a "null window" of width 1 is not a
>   true null window: a score like α + 0.5 lands *inside* it and is accepted as exact without the
>   re-search. That is mostly harmless, but rounding all evaluation to integers removes a source
>   of subtle inconsistency.
> - Two mirrored branches per function, in four functions, means about 8 copies of the move loop.
>   They have already drifted (section 14). A negamax rewrite (`score = −search(−β, −α, …)`, with
>   the evaluation returned from the side to move's view) halves the code, and is the form every
>   reference implementation you will read uses.
> - Root moves are searched in `sortMoves` order, which already uses the previous iteration's TT,
>   so the previous best move is normally first. That is correct, but it would be more robust to
>   force the previous iteration's best move first explicitly.
> - On a time abort, the parent receives ±∞, and then **stores a TT entry** built from those fake
>   values (e.g. all children aborted → `value = −100 000` → stored as an upper bound "White is
>   lost" at that depth). The table is thrown away after each request, so this is currently
>   harmless. It becomes a real bug the moment the TT persists between moves. Skip TT stores
>   after an abort, which needs an explicit `this.stopped` flag.

---

## 13. Iterative deepening and the drivers

### 13.1 `bestMoveByTime(time)` (L3809)

The driver for 🔎 **iterative deepening** with 🔎 **aspiration windows**:

```
reset TT, history, pruningHistory; finish = now + time
hypothesis = 0
for i = 1, 2, 3, … while time remains:
    window around hypothesis:
        if the leaf ply is White's:  [h − 10, h + 20]
        else                         [h − 20, h + 10]
    res = αβByTime(window, depth = i)
    fail low  → re-search (−∞, α+1)
    fail high → re-search (β−1, +∞)
    if !res.move → re-search (−∞, +∞)   // e.g. null move pruned at the root
    if still within time (or i === 1): bestMoveInf = res
    postMessage(bestMoveInf)            // partial result per completed iteration
```

The window is skewed depending on whose move the last ply is (`lastMoveOrder`). That is a hand
correction for the 🔎 **odd-even effect**: iterations that end on the engine's own move tend to
score higher than those that end on the opponent's.

The window size is `point = marks[0] / 100 = 1`, so the window is **10-20 evaluation units wide**,
or 0.1-0.2 of a progressor. That is very narrow.

### 13.2 Time management

There is no 🔎 **time management** logic inside the engine: it gets one number of milliseconds and
uses all of it. When time runs out, the current iteration unwinds quickly, because every node
returns immediately. The Haxe side computes the budget with `BotTimeData.getSecsToMove`.

### 13.3 Partial-iteration results at the root

Inside the root move loop (L3271-3289), after each root move:

```js
if (bestMove && depth === maxDepth && (time remains || maxDepth <= 1))
    for j in 0..i:
        if (no previous result) or (moves[j] is the previous iteration's best move):
            accept bestMove/value as the new bestMoveInf
```

In words: **a new best move from an unfinished iteration is accepted only once the previous
iteration's best move has been re-searched in this iteration.** The new candidate then provably
scored at least as well as the old best at the new depth. This is a sound rule, and many engines
get it wrong.

### 13.4 The fail-high/low re-search

The re-search keeps one side of the window at the failed bound (`α+1` or `β−1`) and opens the
other to infinity.

> **Review.**
> - **The aspiration window is far too narrow.** ±10-20 units on a scale where a progressor is
>   100 means many iterations fail and re-search, especially early when scores swing. Typical
>   engines start at ±25-50 centipawns and **widen gradually** on failure (doubling, for example)
>   rather than jumping to ±∞. A jump to ∞ throws away the bound information and costs a lot in
>   tactical positions.
> - **Only one re-search.** If the re-search with `(−∞, α+1)` itself fails, which search
>   instability makes possible, the result is a bound but is treated as a score.
> - `hypothesis` starts at 0 each move. Seed it with the previous move's score (another reason to
>   keep the worker alive).
> - The odd-even skew is a reasonable hack. You can re-check whether it still helps after the
>   evaluation is improved.
> - Time management: give a soft limit (do not start a new iteration after ~50% of the budget,
>   since it will almost certainly not finish) and a hard limit (abort mid-iteration). Currently
>   the engine starts iteration i+1 with 1 ms left, aborts it at once, and wastes nothing, but it
>   also never stops early when the best move is stable. That would save clock time for later
>   moves. Without a time control, the bot thinks for **120 s per move**, which is probably more
>   than users want to wait.
> - `performance.now()` is called at *every* node. Check every 1024 nodes instead.

---

## 14. Other machinery

### 14.1 The four search functions

| function | used by | null move | history reductions | TT-gated LMR | extension loop | abort | partial results |
|----------|---------|-----------|--------------------|--------------|----------------|-------|-----------------|
| `αβ`        | `IDS` / `bestMove(depth)`         | ✔ | ✔ | ✔ | `while` | – | – |
| `cleanαβ`   | `cleanIDS` re-searches only        | ✘ | ✘ | ✘ | `if` (extensions only, no reductions) | – | – |
| `αβByTime`  | `bestMoveByTime` (**the bot**)     | ✔ | ✔ | ✔ | `while` | time | ✔ + PV |
| `αβByCount` | `bestMoveByCount` / `bestMoveByLevel` | ✔ | ✔ | ✔ | `while` | node count | ✔ (buggy for Black, 15.4) |

`cleanIDS` (L3736) is notable: its main search uses `αβ`, the pruned one, and only the aspiration
re-searches use the "clean" version. That looks like an experiment to measure how much the pruning
changes the result. The depth-limited drivers (`bestMove`, `cleanBestMove`, `IDS`, `cleanIDS`) are
not reachable from the worker protocol.

### 14.2 `getMoveNumber`

At the root, `currentLine` is set to the move's index in **unsorted** `getMoves()` order
(`αβByTime`, `αβByCount`), so it stays stable between iterations even though the sorted order
changes. In the older `αβ`, it is the **sorted** index `i` (L2760), which changes between
iterations. That does not matter there, because `bestMove()` sets variability to 0.

### 14.3 Principal variation collection

Each node returns `line`, and the parent does `line.push(move)`. The lines are built **leaf
first**: the root's `bestLine` is `[leaf, …, child move, root move]`. (The leftover
`if (bestMove.from != bestLine[last].from) { let rrrr = 0; }` at L3283 is a breakpoint anchor that
checks exactly this.) Nodes that return early (TT cutoff, quiescence, abort) return no line, so
the PV is often truncated.

The Haxe side (`Anaconda.buildEvaluationResultByData`) reads it as
`[data.move, ...data.bestLine]` **in forward order**. The reconstructed main line is therefore
garbled. It contains the root move twice, and every move after the first is applied to the wrong
position. Only `mainLine[0]` is used for playing, so the bot is unaffected, but any analysis
display built on it would be wrong.

### 14.4 Legacy client API

`tryMove` (uses `confirm`/`prompt` with Russian text, which does not exist in a worker), `move`,
`setField`, `takeBack`, `strMoves` (old notation letters: Dominator → "D", Defensor → "F"),
`getStrMoves`, `gameResult`, and `passMove` belong to a standalone board UI that once used this
class directly. Note that `gameResult` calls `fastMark`, which adds `variabilityArray[currentLine]`.
On a fresh instance that is `undefined` and makes the score `NaN`.

### 14.5 Variability: making the bot weaker on purpose

`initializeVariability()` assigns each root move a random offset in
`[−variability, +variability]` (rounded). `fastMark` adds the offset of the root move currently
being searched (`currentLine`) to every quiescence-root evaluation in that subtree. In effect,
every root move's score gets a fixed random bonus, so a weaker level picks among "roughly equal"
moves at random. With `variability = 500`, it sometimes gives up a Dominator.

Offsets are skipped near win scores, so wins and losses stay exact.

> **Review.**
> - This is an elegant trick, with one leak: **TT entries carry the offset of the root move under
>   which they were computed**. When root move B transposes into a position first searched under
>   root move A, it inherits A's offset. At high variability, that makes the noise less random than
>   intended. That is acceptable for a "weak bot" feature, but worth knowing.
> - In time mode, `variability` is never set (it stays 0), so the time-mode bot is always "full
>   strength". Strength is controlled only through the time budget.

---

## 15. The level mode (node budgets)

### 15.1 `bestMoveByLevel(level)` (L3912)

| level | node limit | variability |
|-------|-----------:|------------:|
| 0  |       3 000 | 500 |
| 1  |      10 000 | 250 |
| 2  |      30 000 | 100 |
| 3  |     100 000 |  50 |
| 4  |     300 000 |  25 |
| 5  |   1 000 000 |  20 |
| 6  |   3 000 000 |  15 |
| 7  |  10 000 000 |  15 |
| 8  |  30 000 000 |  10 |
| 9  |  70 000 000 |  10 |
| 10 | 150 000 000 |   8 |

It begins with `global.onmessage({data: "get"})`, which calls the worker's own message handler
with a payload that matches no command, so it does nothing. That is dead code.

### 15.2 `bestMoveByCount(limit)`

This is the same iterative-deepening loop as the time driver, with a 🔎 **node-count limit**
instead of a clock. `αβByCount` posts a progress string (`"37%"`) every 10 000 nodes.

### 15.3 Why a node budget is a good idea

Node limits make strength **independent of the user's hardware**: a level-5 bot plays the same on
a phone and on a desktop, and only the wait time differs. This is the standard way to build
reproducible weak levels.

### 15.4 Why it is "Not working atm"

- The worker posts **progress strings** (`"37%"`) through the same channel. The Haxe handler
  treats every message as a result object and crashes on `data.move` / `data.bestLine`.
- The final reply from `bestMoveByLevel` **lacks `completed: true`**. Unlike the time command, the
  `onmessage` handler at L2-7 does not set it, so the Haxe side never calls `fullResultCallback`.
- `bestMoveInf.bestLine` is never set in count mode, and the Haxe code iterates it
  unconditionally.
- In `αβByCount`'s **Black** branch, the root partial-result update checks
  `this.finish - performance.now() > 0` (L3681), copied from the time version. `finish` is 0 in
  count mode, so Black never gets partial-iteration results. It falls back to the last completed
  iteration, which is weaker but not broken.
- Quiescence nodes are not counted, so "nodes" means only main-search nodes, and wall time for one
  level varies a lot between quiet and tactical positions.

> **Review.** For v3.0, I would make **node budget plus variability** the only strength control,
> and let the time budget act as a safety cap. Use a typed message protocol: `{type: "progress"}`,
> `{type: "info", depth, score, pv}`, `{type: "bestmove", move}`.

---

## 16. Putting it together: one search, end to end

1. Haxe sends `{command: "bestMoveByTime", position: "pmeeee…w", time: 5000}`.
2. The worker builds a `Position` (fresh Zobrist keys, a repetition map holding only the root),
   resets the TT and history tables, and sets `finish`.
3. Iteration 1: aspiration window around 0. At the root (depth 1), the null-move test may prune;
   if so, a full-window re-search follows. The moves are unsorted (depth 1 < sortDepth), and each
   child goes straight into the quiescence search.
4. Iteration 2 onwards: the root is sorted by `sortMoves` using the TT from the previous iteration.
   Each root move is searched with PVS. Children at depth ≥ 2 probe and store the TT and sort
   their moves; children at depth 1 use the null move and unsorted moves; leaves use the
   quiescence search with incremental evaluation. Forcing moves extend; quiet moves that are
   rarely best get reduced.
5. After each finished iteration, `bestMoveInf` is posted. The Haxe side reports
   "partial result at depth N" to the player every third depth.
6. When time runs out, all nodes return ±∞ immediately. The root keeps whatever passed the
   partial-iteration rule, the worker posts the result with `completed: true`, and Haxe plays
   `mainLine[0]` and discards the worker.

---

## 17. Consolidated review: what to check and change

Ordered by my estimate of impact. Items marked **(bug)** are defects, as opposed to missing
techniques.

### Playing strength

1. **Re-search reduced moves when they beat α** (section 11). Without it, history reductions of up
   to 2 plies permanently hide quiet defensive moves.
2. **Handle Intellector threats in the quiescence search** (section 8): no stand pat while the
   Intellector is attacked, and include "Intellector steps onto a final cell" and promotions.
   This targets the horizon effect on the game's two winning conditions.
3. **Send the game history** for repetition detection (section 7.4), and make the draw score
   side-relative (section 7.3, **bug**: White-relative −0.1 favors Black regardless of the bot's
   side).
4. **Check `distanceToCenter`'s sign** (section 6, likely **bug**): Defensors and Liberators are
   pulled toward the edge.
5. **Add Intellector-safety evaluation**: attackers and defenders around it, escape cells.
6. **Widen the aspiration window and widen gradually on failure** (section 13).
7. **Tune the evaluation** (Texel tuning), then measure every change with 🔎 **SPRT** self-play
   instead of judging by eye.

### Speed (nodes per second and nodes per decision)

1. **Order moves at depth 1** (captures first), plus killer moves and the hash move. Drop the
   make-every-child `sortMoves` and the bubble sorts (section 10).
2. **Replace the TT** with a fixed-size typed-array table holding check keys (section 9). That
   gives speed, bounded memory, and collision safety in one change.
3. **Integer-packed moves and preallocated undo stacks** to stop GC churn (section 4).
4. **Real null-move pruning** (R = 2-3, depth ≥ 3) and SEE/delta pruning in the quiescence search
   (sections 8, 11).
5. Compute `isCheck()` lazily or incrementally, use lookup tables instead of `.includes`, and
   check the clock every N nodes.
6. Keep **one worker per game** and **keep the TT between moves**. This requires fixed Zobrist
   keys and skipping TT stores after an abort (section 12, latent **bug**).

### Correctness and robustness

1. **(bug)** The PV is collected leaf-first, and the Haxe side reads it forward (section 14.3).
2. **(bug)** The level mode is broken: progress strings, the missing `completed` flag, a missing
   `bestLine`, and the `finish` copy-paste error in the Black branch (section 15.4).
3. **(bug)** 32-bit Zobrist keys with no verification key (sections 4.3, 9).
4. The TT classifies results against the pre-narrowing window (section 9).
5. The hard-coded tables assume reachable positions. Arbitrary editor positions can freeze
   aggressors or corrupt the board (section 3). Validate positions or generate the tables.
6. Four drifting copies of the search, each with mirrored White/Black branches. A single negamax
   search with a pluggable `shouldStop()` (time or nodes) removes the duplication.
7. Verify move generation against `intellectorboard` with perft before trusting any strength
   change. (Defensor-initiated castling is intentionally absent, see section 5.4.)

### Porting notes for v3.0 (`client.botengine`)

- Keep the engine **self-contained** in its worker, with its own compact board representation.
  `intellectorboard`'s object-based model is the right tool for rules, UI, and validation, but too
  slow for the inner loop. Use `intellectorboard` as the **reference** in tests (perft, move-list
  equality on random positions), not as the engine's data model.
- Haxe can compile a separate JS target for the worker, so the engine can be written in Haxe with
  typed arrays (`haxe.io.Int32Array` etc.) instead of hand-written JS. Whether that is worth it
  compared with keeping a cleaned-up JS file is a decision to make explicitly.
- Keep the White-relative score in the UI layer and the side-to-move-relative score inside the
  engine (negamax), with the conversion happening exactly once at the message boundary.
