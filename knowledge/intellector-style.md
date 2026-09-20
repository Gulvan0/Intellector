# Intellector design theme

The component-independent layer: colour, type, shape, spacing, states, and the rules
that govern how they combine. Individual component specs (the challenge params overlay,
and others to come) reference this file rather than restating it.

Two constraints shape everything below and are not negotiable:

- **HaxeUI's style engine has no `letter-spacing` and no `text-overflow: ellipsis`.**
  Type cannot be tracked out, and overflowing text is clipped rather than ellipsised, so
  every label must fit by construction. See §3.4.
- **Light mode only**, warm-neutral, derived from the game board.

---

## 1. Where the theme comes from

The board is the origin of the palette, not an element styled to match it. Its five
values are fixed by the game:

| Role | Value |
| --- | --- |
| Light hex fill | `#ffcf9f` |
| Dark hex fill | `#d18b47` |
| Hex seams / border | `#664126` |
| White pieces | `#ffffff`|
| Black pieces | `#000000` |

Every neutral in the theme takes the seam brown's hue (~30°) at **3–8% saturation**. The
surfaces are therefore warm without approaching the board's chroma, which is what keeps
the board the only saturated thing on screen and makes it read as the subject rather
than as decoration. `ink` is that same brown pushed dark, not a neutral black, so text
and board belong to one family.

**The board's five values are not theme tokens.** Never reuse them for UI chrome — a
control in `#d18b47` reads as a piece of board that came loose.

---

## 2. Colour

### 2.1 Elevation ladder

Lightness encodes elevation: higher surfaces are lighter. This is load-bearing because
the desktop overlay is non-blocking and has no scrim behind it — lightness is the only
cue that it floats.

| Layer | Token | Value |
| --- | --- | --- |
| Page background | `pageBg` | `#e9e3d9` |
| Menu bar, top chrome | `barBg` | `#f2eee6` |
| Overlay, dialog, card | `surface` | `#faf7f2` |
| Inset box, unselected chip | `surfaceSunken` | `#f0ebe2` |
| Text input | `surfaceDeep` | `#fffefb` |

`surfaceSunken` and `surfaceDeep` are *within* a surface, not steps in the ladder: a
sunken box on a `surface` card reads as recessed, and an input reads as the deepest
thing you can type into. Never place `surface` directly on `surface` — nest via
`surfaceSunken`.

### 2.2 Lines and text

| Token | Value | Used for |
| --- | --- | --- |
| `border` | `#d8cfc0` | control borders, card borders |
| `borderHover` | `#bdb2a0` | hover borders |
| `divider` | `#e6dfd3` | hairlines between regions, disabled borders |
| `barBorder` | `#ded5c6` | menu bar's bottom edge |
| `ink` | `#2a211a` | primary text |
| `inkMuted` | `#6d6152` | labels, secondary text, unselected control text |
| `inkFaint` | `#a79b8a` | disabled text, unselected icon rings |

### 2.3 Accent — brass

| Token | Value | Used for |
| --- | --- | --- |
| `accent` | `#8a5a1f` | primary button fill, selected label |
| `accentHover` | `#70491a` | primary button hover |
| `accentMuted` | `#c79a56` | selected border, selected icon ring |
| `accentTint` | `#f6e6c6` | selected fill |
| `accentInk` | `#fffefb` | text on a solid accent fill |

Brass is the colour of mechanical tournament clocks, medals, and the fittings on a
wooden board — it refers to the objects the game is played with. It is the only token
chosen by reference rather than derived, and it was chosen after eliminating:

- **Every bright warm hue.** White text at 4.5:1 pins accent lightness at roughly L\* 45
  or below; amber, gold and mid-orange cannot carry white text at all. "Warm accent" can
  only mean *dark* warm.
- **Green and red**, reserved for win, loss and error elsewhere in the product,
  regardless of how well forest-green or oxblood pair with wood.
- **Indigo blue**, the safe and proven pairing with warm wood, rejected as corporate —
  it is the colour of administrative software and made dialogs read as settings panels.
- **Violet**, which passed every functional test but referred to nothing in the domain.
  It was the last hue standing after elimination; negative reasoning, and it showed.

Brass's darkness is load-bearing: at this lightness it clears 7:1 against `accentInk`
and still reads as "active" on a warm field without shouting.

