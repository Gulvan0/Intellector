# Hxconda improvement plan

Proposed changes to the Hxconda engine (`src/engine/hxconda`), split by whether they keep its behaviour. Most items come from `[[anaconda_engine_guide]]`; the section numbers below point there.

## Acceptance procedure

Every change gets its own round: implement it, measure it, then accept or revert it before the next one starts.

**A change meant to keep the behaviour** (list A):

1. `node scripts/hxconda/compare.js level 120 11 0,1,2,3 --baseline`, plus `level 15 23 4,5` and `time 60 37 50,200,600`, all with `--baseline`. Any mismatch means the change altered behaviour: fix it, or move the item to list B.
2. `node scripts/hxconda/bench.js --record "<label>"`, on an otherwise idle machine: other load slows the dedicated cores through the shared cache and power budget, ±1.5-2.5% for the same build. Single pairs still swing by ±4-8% on an idle machine, so accept only a speedup with at least 8 of the 9 pairs faster at each of the three levels: a sign test, which a change without effect passes with p ≈ 0.02. Run-to-run drift is ±3-4%, so only the paired ratios of the same run count.

**A change meant to alter the behaviour** (list B):

1. `node scripts/hxconda/match.js --record "<label>"`: 30000 nodes per move, SPRT [0, 10]. A change aimed at speed rather than search quality is tested with `--time <ms>` instead, since node-limited games don't reward speed.
2. A change accepted at 30000 nodes is confirmed at a larger budget, since some techniques only pay off in deeper searches, or only hurt there. The confirmation is a non-regression test, `--nodes 200000 --elo0 -10 --elo1 0`, passing unless the change is worse by 10 Elo. Engines without noise play the same game whenever a change doesn't trigger, so a change that alters few games leaves most pairs identical; a second [0, 10] test then rejects on a handful of differing pairs, which only says "not +10 Elo".
3. `bench.js` is still run. Node-limited wall time stays meaningful as speed per node, even though the trees differ.

Calibration (`match_results.md`): doubling the nodes is worth about +140 Elo, detected after 92 pairs. Typical single improvements are worth 5-30 Elo, which takes hundreds to thousands of pairs; 6000 openings allow 12000 games (2000 until B10a). If a match ends "inconclusive" at the opening limit, generate more openings with `match.js --generate-openings <count>`.

**After accepting** either kind: copy `bin/hxconda.js` over `scripts/hxconda/baseline/hxconda.js` and commit both together with the result rows.

## Where the time goes

CPU profile of the accepted baseline (A10) on the 10 benchmark positions at level 5, self time per function:

| Share | Function | What it does |
|---|---|---|
| 30.2% | `MoveGenerator.generateCaptures` | every quiescence node generates all its captures |
| 9.5% | `orderedCaptures` | ordering keys of the quiescence captures, and their sorting |
| 7.2% | `sortMoves` | ordering keys of main search moves, depth ≥ 2 (no longer makes the children since B10) |
| 6.6% | `quiesce` | |
| 6.3% | `MoveGenerator.generateMoves` | main search nodes |
| 15.1% | `search` and the two move loops | including the inlined transposition table |
| 5.6% | `Board.attacksIntellector`, `isIntellectorAttackedAfter` | check detection, once per move loop and after every move |
| 3.2% | `Board.makeMove` | |
| 2.6% | garbage collection | |
| 1.9% | `SearchTuning.sortByKeys` | sorting of main search moves |

Quiescence and move generation dominate; sorting, allocation and the depth ≥ 2 nodes are a few percent each. Re-profile after every accepted change, since the shares shift.

Speed is worth strength: at about +140 Elo per doubling of the nodes, a 10% speedup is worth about +19 Elo in games played on time.

## A. Changes that keep the behaviour

The output must stay identical, so each change only alters how a result is computed. IDs are stable; the list order is the priority, by the profile above.

### Planned

None left.

### Tried

