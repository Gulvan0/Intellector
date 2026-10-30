# Hxconda benchmark results

Produced by `node scripts/hxconda/bench.js --record "<label>"` after building the worker with `haxe hxconda.hxml`.

Each level cell holds the median total wall time in milliseconds, over 9 repetitions after 20 warm-up searches, of node-limited searches on 10 fixed playout positions: reference Anaconda (`reference/position.js`) / baseline (`baseline/hxconda.js`, the last accepted build) / candidate (`bin/hxconda.js`). Each repetition runs the baseline and the candidate back to back, in alternating order; the speedup vs baseline is the median of these pairs' time ratios, and the range column gives the lowest and highest pair ratio, the noise of that row, and how many pairs were faster than the baseline. All columns list levels 4 / 5 / 6. The runs are pinned to dedicated performance cores at high priority with a fixed V8 heap schedule (`isolation.js`), but other load on the machine still slows them through the shared cache and the power budget: bench on an otherwise idle machine. Compare rows recorded on the same machine only.

Before recording a speedup, check with `scripts/hxconda/compare.js --baseline` that a change meant to keep the behaviour does keep it.

## Earlier format

Reference / candidate, fastest of 3 runs. Rows labelled "(vm harness)" ran the engines inside `vm` contexts, which slows global lookups in both engines.

| Date | Commit | Label | Level 4 (300k nodes) | Level 5 (1M nodes) | Level 6 (3M nodes) | Machine |
|---|---|---|---|---|---|---|
| 2026-10-28 | 354670a | Initial port (vm harness) | 4336 / 2509 (x1.73) | 12402 / 7228 (x1.72) | 35962 / 21015 (x1.71) | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | Subpackages, typed protocol (vm harness) | 4440 / 2569 (x1.73) | 12566 / 7546 (x1.67) | 34730 / 20676 (x1.68) | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | Baseline, in-realm harness | 2270 / 1400 (x1.62) | 6710 / 4272 (x1.57) | 18797 / 12168 (x1.54) | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | A1: win check without making the move (rejected: x1.004-1.007 vs baseline head-to-head) | 2121 / 1351 (x1.57) | 6905 / 4149 (x1.66) | 19445 / 12464 (x1.56) | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |

## Interleaved medians

5 repetitions, each running reference, baseline and candidate in that order, unpinned; the speedup is the ratio of the medians. Head-to-head noise against the baseline was about ±1% on an idle machine, ±2% under load.

| Date | Commit | Label | Level 4 (300k nodes) | Level 5 (1M nodes) | Level 6 (3M nodes) | Speedup vs baseline | Speedup vs reference | Machine |
|---|---|---|---|---|---|---|---|---|
| 2026-10-28 | 354670a | A2: incremental material score | 1931 / 1263 / 1078 | 6168 / 4052 / 3614 | 19540 / 12670 / 10635 | 1.172 / 1.121 / 1.191 | 1.79 / 1.71 / 1.84 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | A3: pick next best instead of sorting (rejected) | 1902 / 1063 / 1071 | 6257 / 3527 / 3654 | 18936 / 10340 / 10752 | 0.993 / 0.965 / 0.962 | 1.78 / 1.71 / 1.76 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-28 | 354670a | A4: allocation-free move lists (rejected) | 2064 / 1174 / 1156 | 6669 / 3682 / 3661 | 20142 / 11236 / 10967 | 1.016 / 1.006 / 1.025 | 1.79 / 1.82 / 1.84 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | 4148bcb | A5: targeted captures in deep quiescence (rejected) | 2040 / 1101 / 1135 | 6478 / 3487 / 3600 | 18100 / 10215 / 10459 | 0.970 / 0.969 / 0.977 | 1.80 / 1.80 / 1.73 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | 4148bcb | A6: piece lists via occupancy masks (1 warm-up search) | 2037 / 1059 / 1054 | 6101 / 3365 / 3100 | 19092 / 10501 / 9453 | 1.005 / 1.085 / 1.111 | 1.93 / 1.97 / 2.02 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | 4148bcb | A6: piece lists via occupancy masks | 1855 / 1001 / 883 | 5821 / 3252 / 2953 | 18690 / 10106 / 8800 | 1.134 / 1.101 / 1.148 | 2.10 / 1.97 / 2.12 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | 971a6d1 | A5 retry over the occupancy masks, target bit masks (rejected) | 1771 / 870 / 870 | 5771 / 2910 / 2801 | 17554 / 8688 / 8632 | 1.000 / 1.039 / 1.006 | 2.04 / 2.06 / 2.03 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | bb40ed4 | A7: incremental check detection | 2034 / 1011 / 963 | 5844 / 2962 / 2771 | 17328 / 8689 / 8358 | 1.050 / 1.069 / 1.040 | 2.11 / 2.11 / 2.07 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | ff2f36d | A8: capture ordering keys during generation (rejected) | 1735 / 831 / 850 | 5644 / 2681 / 2765 | 17825 / 8419 / 8855 | 0.978 / 0.970 / 0.951 | 2.04 / 2.04 / 2.01 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | 36d38a2 | A9: open-addressing transposition table and visit counts | 1709 / 821 / 800 | 5739 / 2838 / 2707 | 17627 / 8334 / 8025 | 1.026 / 1.048 / 1.039 | 2.14 / 2.12 / 2.20 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | 019fdb0 | A10: lookup tables in typed arrays | 1773 / 822 / 770 | 5800 / 2806 / 2649 | 17877 / 7937 / 7416 | 1.068 / 1.059 / 1.070 | 2.30 / 2.19 / 2.41 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | 1689ac5 | A11: single side-relative move loop (rejected) | 1953 / 871 / 827 | 6312 / 2633 / 2635 | 18242 / 7819 / 7985 | 1.053 / 0.999 / 0.979 | 2.36 / 2.40 / 2.28 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |

