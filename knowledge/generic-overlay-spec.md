# Modern overlay presentation — implementation spec

Everything except the scrollview's contents: the container, the header with its close
button, the scrollview shell (including its scrollbar), and the customizable footer
button row.

Light mode. Styling is constrained to what HaxeUI's style engine supports — in
particular **no `letter-spacing` and no `text-overflow: ellipsis`** anywhere in this
spec; see §7 for how labels are kept from overflowing instead.

## 0. Coexistence with the existing (bare) presentation

This is a second **presentation** an overlay can be shown with, not a replacement for
the existing one and not a different content model. `showOverlay` (or whatever wraps
`ModalOverlay`/`SideBarOverlay`) gains a presentation switch — e.g.
`presentation: Bare | Modern`, defaulting to `Bare` so every existing call is
unaffected:

- **`Bare`** — today's behavior, unchanged. The framework user's `OverlayContent` *is*
  the whole visible box: `.haxefolio-overlay-modal`'s default background/padding/shadow
  paints around it directly, and the framework's own floating `OverlayCloseButton`
  (the plain SVG-icon one, positioned via `OverlayLayout`) sits on top of it.
- **`Modern`** — this spec. The framework user writes the exact same kind of
  `OverlayContent` as for `Bare` — no new shape, no new base class — but it is now
  placed as the **scrollview body's contents** (§4) inside the header/body/footer
  chrome described below, sized to the computed body area instead of the full box.
  Choosing `Modern` additionally requires the two inputs `Bare` never needed: the
  header **title** (§3) and the footer's **button spec** (§5.1).

Under `Modern`, `Bare`'s chrome and close button are not layered underneath this
spec's — they are not applied at all. The two never coexist on the same overlay; the
presentation argument is the only thing that changes at the call site, and the content
factory a framework user already wrote for an existing `Bare` overlay can be pointed at
`Modern` unmodified, provided with a title and footer buttons.

## 1. Structure

Three stacked regions, no gaps, inside one clipping container:

```
container (fixed size, overflow: hidden)
├── header   — fixed height, never scrolls
├── body     — the only scrollable region
└── footer   — fixed height, never scrolls
```

The body's height is **computed, not flexible**: `bodyH = containerH − headerH − footerH`.
This is deliberate for HaxeUI — no flex needed; the body is an absolutely-sized
scrollview. The container itself has `overflow: hidden` so the rounded corners clip
children.

## 2. Container geometry

|                | Desktop (non-blocking dialog)   | Mobile (bottom sheet)                          |
| -------------- | ------------------------------- | ---------------------------------------------- |
| Width          | 620 px, fixed                   | 100% of viewport                               |
| Height         | 720 px, fixed                   | 100% of viewport minus a top inset             |
| Top inset      | — (vertically centred, see §2.1) | ~124 px of scrim visible above                 |
| Corner radius  | 9 px all corners                | 12 px top-left + top-right, 0 bottom           |
| Background     | `#fbf9f5`                       | same                                           |
| Border         | 1 px `#d6cfc2`                  | 1 px `#d6cfc2`, top/left/right (bottom is off-screen) |
| Elevation      | drop shadow, `0 8px 28px rgba(36,31,26,0.16)` | `0 −4px 20px rgba(36,31,26,0.18)` |
| Scrim          | **none**                        | `rgba(36,31,26,0.35)`                          |
| Entry          | fade, no movement               | slide up from `y = 100%` to rest               |

### 2.1 Desktop: non-blocking

The desktop dialog is **not modal**. Consequences, all of which differ from a modal
overlay:

- **No scrim.** The page behind stays fully visible and fully interactive; the dialog is
  separated from it by its drop shadow and border alone.
- **No focus trap.** Tab order runs through the dialog and then continues into the page
  normally. Do not install a focus-cycling handler.
- **Page scrolling stays unlocked.** The user may scroll the page behind the dialog while
  it is open. The dialog stays anchored to the viewport, not the document.
- **No click-outside dismissal.** Clicking the page behind interacts with the page; it
  must not close the dialog, since a non-blocking window is expected to survive
  incidental clicks. Dismissal is the close button or the footer's cancel action.

Desktop centring on open: horizontally and vertically centred. If the viewport is
shorter than 720 px + 40 px margin, the container shrinks in height only (the body
absorbs it) and never below ~420 px. This re-measures live: if the browser window is
resized while the dialog is open, its height keeps tracking the viewport rather than
staying pinned to whatever was measured at open time.