- **A1. Win check without making the move in move ordering.** **Rejected:** x1.004-1.007 against the baseline. `sortMoves` makes and unmakes every move at nodes of depth ≥ 2 only to ask whether the move wins at once, but those nodes are too few for this to matter.
- **A2. Incremental material score.** **Accepted:** x1.12-1.19 against the baseline. `Board` keeps the sum of piece-square values up to date in make/unmake, instead of `evaluate()` summing 59 squares at every quiescence root. Quiescence moves skip the update (`makeUnscoredMove`), since quiescence tracks its own score. Exact, because every value is a multiple of 0.5.
- **A3. Pick-next-best instead of sorting.** **Rejected:** x0.96-0.99 against the baseline. Selecting the earliest best remaining move reproduces the stable sort exactly, but every pick rescans the rest of the list, and most quiescence nodes search all their captures: the insertion sort of a short list is cheaper.
- **A4. Allocation-free move lists.** **Rejected:** x1.006-1.025 against the baseline, within or barely beyond the noise, so not worth the stack bookkeeping in every move loop. Moves and sort keys lived in one reusable stack of arrays rather than new arrays per node. Worth retrying after A6, once allocation is a larger share of the time.
- **A5. Targeted captures in deep quiescence.** **Rejected:** x0.97-0.98 against the A2 baseline, x1.000-1.039 after A6. From quiescence depth 2 on, only recaptures and Intellector captures are searched. Those nodes make 29% of the capture generations but, with fewer pieces left, only about 6-8% of the time, so little is there to win. Looking up the attackers of the target squares scans 12 rays from each and cost as much per call as a full generation (x0.82-0.87). Generating only for the own pieces that could reach a target on an empty board, through the occupancy masks and a reach bit mask per piece and square, about breaks even. Reversed progressor steps need inverted step tables: the opposite color's table is empty on the final rows.
- **A6. Piece lists.** **Accepted:** x1.10-1.15 against the baseline. `Board` keeps two 32-bit occupancy masks per color up to date in make/unmake, and both generators visit the side's own pieces through them in square order instead of scanning all 59 squares. The masks live in an `Int32Array`: in a plain array, a mask with bit 30 or 31 set is no small integer to V8 and turns the array into doubles, which cost most of the gain. Measured with 20 warm-up searches per process; with a single one, level 4 showed only x1.005-1.038, the candidate losing its first search to JIT tiering.
- **A7. Incremental check detection.** **Accepted:** x1.04-1.07 against the baseline. A move loop tries 10.8 moves on average, each followed by a check detection. Now each loop asks once whether the side to move already attacks the opponent's Intellector; it rarely does, and then every move gets the full detection. Otherwise only the moved piece and the dominator and aggressor lines from the Intellector through the vacated square can attack after a move, and castling only puts the defensor on the origin square. The precondition is needed: a moved piece can also block an attack of its own side's slider.
- **A8. Capture ordering keys during generation.** **Rejected:** x0.95-0.98 against the baseline. Computing the keys is about a third of `orderedCaptures` (3.5% of the time), mostly filling the array of keys, which generation still has to do. Pushing each key along with its capture slowed down the generator's inner loop by more than the second pass cost. Integer keys, all piece values being integers, gave x1.00 in a quick check: comparing the keys was never the cost.
- **A9. Transposition table and repetition counts on typed arrays.** **Accepted:** x1.03-1.05 against the baseline. The table's functions are inlined into `search` and `sortMoves`, which hid them from the profile: a level 5 benchmark run makes 7.7M `js.lib.Map` operations, about 12% of the time in a tight loop. Both maps became open-addressing tables with linear probing, keyed by the exact hash and growing by rehashing: `TranspositionTable` indexes its per-position entry arrays, and `VisitCounts` deletes with backward shifting and counts hash 0 apart. The entries are still objects; moving them into parallel typed arrays is left untried.
- **A10. Lookup tables in typed arrays.** **Accepted:** x1.06-1.07 against the baseline. `Board.pieces` is a `PieceArray`, an abstract over an `Int8Array` that reads and writes `Piece` values. `SquareLists` packs its squares into an `Int8Array` and its offsets into an `Int16Array`, and the piece values and piece-square scores live in `Float64Array`s.
- **A11. Negamax rewrite.** **Rejected:** x1.05 / x1.00 / x0.98 against the baseline, exact. One move loop ran on side-relative scores, `sign` times the white-relative ones that `search()` keeps returning, which removed 63 lines. Level 6 stayed slower over 15 interleaved pairs (x0.986). The cause wasn't found: the loop's own time dropped by 11%, and the inlining decisions and deoptimizations matched the baseline's. Worth reconsidering if the list B work on the move loop makes the two copies a burden.
- **A12. Exact delta pruning in quiescence.** **Rejected:** x1.00 / x1.03 / x1.01 against the baseline, 4/9, 8/9 and 6/9 pairs faster. A quiescence node never returns more for the capturing side than the score right after the capture, since the opponent can stand pat, so a capture whose `scoreAfterCapture` doesn't beat the bound can be skipped without changing any result. But such a child already returns at its stand-pat check, before generating captures: only the make, unmake and call are saved.