### 2.4 Status

| Token | Value | Used for |
| --- | --- | --- |
| `danger` | `#9e2f1c` | validation text |
| `dangerBorder` | `#b8462c` | invalid field borders |

`danger` is a dark brick, not a signal red: a saturated red beside the board's orange
reads as a second board colour. Pushed dark and slightly brown, it separates from both
the board and the accent.

Green and red carry game meanings (win, loss) product-wide, so **no control may use
green or red to mean anything else**. A confirm button is brass, not green.

### 2.5 Scrollbar and scrim

| Token | Value |
| --- | --- |
| `scrollThumb` | `#d0c6b5` |
| `scrollThumbHover` | `#bdb2a0` |
| `scrollThumbDrag` | `#9e9282` |
| `scrim` | `rgba(42,33,26,0.35)` |

Scrim is used only where a surface is genuinely modal — on current evidence, mobile
sheets only.

### 2.6 Measured contrast

`ink` on `surface` ~13:1 · `ink` on `barBg` ~12.5:1 · `inkMuted` on `surface` ~5.4:1 ·
`inkMuted` on `barBg` ~5.1:1 · `inkMuted` on `surfaceSunken` ~12:1 · `accentInk` on
`accent` ~7.2:1 · `accent` on `accentTint` ~6.1:1 · `accent` on `barBg` ~5.2:1 ·
`danger` on `surface` ~7.6:1. All above 4.5:1.

---

## 3. Typography

### 3.1 Faces

**Onest** (400/500/600) for all UI text - HaxeFolio's own default face, no Intellector
override. **IBM Plex Mono** (400/500/600) for
**numeric values only** — clock readouts, time-control labels like `3+2`, SIP and other
notation strings, ratings. No other faces.

The mono/proportional split is semantic, not decorative: mono means "this is a value you
read digit by digit". Using it for anything else dilutes that.

### 3.2 Scale

| Role | Size | Weight | Colour |
| --- | --- | --- | --- |
| Dialog / section title | 17 px | 600 | `ink` |
| Body text, control labels | 13 px | 500 | `ink` or `inkMuted` |
| Field label | 12 px | 500 | `inkMuted` |
| Numeric value (mono) | 14 px | 500 | `ink` |
| Hint, status, validation | 11 px | 400 | `inkMuted` / `danger` |

### 3.3 Field labels are sentence case, not mono caps

Field labels are sentence-case Onest at 12 px — **not** 10 px mono uppercase. Three
reasons, in order of weight:

1. Small mono caps are the visual signature of administrative software. On a game site
   they make every form read as a settings console.
2. Without `letter-spacing`, tracked-out caps are impossible, and untracked small caps
   look cramped.
3. Cyrillic caps run wide, so uppercase labels are the first thing to overflow in
   Russian.

### 3.4 No truncation — labels fit by construction

Since text cannot be ellipsised, overflowing text is clipped by the container, which
looks broken. Therefore:

- Any control whose width is known must have a **character budget** stated in its
  component spec, and translators must be given those budgets. As a reference point,
  Onest at 13 px averages ~6.2 px per Latin character and ~7.1 px per Cyrillic one.
- Where a translation will not fit, **shorten the term rather than abbreviating with a
  trailing dot.** A full short word always reads better than a contraction — Russian
  «Любые» over «Случ.».
- Any row of three or more equal-width controls with locale-dependent labels **stacks
  vertically on mobile** rather than shrinking, so each label gets the full sheet width.

---

## 4. Shape and spacing

### 4.1 Corner radii

