# Strength to parameters

cpl = centiprogressor loss

strength | min cpl | max cpl | depth | perfect own plies before enabling cpl window | evaluate all possible moves
1 | 200 | unbounded | 6 | 0 | yes
2 | 100 | 500 | 6 | 1 | yes
3 | 50 | 300 | 8 | 2 | no
4 | 25 | 150 | 8 | 3 | no
5 | 20 | 100 | 8 | 4 | no
6 | 10 | 80 | 10 | 5 | no
7 | 0 | 45 | 10 | 6 | no
8 | 0 | 20 | 10 | 7 | no
9 | 0 | 0 | 12 | N/A | no

# Styles

## Standard

Nothing special

## Vrezh

- In base piece costs, favours agressors slightly more
- Prefers checks
- Prefers sacrifices
- Contempt factor: draw is evaluated as -200 centiprogressors

## Trailblazer

- In base piece costs, favours progressors slightly more
- Prefers progressor moves
- Prefers forward intellector moves

## Fortress

- In base piece costs, favours defensors slightly more
- Prefers to keep every piece defended
- Can attack, but doesn't like to counter-attack when being attacked
- Contempt factor: draw is evaluated as +200 centiprogressors

## Unchained

- In base piece costs, favours liberators slightly more
- Prefers to keep its pieces a little more scattered, or at least keep more hexes attacked by its own pieces
- Prefers 2-hex liberator jumps to 1-hex moves; for agressors and dominators, the further the distance travelled by the piece is, the more it likes this move

# Weakening details

Engine runs at specified depth, defined by the strength. If the allocated time runs out before it finishes its calculation, just fall back to the previous even depth.

During the first few moves (the amount is defined by the strength), it chooses absolute best moves.

After these were played, the following algorithm is applies:

1. Evaluate the position and gather the moves the score of which is known (i.e., ones that weren't pruned away). For strengths 1-2, evaluate the score of EVERY possible move instead.
2. Find moves with scores that fit into the window: `[best_move_score - max_cpl; best_move_score - min_cpl]` (min/max cpl are defined by the strength). If there are none, instantly play the worst move whose score is above `best_move_score - min_cpl`. If there are some, proceed to the next step
3. Unless it's Haxaconda Standard, adjust scores by adding/substracting values from the score based on the bot's intricacies
4. Randomly pick a move according to the distribution defined by weights. The weight of each move is `(100/(best_adjusted_score - adjusted_score + 1))^level`

# Resolved gaps (as built)

- **Scored moves (MultiPV-3)**: a weakened search scores the root moves only at depths 1 and 2 and at
  the even depths from 6 (strengths 1-2) or 8 (strengths 3+); every other depth is a plain search.
  At a scored depth, the best move and the 3 best moves inside the window (the best one among them when
  `min_cpl` is 0) get exact scores; the other
  moves only get null-window bounds (reduced like in the main search, settled unreduced when they
  pass). The "evaluate all moves" column is dropped. Moves are ordered by the previous scored depth.
- **Speed limit**: a weakened search may take at most `max(3 x the plain search at the same depth,
  0.5 s)`. Scoring every move in the window exactly cost x3.5-75; MultiPV-3 brought it to about x2-3.
- **Style split**: piece costs, Trailblazer's advancement bonuses and contempt change the search's
  evaluation (`Evaluation.useStyle`, `Evaluation.drawScore`), so they act on every move, perfect plies
  included. The "Prefers …" traits are step-3 bonuses (`StyleBonuses`) on the window candidates only.
- **Values** (centiprogressors, from the bot's side): favourite piece costs, both colours: progressor
  115 (Trailblazer), aggressor 230 (Vrezh), defensor 170 (Fortress), liberator 195 (Unchained).
  Trailblazer advancement x1.5: progressor 0 0 30 75 150 225, intellector 0 8 15 30 75 150.
  Vrezh: check +40; sacrifice +50 (the moved piece ends attacked, and losing it there - undefended, or
  to a cheaper attacker - costs more than the move captured). Trailblazer: progressor move +30,
  forward intellector move +30. Fortress: -20 per own non-intellector piece left undefended (after
  minus before); -40 for a counter-attack while attacked (an own piece was attacked, the move doesn't
  reduce the attacked own pieces but attacks more enemy ones, intellector included). Unchained: +3 per
  hex attacked by own pieces (after minus before); 2-hex liberator jump +25; aggressor/dominator +8
  per ray step beyond the first.
- **Exponent**: "level" in the weights is the strength.
- **Perfect own plies**: counted over the game's current position history (takebacks undo them).
- **Decisive scores**: no special case; weak bots may miss wins.
- **Empty window**: the "worst move above `best - min_cpl`" is judged by the bounds the null-window
  tests gave, without extra searches.
- **Timeout**: the base is the latest completed even iteration (depth 1 if none). A perfect move
  plays the abandoned even iteration's best move so far, if it has one. A weakened move's base is the
  latest completed scored even depth (depth 2 always is one); it merges in the abandoned scored
  depth's records only if that depth's best so far differs from the base's best.