## B. Changes that alter the behaviour

### Fixes

1. **Side-relative draw score** (7.3). `DRAW_SCORE = -0.1` is white-relative, so a draw always slightly favours black. **Accepted as a fix without measurable effect:** `DRAW_SCORE = 0`, and the table store guard is a flag, propagated through the move loops and null-move pruning, telling whether a score comes from a repetition draw. Non-regression tests: +0.9 Elo [-0.8, 2.6] at 30000 nodes, +10.5 [-3.6, 24.7] at 200000. The draw score barely matters: even with the game history, 1 pair in 203 differed from the baseline's games at 30000 nodes, and before item 3 the 30000-node match played 1280 identical pairs, since a repetition then needed a 4-ply cycle inside the tree ending at depth ≥ 2. A contempt of 0.1 against the root side was just as neutral (1 differing pair in 31). The flag is narrower than the old `score != DRAW_SCORE` guard, which also skipped fail-low bounds equal to the draw score only because an ancestor's window came from a draw; with the guard added back, the flag build reproduces the old one in 7788/7788 positions.
2. **`distanceToCenter` sign** (6.3). Defensors, liberators and dominators got a bonus for being far from the centre, by mistake. **Accepted, flipped into a centrality bonus:** +122.7 Elo [81.0, 168.1] at 30000 nodes, +155.3 [104.7, 212.9] at 200000. Removing the term instead gave +103.5 [66.4, 143.1], and the flip beat the removal by +77.1 [45.9, 109.5] head to head. The flip also lowers these pieces' average value against the others, by about 30 per piece; a centred form, `(5 - distance)` per step, would keep it and is untried.
3. **Game history for repetitions** (7.4). **Accepted:** +10.6 Elo [2.1, 19.0] at 30000 nodes; at 200000, +8.4 [-4.5, 21.2], passing the non-regression test. The request's optional `history` lists the game's earlier positions in the Anaconda notation, and `Board` counts each as a visit. A return to any of them in the search scores as a draw, the same two-fold rule as for repetitions inside the tree; a true threefold against the pre-root history, as Stockfish requires, is untried.
4. **Transposition table soundness** (9). **Accepted as a fix without measurable effect:** non-regression tests -1.9 Elo [-8.2, 4.5] at 30000 nodes, +3.0 [-7.2, 13.2] at 200000; 3 pairs in 116 differed from the baseline's games. The table is keyed by the hash together with a second 32-bit verification key, which `compare.js` showed to be needed: one level 5 search out of 44 hit a hash collision. The key comes from a fixed-seed xorshift, leaving `Math.random` untouched, and is passed along the hash only at nodes deep enough to reach the table: keeping it up to date in make/unmake gave the same output at x0.96. Results are stored against the window the node searched, after narrowing and mate clamping. No store follows an aborted search, which changes nothing while the table lives for one request only.
5. **Level-mode root reports for black** (15.4). **Accepted:** +23.3 Elo [8.0, 38.6] at 30000 nodes, +21.7 [3.0, 40.5] at 200000. A minimizing root only reported mid-iteration progress at depth 1, so black fell back to the last completed iteration; now both sides report while the budget lasts. Time-limited searches were unaffected.
6. **Progressor checks on the home row.** **Accepted as a fix without measurable effect:** non-regression tests -2.8 Elo [-8.1, 2.6] at 30000 nodes, +3.3 [-6.8, 13.4] at 200000; 1 pair in 28 differed from the baseline's games. Check detection found progressor attackers through the opposite color's step table from the Intellector's square, which is empty on the final rows, so a progressor attacking an Intellector on its own back row (e.g. a white progressor on b6, c6 or d6 against c7) gave no check. It also listed home-row squares no progressor can stand on. Check detection now uses inverted step tables, `BoardGeometry.*_PROGRESSOR_ORIGINS`.
26. **Stalemate at the root.** A side without legal moves loses. Inside the tree this already held, since a move loop without moves returns its initial losing score, but a root without moves threw "Anaconda found no move to play", which `match.js` scored as a draw. **Accepted as exact:** the report now has no move and the losing score, which `match.js` scores as a stalemate loss; `compare.js` found no mismatch against the baseline.