## Results

| Date | Commit | Label | Level 4 (300k nodes) | Level 5 (1M nodes) | Level 6 (3M nodes) | Speedup vs baseline | Pair ratio range (pairs faster) | Speedup vs reference | Machine |
|---|---|---|---|---|---|---|---|---|---|
| 2026-10-29 | 902c040 | B3: game history for repetitions | 1948 / 886 / 847 | 6779 / 2842 / 2855 | 19297 / 8193 / 8249 | 1.008 / 1.001 / 0.993 | 0.967-1.087 / 0.963-1.047 / 0.966-1.024 | 2.34 / 2.34 / 2.35 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-29 | f16ddf5 | B1: draw score 0, store guard by draw flag | 2213 / 922 / 937 | 7113 / 3001 / 2979 | 21188 / 9037 / 8930 | 1.008 / 1.005 / 1.008 | 0.956-1.068 (6/9 faster) / 0.972-1.054 (7/9 faster) / 0.979-1.039 (6/9 faster) | 2.41 / 2.36 / 2.38 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-30 | 9893910 | B2: centrality bonus (distance term flipped) | 2025 / 863 / 849 | 6506 / 2773 / 2783 | 18953 / 8078 / 8007 | 1.009 / 0.987 / 1.019 | 0.946-1.049 (7/9 faster) / 0.971-1.032 (4/9 faster) / 0.988-1.058 (8/9 faster) | 2.36 / 2.33 / 2.38 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-30 | 135c934 | B4: TT verification key kept up to date in make/unmake (superseded: identical output, slower) | 2156 / 912 / 941 | 6859 / 2914 / 3011 | 20006 / 8310 / 8620 | 0.968 / 0.962 / 0.964 | 0.934-1.046 (2/9 faster) / 0.945-0.990 (0/9 faster) / 0.934-0.993 (0/9 faster) | 2.30 / 2.28 / 2.33 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-30 | 135c934 | B4: TT verification key passed along the hash, effective-window stores, no stores after an abort | 2021 / 850 / 845 | 6488 / 2785 / 2809 | 19972 / 8225 / 8266 | 0.991 / 0.991 / 1.001 | 0.963-1.019 (4/9 faster) / 0.948-1.019 (4/9 faster) / 0.978-1.050 (5/9 faster) | 2.40 / 2.31 / 2.41 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-30 | 885d38d | B5: level-mode root progress for black | 2178 / 913 / 931 | 7057 / 3032 / 2933 | 20742 / 8642 / 8612 | 0.997 / 1.009 / 0.996 | 0.968-1.047 (4/9 faster) / 0.976-1.052 (6/9 faster) / 0.956-1.028 (3/9 faster) | 2.37 / 2.35 / 2.41 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-30 | 448ed28 | B6: progressor checks through inverted step tables | 2137 / 917 / 915 | 7037 / 3034 / 2990 | 20191 / 8530 / 8519 | 1.000 / 0.998 / 1.002 | 0.962-1.026 (4/9 faster) / 0.972-1.038 (4/9 faster) / 0.979-1.012 (5/9 faster) | 2.34 / 2.33 / 2.38 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-30 | 10b8675 | B7: re-search reduced moves that beat the best score | 2189 / 946 / 915 | 6738 / 2915 / 2617 | 20611 / 8439 / 7702 | 0.996 / 1.116 / 1.104 | 0.924-1.077 (4/9 faster) / 1.073-1.130 (9/9 faster) / 1.081-1.133 (9/9 faster) | 2.40 / 2.57 / 2.68 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-30 | 9c0be43 | B8: captures first by MVV-LVA at depth-1 nodes | 2199 / 929 / 895 | 6840 / 2673 / 2628 | 20673 / 7868 / 7702 | 1.046 / 1.020 / 1.019 | 0.957-1.060 (7/9 faster) / 0.989-1.055 (7/9 faster) / 0.993-1.052 (8/9 faster) | 2.47 / 2.60 / 2.67 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
| 2026-10-30 | 7660738 | A12: exact delta pruning of quiescence captures (rejected) | 2148 / 859 / 849 | 6821 / 2644 / 2618 | 20399 / 7634 / 7536 | 0.999 / 1.028 / 1.013 | 0.924-1.048 (4/9 faster) / 0.978-1.037 (8/9 faster) / 0.988-1.019 (6/9 faster) | 2.53 / 2.60 / 2.69 | 12th Gen Intel(R) Core(TM) i7-12800HX, Node v22.12.0 |