> **Implementation note.** Live re-measurement means resizing the outer sized box
> `ModalOverlay` creates, not just this content's own contents — and `ModalOverlay.show()`
> currently has no way to do that after the initial call. This overlay is built as
> plain `OverlayContent`, going through `HaxeFolioApp.showOverlay()` like any other
> overlay, so it coexists with existing overlays (login, preferences) rather than
> replacing them. The one shared-library change it needs is additive: extend
> `ModalOverlay.show()`'s return value with a resize handle alongside the existing
> `dismiss` closure (mirroring the re-measurement `SideBarOverlay` already does
> internally for the mobile sheet), so this content can request a re-measure.
> Existing callers that ignore the new handle are unaffected.

### 2.2 Mobile: blocking

The mobile sheet **is** modal: it has a scrim, page scrolling is locked while it is
open, and tapping the scrim dismisses it. Pinned to the bottom edge, full width, no
side margins.

## 3. Header

- Height **60 px**, fixed. Never scrolls, never changes height.
- Horizontal padding **22 px** both sides.
- Bottom border: 1 px `#e4ded2`.
- Background: same as container (`#fbf9f5`) — no separate fill.
- Layout: title left, close button right, both vertically centred.

**Title**: 17 px, weight 600, colour `#241f1a`, single line, no wrapping.

**Close button**: 26 × 26 px, corner radius 4 px, 1 px border `#d6cfc2`, transparent
background, glyph `✕` at 14 px in `#6b6357`, centred. Hover: border `#b9b0a0`, glyph
`#241f1a`. Pressed: background `#f1ede5`. It is the only interactive element in the
header.

## 4. Body — the scrollview shell

- Padding **18 px top, 22 px sides, 22 px bottom**.
- Vertical scrolling only; horizontal scrolling disabled.
- Fixed height as computed above, so the scrollbar appears inside the overlay, never on
  the page.
- The overlay makes no assumptions about its contents. Whatever is placed here must be
  built to a width of `containerW − 44 px`, minus the reserved scrollbar gutter.
  **Content should size children in percentages, not pixels** — a 5-across row of preset
  buttons must be `20% − gap`, not `106 px`, so that it survives any change in the body's
  usable width.

### 4.1 Scrollbar styling

The scrollbar is part of the overlay chrome, not a platform default. It is a thin,
permanently-gutter'd track so that content never reflows when it appears.

| Property              | Value                                                  |
| --------------------- | ------------------------------------------------------ |
| Lane width            | 10 px, always reserved                                  |
| Track background      | transparent — the container fill shows through          |
| Thumb background      | `#cdc5b6`                                               |
| Thumb hover           | `#b9b0a0`                                               |
| Thumb active/drag     | `#9a9082`                                               |
| Thumb corner radius   | 4 px                                                    |
| Thumb inset           | 2 px each side, giving a 6 px visible thumb in the 10 px lane |
| Thumb minimum length  | 32 px                                                   |
| Arrows / step buttons | none                                                    |
| Overscroll            | contained — the page behind must not scroll when the body hits its end |

The gutter is reserved **at all times**, including when the content is short enough not
to scroll. This is the single most important detail: an appearing-and-disappearing
scrollbar changes the body's usable width, which silently re-wraps percentage rows and
reintroduces exactly the layout instability the overlay is designed to avoid.

The 10 px lane sits inside the body's 22 px right padding, so the visible thumb ends up
about 8 px from the container's inner edge and content keeps a full 22 px of breathing
room on the left. Do not compensate by shrinking the right padding.

No scroll shadows or fades at the top and bottom edges — the 1 px borders on the header
and footer are the only separators. On touch platforms, momentum scrolling is native and
the thumb may auto-hide; the gutter stays reserved regardless.

## 5. Footer — the customizable button row

- Height **68 px**, fixed.
- Horizontal padding **22 px** both sides.
- Top border: 1 px `#e4ded2`.
- Background `#fbf9f5`, explicitly painted — it must be opaque so scrolled body content
  passes behind it, not through it.
- Buttons in a single row, vertically centred, **gap 10 px** between adjacent buttons.

### 5.1 Button model

The programmer supplies an ordered list; each entry is:

```haxe
{
  label:      String,        // display text
  widthPct:   Float,         // percent of the available row width
  emphasized: Bool,          // theme-coloured fill + bold text
  enabled:    Bool,          // optional, default true
  onClick:    Void -> Void
}
```

### 5.2 Width resolution

```
available = containerW − 44           // footer padding
                       − 10 × (n − 1)  // inter-button gaps
buttonW_i = widthPct_i / 100 × available
```

Percentages are expected to sum to 100. If they sum to less, the row is left-aligned
with trailing slack; if more, widths are scaled down proportionally so the row never
overflows. The reference design's footer is Cancel at 25% and Create at 75%.

### 5.3 Button styling

Identical geometry for both variants: vertical padding 11 px (≈37 px tall), corner
radius 5 px, font size 13 px, single line, centred, no wrapping.

