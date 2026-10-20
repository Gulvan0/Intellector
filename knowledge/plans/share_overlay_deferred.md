# Share overlay: deferred

Plan: `[[share_overlay_plan]]`.

## 1. Export as puzzle

**Why deferred:** a future group of the analysis page, not designed.

**How to apply:** one more `ShareGroup` descriptor (analysis only). The strip appears by itself once
a page has two groups; with three, the collapsed strip must stack (theme rule for three or more
equal controls), which `TabStrip` can't do yet.

## 2. Frame count and duration

**Why deferred:** the design dropped the info strip.

**How to apply:** if wanted, as the interval field's header hint, not as a new row.

## 3. Live updates while open

**Why deferred:** the overlay is a snapshot (decision 11).

**How to apply:** feed the game page's `PlyHistory` changes into the Share game page's PIN and the
animation's frames.
