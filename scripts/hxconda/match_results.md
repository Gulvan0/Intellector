# Hxconda match results

Produced by `node scripts/hxconda/match.js --record "<label>"`. The candidate is `bin/hxconda.js` unless the label says otherwise; the baseline is `scripts/hxconda/baseline/hxconda.js`. Openings: `scripts/hxconda/openings.json`, each played twice with colours swapped. Elo is the candidate's, with its 95% confidence interval.

| Date | Commit | Label | Conditions | Pairs | W/D/L | Pair points 0/½/1/1½/2 | Elo | LLR | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| 2026-10-28 | 354670a | Calibration: same build, 2x nodes | 30000 vs 15000 nodes, noise 0; SPRT [0, 10], α=0.05, β=0.05 | 92 | 114/26/44 | 4/6/31/18/33 | 139.2 [94.1, 189.2] | 3.00 | accepted: stronger by more than 0 Elo |