### Search

7. **Re-search reduced moves that beat α** (11.2). **Accepted:** +79.6 Elo [47.7, 113.0] at 30000 nodes, +114.0 [72.7, 158.7] at 200000. History reductions of up to 2 plies and the table-gated late-move reductions stayed final, hiding quiet defensive moves. A reduced move scoring better than the best move so far is now searched again without its reduction: a null-window move first at a null window, then through the usual full-window re-search; the first move at the full window. Node-limited wall time dropped by 10-12% at levels 5-6, the trees differing.
8. **Order depth-1 nodes** (10.4). **Accepted:** +111.7 Elo [72.4, 153.9] at 30000 nodes, +80.8 [46.5, 116.6] at 200000. Depth-1 nodes, the most numerous non-quiescence nodes, searched in generation order; now their captures come first, ordered as in quiescence (most valuable victim, then cheapest attacker), and the quiet moves keep their generation order. Node-limited wall time also dropped by 2-5%, so the gain doesn't come from quiescence work hidden from the node count.
9. **Quiescence pruning** (8). Delta pruning is exact here with margin 0, and saves nothing measurable (A12). **Rejected, first-order SEE:** -11.0 Elo [-25.4, 3.4] at 50 ms per move. Quiescence skipped captures giving a piece for a cheaper one on a square the opponent defends, by the check-detection patterns applied to the target square. It was only x1.02-1.06 faster per node, and lost -26.5 Elo [-43.3, -9.8] at 30000 nodes: a defended square often still wins the exchange. A full SEE is untried, but needs the attackers of the square, which cost about a capture generation to collect (A5), against a gain of at most a few percent.
10. **Hash move and killer moves** (10). Store the best move per position and try it first, then two killer moves per ply. Once these work, the make-every-child ordering of `sortMoves` can go.
    - **Hash move: accepted.** +20.7 Elo [6.5, 35.1] at 30000 nodes on the 6000 openings, after +8.6 [-1.2, 18.4] ended inconclusive on the old 2000; the stop overshoots, so about +10 is likelier. +11.0 [-3.4, 25.4] at 200000, and x1.03-1.05 faster per node. At nodes of depth ≥ 2, the move of the position's deepest table entry that has one goes first, ahead of the `sortMoves` order.
    - **Killer moves at depth-1 nodes: accepted.** +17.0 Elo [4.5, 29.5] at 30000 nodes, +9.6 [-4.2, 23.5] at 200000, but x0.96-1.00 per node: about 6 of those Elo go back when playing on time. Each ply from the root keeps the two latest distinct quiet moves that caused a cutoff there; depth-1 nodes search them right after the captures. Deeper nodes don't use them yet: their `sortMoves` keys mix table scores, an unbounded history bonus and capture gains, which leave killers no clean place.
    - **Ordering without the children's table entries: accepted.** +9.6 Elo [1.9, 17.2] at 30000 nodes, +12.0 [-2.7, 26.8] at 200000, and x1.33-1.41 faster per node. `sortMoves` made every child and read its table entries for an ordering key; now the keys come from the move alone: immediate wins (an Intellector step onto a final square; Intellector captures rank highest among captures), captures not losing material by their gain, the killer moves, the other quiet moves by history, then the losing captures. The hash move still goes first.