**Normal** — transparent background, 1 px border `#d6cfc2`, text `#6b6357`, weight 500.
Hover: border `#b9b0a0`, text `#241f1a`.

**Emphasized** — background = theme accent (`#2f6bbf` in the reference design), border
1 px the same accent, text `#ffffff`, weight **600**. Hover: accent darkened ~8%
(`#2a5fa9`).

**Disabled** (either variant) — background `#f1ede5`, border 1 px `#e4ded2`, text
`#a39a8c`, cursor `not-allowed`, no hover response. A disabled emphasized button drops
its accent fill entirely; this is how the overlay signals "not submittable" without a
modal error.

## 6. Colour tokens (light)

| Token             | Value     | Used for                                        |
| ----------------- | --------- | ----------------------------------------------- |
| `surface`         | `#fbf9f5` | container, header, footer fill                   |
| `surfaceSunken`   | `#f1ede5` | disabled fills, inset boxes in the body          |
| `surfaceDeep`     | `#ffffff` | input fills in the body                          |
| `border`          | `#d6cfc2` | container and control borders                    |
| `borderHover`     | `#b9b0a0` | hover borders                                    |
| `divider`         | `#e4ded2` | header/footer hairlines, disabled borders        |
| `ink`             | `#241f1a` | primary text                                     |
| `inkMuted`        | `#6b6357` | secondary text, labels, normal button text       |
| `inkFaint`        | `#a39a8c` | disabled text                                    |
| `accent`          | `#2f6bbf` | emphasized button, active selections             |
| `accentHover`     | `#2a5fa9` | emphasized button hover                          |
| `accentInk`       | `#ffffff` | text on accent                                   |
| `danger`          | `#b23a22` | validation text                                  |
| `dangerBorder`    | `#c4634f` | invalid field borders                            |
| `scrollThumb`     | `#cdc5b6` | scrollbar thumb                                  |
| `scrollThumbHover`| `#b9b0a0` | scrollbar thumb hover                            |
| `scrollThumbDrag` | `#9a9082` | scrollbar thumb while dragging                   |
| `scrim`           | `rgba(36,31,26,0.35)` | mobile sheet scrim only                |

Contrast: `ink` on `surface` is ~14:1, `inkMuted` on `surface` ~5.4:1, `accentInk` on
`accent` ~5.1:1 — all comfortably above 4.5:1 for body text.

## 7. Typography and label fitting

Archivo (400/500/600/700) for all UI text; IBM Plex Mono (400/500/600) for numeric
values and the small uppercase field labels (10 px). No other faces.

Two HaxeUI constraints shape this:

- **No `letter-spacing`.** The small uppercase mono labels were originally tracked out
  at 0.1em. Without it they read tighter, so compensate by using the mono face at 10 px
  with `uppercase` text and, where a label sits directly above a control, one extra
  pixel of bottom margin (6 px instead of 5 px) so the tighter label doesn't crowd the
  field. Never substitute manual space-between-letters strings.
- **No `text-overflow: ellipsis`.** Labels cannot be truncated gracefully, so they must
  be short enough to fit by construction. Overflowing text is clipped by the container's
  `overflow: hidden`, which looks broken. Therefore:
  - Footer button labels are budgeted against their resolved pixel width (§5.2) — at
    620 px wide, a 25% button holds roughly 9 Latin characters at 13 px, a 75% button
    roughly 38. Translators must be given these budgets.
  - The header title is budgeted against `containerW − 44 − 26 − 12` (padding, close
    button, gap) — roughly 68 Latin characters at 17 px on desktop, 38 on a 390 px
    mobile sheet.
  - Where a translation cannot fit, shorten the term rather than abbreviating with a
    trailing dot — a full short word (Russian «Любые») always reads better than a
    contraction («Случ.»).
  - Any row of ≥3 equal-width buttons whose labels are locale-dependent should stack
    vertically on mobile rather than shrink, so each label gets full sheet width.

## 8. Invariants

1. **Header and footer heights are constants.** Nothing the body does may change them.
2. **The container size never depends on content.** Content scrolls; the frame doesn't
   grow.
3. **The scrollbar gutter is always reserved.** The body's usable width is a constant.
4. **The footer is always visible**, regardless of scroll position.
5. **Only the body scrolls within the overlay**, and its overscroll does not chain to
   whatever is behind it.
6. **Desktop is non-blocking**: no scrim, no focus trap, no page scroll lock, no
   click-outside dismissal. **Mobile is blocking**: scrim, page scroll lock, scrim-tap
   dismissal.
7. **No label is ever truncated** — it is budgeted to fit, because the platform cannot
   ellipsise it.
