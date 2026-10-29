# Hxconda match results

Produced by `node scripts/hxconda/match.js --record "<label>"`. The candidate is `bin/hxconda.js` unless the label says otherwise; the baseline is `scripts/hxconda/baseline/hxconda.js`. Openings: `scripts/hxconda/openings.json`, each played twice with colours swapped. Elo is the candidate's, with its 95% confidence interval.

| Date | Commit | Label | Conditions | Pairs | W/D/L | Pair points 0/½/1/1½/2 | Elo | LLR | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| 2026-10-28 | 354670a | Calibration: same build, 2x nodes | 30000 vs 15000 nodes, noise 0; SPRT [0, 10], α=0.05, β=0.05 | 92 | 114/26/44 | 4/6/31/18/33 | 139.2 [94.1, 189.2] | 3.00 | accepted: stronger by more than 0 Elo |
| 2026-10-29 | 902c040 | B3: game history for repetitions | 30000 nodes, noise 0; SPRT [0, 10], α=0.05, β=0.05 | 312 | 278/87/259 | 0/21/251/40/0 | 10.6 [2.1, 19.0] | 3.01 | accepted: stronger by more than 0 Elo |
| 2026-10-29 | 902c040 | B3: game history for repetitions | 200000 nodes, noise 0; SPRT [0, 10], α=0.05, β=0.05 | 33 | 29/6/31 | 0/2/31/0/0 | -10.5 [-24.7, 3.6] | -2.98 | rejected: not stronger by 10 Elo |
| 2026-10-29 | 902c040 | B3: game history for repetitions, non-regression | 200000 nodes, noise 0; SPRT [-10, 0], α=0.05, β=0.05 | 83 | 76/18/72 | 0/3/73/7/0 | 8.4 [-4.5, 21.2] | 3.11 | accepted: stronger by more than -10 Elo |
| 2026-10-29 | f16ddf5 | B1: draw contempt 0.1 against the root side | 30000 nodes, noise 0; SPRT [0, 10], α=0.05, β=0.05 | 31 | 30/1/31 | 0/1/30/0/0 | -5.6 [-16.4, 5.2] | -3.49 | rejected: not stronger by 10 Elo |
| 2026-10-29 | f16ddf5 | B1: draw score 0, store guard by draw flag | 30000 nodes, noise 0; SPRT [0, 10], α=0.05, β=0.05 | 203 | 196/15/195 | 0/0/202/1/0 | 0.9 [-0.8, 2.5] | -56.84 | rejected: not stronger by 10 Elo |
| 2026-10-29 | f16ddf5 | B1: draw score 0, store guard by draw flag, non-regression | 30000 nodes, noise 0; SPRT [-10, 0], α=0.05, β=0.05 | 200 | 193/15/192 | 0/0/199/1/0 | 0.9 [-0.8, 2.6] | 78.14 | accepted: stronger by more than -10 Elo |
| 2026-10-29 | f16ddf5 | B1: draw score 0, store guard by draw flag, non-regression | 200000 nodes, noise 0; SPRT [-10, 0], α=0.05, β=0.05 | 33 | 32/4/30 | 0/0/31/2/0 | 10.5 [-3.6, 24.7] | 2.98 | accepted: stronger by more than -10 Elo |