11. **Intellector threats in quiescence** (8). No stand pat while the own Intellector is attacked. Also add Intellector steps onto a final square, and promotions, to the quiescence moves. This adds quiescence nodes, so test it with `--time`: the node budget doesn't count them.
    - **No stand pat in check, with all moves as evasions: rejected.** -133.6 Elo [-183.9, -88.2] at 50 ms per move, against +511.5 after 5 pairs at 30000 nodes, which only shows how much uncounted quiescence work it added. `search()` took an `isInCheck` flag (the move loops' `isCheck`, the root's own check, `attacksIntellector` for the null-move child), and quiescence children got theirs from the incremental check detection, valid since a capturer able to take the Intellector takes it first.
    - **Evasions at every quiescence ply: rejected.** -29.2 Elo [-50.5, -8.0] at 50 ms per move. In check, a node searched the captures and Intellector moves (castling included) that leave its Intellector unattacked, standing pat only if there were none, since quiet blocks aren't generated; the null move was skipped at the root and in check. Quiescence children got their check from the incremental detection, which costs only x0.96-0.97; the evasions themselves made it x0.78 per counted node on 200 match openings.
    - **Evasions at the main search's leaves only: accepted.** +10.9 Elo [2.2, 19.6] at 50 ms, and +15.6 [-0.6, 32.0] at 200 ms, passing the non-regression test [-10, 0]; x0.93 per counted node on the match openings. Only the depth-0 node searches the evasions, its check flag coming from the move loops, so quiescence needs no check detection; deeper plies stand pat as before. `bench.js` measures x0.68 for it: its 10 playout positions hold far more checks than games from the openings, so its speed figures overstate any cost tied to checks.
    - Without stand pat, the null move at the root can prove a win: `search()` clamps β = +∞ to `WHITE_WIN_SCORE` before the null-move test `beta < +∞`, so even `run()`'s full-window fallback runs it, and a pruned root has no move, which made 156 games in 202 pairs end with "no move". Hence the null move is skipped at the root.
12. **Real null-move pruning** (11.4): reduction R = 2-3 at depth ≥ 3, skipped while the own Intellector is attacked.
    - **R = 2, 3 from depth 6, behind a static evaluation gate: accepted.** +12.2 Elo [2.5, 21.9] at 30000 nodes, +7.9 [-5.0, 20.8] at 200000 (non-regression [-10, 0]), and +11.5 [2.3, 20.6] at 50 ms against B11c, despite x0.94-0.95 per node. A node of depth ≥ 3 passes and searches the child at a null window, R plies shallower, returning the bound if it still holds. Skipped at the root, in check, right after a null move, and when the side to move has nothing but its Intellector and progressors, where zugzwang is likeliest. It is only tried if the static evaluation already reaches the bound. A decisive score after the pass becomes the bound, since passing is no legal way to win or lose. The depth-1 null move stays as it was, skipped right after a null move too.
13. **Stronger extension for Intellector attacks** (11.1): a full ply instead of half, with a per-line extension budget.
14. **Reduction exemptions** (11.2): no reductions at the root, for the first moves of a node, or while the own Intellector is attacked.
15. **Aspiration windows** (13.4): start wider, around ±50, and widen gradually on failure instead of jumping to ±∞. Repeat the re-search if it fails again.
16. **Integer scores** (12): round the piece-square values and drop the 0.5 steps, so a null window is a true null window.

### Evaluation

17. **Intellector safety** (6): attackers near the Intellector, defensors next to it, escape squares.
18. **Free path of the Intellector** (6): a bonus for an uncontested route to the final row.
19. **Real mobility approximation** (6): count the free first steps of each ray instead of the empty-board mobility.
20. **Texel tuning** (6): tune material and piece-square values on positions from self-play games.

### Infrastructure and protocol

21. **Count quiescence nodes in the node budget** (15.4). Makes the levels' wait times more even, but changes what each level means: the level table needs recalibrating, using `match.js` against the old levels.
22. **Time management** (13.2): a soft limit (don't start an iteration after about half the budget), a hard limit, and a clock check every 1024 nodes. Affects timing only, so it is tested with `--time`.
23. **Bounded transposition table** (9): fixed size with a depth-preferred plus always-replace scheme. Bounded memory for long searches; the replacement changes results.
24. **One worker per game, keeping the table between moves** (1.1). Needs seeded Zobrist keys, item 4 and item 23.
25. **Personalities**: per-personality evaluation tables and candidate-move biases, on top of items 17-18.