| Element | Radius |
| --- | --- |
| Dialog, card, panel | 9 px (12 px on a sheet's top corners) |
| Button, chip, segmented item | 5 px |
| Input, stepper, small icon button | 4 px |
| Scrollbar thumb | 4 px |
| Circular icon slot | 50% |

The scale is deliberately tight — one step less rounded than a default framework look —
so the UI reads as precise rather than soft. Radii do not scale with size; a large panel
and a small panel share 9 px.

### 4.2 Spacing

An 11-value scale in pixels: **2, 4, 5, 6, 8, 10, 12, 14, 18, 22, 26**. In practice:

| Purpose | Value |
| --- | --- |
| Between items in a group (chips, steppers) | 5–6 px |
| Between adjacent buttons in a row | 10 px |
| Between a label and its control | 5–6 px |
| Between paired controls on one row | 14 px, 20 px when they need separating |
| Between sections | 18 px |
| Region padding (dialog body, bar) | 22 px sides, 18 px top |
| Region height (header, footer) | fixed, stated per component |

---

## 5. Controls

### 5.1 Selection is outlined, not filled

Because brass shares the board's hue family, a filled brass chip sitting near a board
reads as board material. Selected states are therefore **outlined**:

| | Selected | Unselected | Disabled |
| --- | --- | --- | --- |
| Fill | `accentTint` | `surfaceSunken` | `surfaceSunken` |
| Border | 1 px `accentMuted` | 1 px `border` | 1 px `divider` |
| Label | `accent`, 600 | `inkMuted`, 500 | `inkFaint`, 500 |
| Icon ring | `accentMuted` | `inkFaint` | `divider` |

The border is deliberately weaker than the accent. The tint and the label weight already
mark the state; a full-strength border makes three signals for one condition, which reads
as shouting. **If a selection needs strengthening, deepen the tint — do not restore the
border.**

**One exception:** a screen's single primary action keeps a solid `accent` fill with
`accentInk` text. There is only ever one of it, it sits away from any board, and a
primary action needs the weight. A filled brass chip is ambiguous; a filled brass button
reads as a medal.

This coupling is a single decision: if the accent ever moves to a cool hue, filled
selections become available again, and the two must change together.

### 5.2 Buttons

Vertical padding 11 px (≈37 px tall), radius 5 px, 13 px text, single line, centred.

*Normal* — transparent fill, 1 px `border`, `inkMuted` at 500. Hover: border
`borderHover`, text `ink`.
*Primary* — `accent` fill, 1 px `accent`, `accentInk` at 600. Hover: `accentHover`.
*Disabled* — `surfaceSunken` fill, 1 px `divider`, `inkFaint`, cursor `not-allowed`, no
hover response. A disabled primary drops its accent fill entirely.

### 5.3 Inputs

`surfaceDeep` fill, 1 px `border`, radius 4 px, `ink` text. Focus: border `accentMuted`.
Invalid: border `dangerBorder`. Disabled: `surfaceSunken` fill, `inkFaint` text.

### 5.4 Touch targets

Minimum 44 px on mobile. Desktop controls may be 37 px tall, but anything that also
appears on a sheet must reach 44 px there.

---

## 6. Validation

Three rules, derived from a previous iteration in which validation was silent and users
could not tell why they were stuck:

1. **Every validated field reserves a fixed-height line** (16 px) for its message,
   present whether or not there is anything to say. The line holds the constraint in
   `inkMuted` when the value is fine ("max 6:00:00") and the error in `danger` when it
   is not ("must be above 0"). Nothing moves between those states.
2. **Constraints live with the control they constrain**, on that control's own label row
   — never as one combined line for a group, which forces the user to work out which
   limit belongs to which field.
3. **The primary action is disabled while anything is invalid**, and drops its accent
   fill (§5.2) so the blocked state is visible without an error summary.

Field-level errors appear on blur or change, not on first render — a form must not open
covered in red.

---

## 7. Layout stability

The overriding structural rule, again from a previous iteration that jumped on every
toggle:

- **Any region whose contents vary must have a fixed height** sized to its tallest
  variant. Switching between variants must not move anything below.
- **Conditional parameters are disabled in place, not hidden.** A parameter that stops
  applying keeps its row, greyed, with the reason stated inline. Hiding it both moves
  the layout and hides the fact that the setting exists.
- **A dialog's frame never depends on its content.** Content scrolls inside a fixed
  frame.
- **A scrollbar gutter is reserved at all times**, whether or not the content scrolls.
  An appearing scrollbar changes the usable width and silently re-wraps
  percentage-sized rows.
- **Size children in percentages, not pixels**, wherever a container's width can change.

---

## 8. Motion

Sparing. Two transitions only:

- **Sheet entry/exit** — slide from `y = 100%`, 220 ms, ease-out.
- **Hover and selection state changes** — 120 ms colour fade, or none at all if the
  platform makes it awkward.

No motion on layout: nothing grows, collapses, or reflows as a transition, because
nothing in this theme is permitted to change size in the first place (§7).

# Colour tokens (light) for invididual components

## Overlays

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
