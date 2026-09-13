## 6. Colour tokens (light)

| Token             | Value                 | Used for                                    |
| ----------------- | --------------------- | ------------------------------------------- |
| `surface`         | `#faf7f2`             | container, header, footer fill               |
| `surfaceSunken`   | `#f0ebe2`             | unselected chips, inset boxes, disabled fills |
| `surfaceDeep`     | `#fffefb`             | input fills                                  |
| `border`          | `#d8cfc0`             | container and control borders                |
| `borderHover`     | `#bdb2a0`             | hover borders                                |
| `divider`         | `#e6dfd3`             | header/footer hairlines, disabled borders    |
| `ink`             | `#2a211a`             | primary text                                 |
| `inkMuted`        | `#6d6152`             | labels, secondary text, unselected chip text |
| `inkFaint`        | `#a79b8a`             | disabled text, unselected icon rings         |
| `accent`          | `#8a5a1f`             | primary button fill, selected chip label     |
| `accentMuted`     | `#c79a56`             | selected chip border, selected icon ring     |
| `accentTint`      | `#f6e6c6`             | selected chip fill                           |
| `accentHover`     | `#70491a`             | primary button hover                         |
| `accentInk`       | `#fffefb`             | text on a solid accent fill                  |
| `danger`          | `#9e2f1c`             | validation text                              |
| `dangerBorder`    | `#b8462c`             | invalid field borders                        |
| `scrollThumb`     | `#d0c6b5`             | scrollbar thumb                              |
| `scrollThumbHover`| `#bdb2a0`             | scrollbar thumb hover                        |
| `scrollThumbDrag` | `#9e9282`             | scrollbar thumb while dragging               |
| `scrim`           | `rgba(42,33,26,0.35)` | mobile sheet scrim only                      |

Measured contrast: `ink` on `surface` ~13:1 · `inkMuted` on `surface` ~5.4:1 ·
`inkMuted` on `surfaceSunken` ~12:1 · `accentInk` on `accent` ~7.2:1 · `accent` on
`accentTint` ~6.1:1 · `danger` on `surface` ~7.6:1. All above 4.5:1.

### 6.1 Where the palette comes from

Every neutral is derived from the board. The board's own values are `#ffcf9f` and
`#d18b47` for the hex fills over `#664126` seams; the neutrals take that brown's hue
(~30°) at 3–8% saturation. The surfaces therefore read as warm without approaching the
board's chroma, so **the board stays the only saturated thing in the overlay** — which
is what makes it read as the subject rather than as decoration. `ink` is the seam brown
pushed dark rather than a neutral black, so text and board belong to one family.

The board's five values (`#ffcf9f`, `#d18b47`, `#664126`, and `#fffdf8` / `#3f2717` for
the pieces) are **not** overlay tokens and must never be reused for UI chrome.

### 6.2 Why the accent is brass

Brass is the colour of mechanical tournament clocks, medals, and the fittings on a
wooden board — it refers to the objects the game is played with. It is the only token
chosen by reference rather than derived, and it was chosen last, after several
alternatives were eliminated:

- **White text at 4.5:1 pins lightness low** (≈L\* 45 or below). Every bright warm hue —
  amber, gold, mid-orange — cannot carry white text at all. In practice "warm accent"
  can only mean *dark* warm.
- **Green and red are reserved** for win, loss and error elsewhere in the product. That
  removes forest-green and oxblood regardless of how well either pairs with wood.
- **Indigo blue was tried and rejected as corporate.** It is the safe, proven pairing
  with warm wood, but it is also the colour of administrative software; on a game site
  it made the dialog read as a settings panel.
- **Violet was tried and rejected as meaningless.** It passed every functional test but
  referred to nothing in the domain — the last hue standing after elimination, which is
  negative reasoning and looked it.

Brass's low lightness is load-bearing: at this darkness it clears 7:1 against white
text and still reads as "active" on a warm field without shouting.

`danger` is a dark brick red, not a signal red — a saturated red beside the board's
orange reads as a second board colour. Pushed dark and slightly brown, it separates
cleanly from both the board and the accent.

## 7. Typography

Archivo (400/500/600/700) for all UI text; IBM Plex Mono (400/500/600) for **numeric
values only** — clock readouts, preset labels like `3+2`, SIP strings. No other faces.

Field labels are sentence-case Archivo at 12 px weight 500 in `inkMuted`, **not** mono
uppercase. This is deliberate: 10 px mono caps are the visual signature of
administrative software, and on a game site they made the dialog read as a settings
console. Sentence case at a readable size is both friendlier and easier to localise,
since Cyrillic caps run wide.
