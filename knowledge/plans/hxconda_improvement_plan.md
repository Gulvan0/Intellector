# Hxconda improvement plan

Proposed changes to the Hxconda engine (`src/engine/hxconda`), split by whether they keep its behaviour. Most items come from `[[anaconda_engine_guide]]`; the section numbers below point there.

## Acceptance procedure

Every change gets its own round: implement it, measure it, then accept or revert it before the next one starts.

**A change meant to keep the behaviour** (list A):

1. `node scripts/hxconda/compare.js level 120 11 0,1,2,3 --baseline`, plus `level 15 23 4,5` and `time 60 37 50,200,600`, all with `--baseline`. Any mismatch means the change altered behaviour: fix it, or move the item to list B.
2. `node scripts/hxconda/bench.js --record "<label>"`. Accept only a speedup against the baseline clearly beyond the ±1% head-to-head noise, at all three levels. Run-to-run drift is ±3-4%, so only the speedup against the baseline, measured in the same interleaved run, counts.

**A change meant to alter the behaviour** (list B):

1. `node scripts/hxconda/match.js --record "<label>"`: 30000 nodes per move, SPRT [0, 10]. A change aimed at speed rather than search quality is tested with `--time <ms>` instead, since node-limited games don't reward speed.
2. A change accepted at 30000 nodes is confirmed at a larger budget (`--nodes 200000`), since some techniques only pay off in deeper searches.
3. `bench.js` is still run. Node-limited wall time stays meaningful as speed per node, even though the trees differ.

Calibration (`match_results.md`): doubling the nodes is worth about +140 Elo, detected after 92 pairs. Typical single improvements are worth 5-30 Elo, which takes hundreds to thousands of pairs; 2000 openings allow 4000 games. If a match ends "inconclusive" at the opening limit, generate more openings with `match.js --generate-openings <count>`.

**After accepting** either kind: copy `bin/hxconda.js` over `scripts/hxconda/baseline/hxconda.js` and commit both together with the result rows.

## Where the time goes

CPU profile of the accepted baseline (A2) on the 10 benchmark positions at level 5, self time per function:

| Share | Function | What it does |
|---|---|---|
| 37.1% | `MoveGenerator.generateCaptures` | every quiescence node generates all its captures |
| 8.5% | `Board.isIntellectorAttacked` | runs after every move of the main search |
| 7.4% | `MoveGenerator.generateMoves` | main search nodes |
| 7.4% | `orderedCaptures` | ordering keys of the quiescence captures |
| 6.0% | `quiesce` | |
| 14.3% | `search` and the two move loops | |
| 3.7% | `sortMoves` | ordering keys of main search moves, depth ≥ 2 |
| 1.7% | `SearchTuning.sortByKeys` | all sorting |
| 2.2% | garbage collection | |
| 1.3% | `Board.hashAfter` | |

Quiescence and move generation dominate; sorting, allocation and the depth ≥ 2 nodes are a few percent each. Re-profile after every accepted change, since the shares shift.

Speed is worth strength: at about +140 Elo per doubling of the nodes, a 10% speedup is worth about +19 Elo in games played on time.

## A. Changes that keep the behaviour

The output must stay identical, so each change only alters how a result is computed. IDs are stable; the list order is the priority, by the profile above.

### Planned

1. **A5. Targeted captures in deep quiescence.** From quiescence depth 2 on, only recaptures and Intellector captures are searched, yet all captures get generated and then filtered out. Instead, look up the attackers of those few target squares, as `isIntellectorAttacked` does. Order them as the generator would: by origin square, then direction or step index, then promotion variant. That keeps the order exact. Counting first how many quiescence nodes are that deep tells how much of the 37% this can reach.
2. **A6. Piece lists.** Both generators, together 44% of the time, scan all 59 squares for the side's pieces. Iterate its own pieces in square order instead, for example through two 32-bit occupancy masks per color kept up to date in make/unmake.
3. **A7. Incremental check detection** (8.5%). After a move, only the moved piece and the lines through the vacated square can start attacking an Intellector; every other attack stays as it was before the move. Exact but intricate.
4. **A8. Capture ordering keys during generation.** `orderedCaptures` makes a second pass over the captures to compute their keys (7.4%). Compute each key when the capture is pushed instead.
5. **A9. Transposition table and repetition counts on typed arrays.** An open-addressing table keyed by the exact hash, with per-position entry chains in parallel typed arrays, replaces `js.lib.Map` and the entry objects. It must stay unbounded, growing by rehashing, and keep the entry order, so its semantics don't change. The table's functions don't show up among the top entries of the profile, so the expected gain is small.
6. **A10. Lookup tables in typed arrays.** `Board.pieces`, `SquareLists.squares` and the score tables become `Int8Array`/`Int32Array`/`Float64Array`. Small gain.
7. **A11. Negamax rewrite.** One move loop instead of a maximizer/minimizer pair. Negation of these scores is exact, but `Math.max`/`Math.min` and the asymmetric PVS windows must be mirrored precisely. Pure code-size win: attempt it only as an exact refactoring, verified by `compare.js`.

