# Viewport sizes for layout testing

Sizes are CSS pixels (width × height). For touch sizes, emulate as mobile with touch (chrome-devtools `emulate`, e.g. `568x280x2,mobile,touch,landscape`); test desktop sizes with a fine pointer, since the board's control row only shows by default on coarse pointers.

## What decides the layout

- **Menu bar:** rail when the height is below 500 and the width is greater than the height; otherwise collapsed below 900 wide, expanded from 900.
- **Board pages (game, analysis), `BoardLayoutTier`:**
    - `Rail`: whenever the menu bar is a rail, at any width.
    - `Medium`: from 600 wide, and only where its board beats the compact one. That boundary moves with the height (see the table).
    - `Wide`: from 1150 wide, and only where its board reaches 85% of the medium one. It needs a height of about 680 or more.
    - `Compact`: everything else, including tall portrait viewports.
- The live game page alone swaps `Medium` for the rail layout (`LiveGamePage.RAIL_FALLBACK_MAX_HEIGHT`) while the viewport is landscape and shorter than 600; its medium cards and board come out too small there. Analysis stays `Medium`.
- The `Medium`/`Wide` boundaries depend on the board coordinates preference. The table assumes file letters are shown; with coordinates off they shift by roughly +2–4%.

| Height | Medium from width | Wide from width |
|---|---|---|
| 500–600 | 600 | never |
| 700 | ~675 | ~1215 |
| 800 | ~780 | ~1305 |
| 900 | ~890 | ~1395 |
| 1000 | ~995 | ~1490 |
| 1200 | ~1210 | ~1670 |

## Board pages

### Rail

| Size | Why |
|---|---|
| 568×280 | Narrowest rail at the minimum design height: the side column's height budget is exactly full, and the analysis editor squeezes the board hardest |
| 640×280 | Common phone landscape at the minimum height: spare width goes to margins around the board |
| 844×390 | Large phone landscape: a roomier rail |
| 1280×480 | Short desktop window: the widest rail, with the board limited by height |
| 800×499 vs 800×500 | The switch between rail and medium |

### Compact

| Size | Why |
|---|---|
| 360×640, 390×844 | Phone portrait |
| 500×500 | Square: not rail (the width isn't greater than the height), and too narrow for medium |
| 599×800 vs 600×600 | The 600 width threshold (at 600×600, medium wins) |
| 768×1024 | Tablet portrait stays compact: the medium boundary at that height is ~1020 |

### Medium

| Size | Why |
|---|---|
| 600×600 | Medium's minimum width |
| 899×700 vs 900×700 | Collapsed vs expanded menu bar, same tier |
| 1024×768 | Tablet landscape |
| 1280×800 | Just misses wide (needs ~1305 at this height) |
| 1000×600 vs 1000×700 | Analysis: the editor's tool card space stays reserved only while the layout's height is 560 or more (about a 640 viewport) |

### Wide

| Size | Why |
|---|---|
| 1366×768 | The smallest common laptop size that is wide |
| 1214×700 vs 1213×700 | The wide boundary at a low height (1254 with coordinates off) |
| 1920×1080 | Common desktop |

## Other pages

- **Home (`HomeLayoutTier`):** wide from 720 wide. In the games section, two columns start at a section width of 740 and three at 1100. These are component widths, so find the matching viewport widths by measuring.
- **Profile (`ProfileLayoutTier`):** medium from 720, wide from 960. The ongoing games card goes to two columns at a card width of 680. The archive goes wide at a card width of 600, and its studies go to two columns at 614.
- Also check each of these at 568×280 (rail) and 360×640 (phone portrait).
