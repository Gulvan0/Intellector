# Hxconda benchmark results

Produced by `node scripts/hxconda/bench.js --record "<label>"` after building the worker with `haxe hxconda.hxml`.

Each level cell holds the median total wall time in milliseconds, over 5 interleaved runs, of node-limited searches on 10 fixed playout positions: reference Anaconda (`reference/position.js`) / baseline (`baseline/hxconda.js`, the last accepted build) / candidate (`bin/hxconda.js`). The speedup columns give the candidate's speedup at levels 4 / 5 / 6. Head-to-head noise against the baseline is about ±1%. Compare rows recorded on the same machine only.

Before recording a speedup, check with `scripts/hxconda/compare.js --baseline` that a change meant to keep the behaviour does keep it.

## Earlier format

Reference / candidate, fastest of 3 runs. Rows labelled "(vm harness)" ran the engines inside `vm` contexts, which slows global lookups in both engines.

| Date | Commit | Label | Level 4 (300k nodes) | Level 5 (1M nodes) | Level 6 (3M nodes) | Machine |
|---|---|---|---|---|---|---|
| 2026-10-28 | 354670a | Initial port (vm harness) | 4336 / 2509 (x1.73) | 12402 / 7228 (x1.72) | 35962 / 21015 (x1.71) | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | Subpackages, typed protocol (vm harness) | 4440 / 2569 (x1.73) | 12566 / 7546 (x1.67) | 34730 / 20676 (x1.68) | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | Baseline, in-realm harness | 2270 / 1400 (x1.62) | 6710 / 4272 (x1.57) | 18797 / 12168 (x1.54) | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | A1: win check without making the move (rejected: x1.004-1.007 vs baseline head-to-head) | 2121 / 1351 (x1.57) | 6905 / 4149 (x1.66) | 19445 / 12464 (x1.56) | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |

## Results

| Date | Commit | Label | Level 4 (300k nodes) | Level 5 (1M nodes) | Level 6 (3M nodes) | Speedup vs baseline | Speedup vs reference | Machine |
|---|---|---|---|---|---|---|---|---|
| 2026-10-28 | 354670a | A2: incremental material score | 1931 / 1263 / 1078 | 6168 / 4052 / 3614 | 19540 / 12670 / 10635 | 1.172 / 1.121 / 1.191 | 1.79 / 1.71 / 1.84 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | A3: pick next best instead of sorting (rejected) | 1902 / 1063 / 1071 | 6257 / 3527 / 3654 | 18936 / 10340 / 10752 | 0.993 / 0.965 / 0.962 | 1.78 / 1.71 / 1.76 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | A4: allocation-free move lists (rejected) | 2064 / 1174 / 1156 | 6669 / 3682 / 3661 | 20142 / 11236 / 10967 | 1.016 / 1.006 / 1.025 | 1.79 / 1.82 / 1.84 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