### Tried

- **A1. Win check without making the move in move ordering.** **Rejected:** x1.004-1.007 against the baseline. `sortMoves` makes and unmakes every move at nodes of depth ≥ 2 only to ask whether the move wins at once, but those nodes are too few for this to matter.
- **A2. Incremental material score.** **Accepted:** x1.12-1.19 against the baseline. `Board` keeps the sum of piece-square values up to date in make/unmake, instead of `evaluate()` summing 59 squares at every quiescence root. Quiescence moves skip the update (`makeUnscoredMove`), since quiescence tracks its own score. Exact, because every value is a multiple of 0.5.
- **A3. Pick-next-best instead of sorting.** **Rejected:** x0.96-0.99 against the baseline. Selecting the earliest best remaining move reproduces the stable sort exactly, but every pick rescans the rest of the list, and most quiescence nodes search all their captures: the insertion sort of a short list is cheaper.
- **A4. Allocation-free move lists.** **Rejected:** x1.006-1.025 against the baseline, within or barely beyond the noise, so not worth the stack bookkeeping in every move loop. Moves and sort keys lived in one reusable stack of arrays rather than new arrays per node. Worth retrying after A5 and A6, once allocation is a larger share of the time.

## B. Changes that alter the behaviour

### Fixes

1. **Side-relative draw score** (7.3). `DRAW_SCORE = -0.1` is white-relative, so a draw always slightly favours black. Make it 0, or a contempt relative to the engine's side.
2. **`distanceToCenter` sign** (6.3). Defensors, liberators and dominators get a bonus for being far from the centre. **Needs a decision on the intent** before testing the flip: is keeping defensors on the edge deliberate?
3. **Game history for repetitions** (7.4). The request carries the position hashes since the start (or since the last capture), so the engine sees real threefold repetitions. Protocol extension; `match.js` already knows the history and would pass it.
4. **Transposition table soundness** (9). Add a second 32-bit verification key, store against the effective window instead of the pre-narrowing one, and skip stores after an aborted search.
5. **Level-mode root reports for black** (15.4). A minimizing root only reports mid-iteration progress at depth 1, so black falls back to the last completed iteration.

### Search

6. **Re-search reduced moves that beat α** (11.2). History reductions of up to 2 plies currently stay final, hiding quiet defensive moves. Expected to be the largest strength gain.
7. **Order depth-1 nodes** (10.4): captures first, by MVV-LVA. Depth-1 nodes are the most numerous non-quiescence nodes and search in board order today; better cutoffs there shrink the quiescence work they spawn.
8. **Quiescence pruning** (8): delta pruning first, then static exchange evaluation (SEE). Quiescence is where most of the time goes, so cutting its nodes is the largest speed lever among the behaviour-altering items. Tested with `--time`.
9. **Hash move and killer moves** (10). Store the best move per position and try it first, then two killer moves per ply. Once these work, the make-every-child ordering of `sortMoves` can go.
10. **Intellector threats in quiescence** (8). No stand pat while the own Intellector is attacked. Also add Intellector steps onto a final square, and promotions, to the quiescence moves. This adds quiescence nodes, so test it after the quiescence pruning.
11. **Real null-move pruning** (11.4): reduction R = 2-3 at depth ≥ 3, skipped while the own Intellector is attacked.
12. **Stronger extension for Intellector attacks** (11.1): a full ply instead of half, with a per-line extension budget.
13. **Reduction exemptions** (11.2): no reductions at the root, for the first moves of a node, or while the own Intellector is attacked.
14. **Aspiration windows** (13.4): start wider, around ±50, and widen gradually on failure instead of jumping to ±∞. Repeat the re-search if it fails again.
15. **Integer scores** (12): round the piece-square values and drop the 0.5 steps, so a null window is a true null window.

### Evaluation

16. **Intellector safety** (6): attackers near the Intellector, defensors next to it, escape squares.
17. **Free path of the Intellector** (6): a bonus for an uncontested route to the final row.
18. **Real mobility approximation** (6): count the free first steps of each ray instead of the empty-board mobility.
19. **Texel tuning** (6): tune material and piece-square values on positions from self-play games.

### Infrastructure and protocol

20. **Count quiescence nodes in the node budget** (15.4). Makes the levels' wait times more even, but changes what each level means: the level table needs recalibrating, using `match.js` against the old levels.
21. **Time management** (13.2): a soft limit (don't start an iteration after about half the budget), a hard limit, and a clock check every 1024 nodes. Affects timing only, so it is tested with `--time`.
22. **Bounded transposition table** (9): fixed size with a depth-preferred plus always-replace scheme. Bounded memory for long searches; the replacement changes results.
23. **One worker per game, keeping the table between moves** (1.1). Needs seeded Zobrist keys, item 4 and item 22.
24. **Personalities**: per-personality evaluation tables and candidate-move biases, on top of items 16-17.
