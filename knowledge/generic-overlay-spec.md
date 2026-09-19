# Modern overlay presentation — implementation spec

Everything except the scrollview's contents: the container, the header with its close
button, the scrollview shell (including its scrollbar), and the customizable footer
button row.

Light mode. Styling is constrained to what HaxeUI's style engine supports — in
particular **no `letter-spacing` and no `text-overflow: ellipsis`** anywhere in this
spec; see §7 for how labels are kept from overflowing instead.

Because this presentation ships **upstream and is used by several sites**, the palette
below is the framework default — hue-neutral graphite — and every colour is a token a
host theme may override (§6.3). Intellector, for instance, replaces the neutrals with a
warm set derived from its board and the accent with brass; nothing here assumes it.

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
| Background     | `#fafafa`                       | same                                           |
| Border         | 1 px `#d4d4d6`                  | 1 px `#d4d4d6`, top/left/right (bottom is off-screen) |
| Elevation      | drop shadow, `0 8px 28px rgba(24,26,31,0.16)` | `0 −4px 20px rgba(24,26,31,0.18)` |
| Scrim          | **none**                        | `rgba(24,26,31,0.35)`                          |
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
- Bottom border: 1 px `#e4e4e6`.
- Background: same as container (`#fafafa`) — no separate fill.
- Layout: title left, close button right, both vertically centred.

**Title**: 17 px, weight 600, colour `#1f2126`, single line, no wrapping.

**Close button**: 26 × 26 px, corner radius 4 px, 1 px border `#d4d4d6`, transparent
background, glyph `✕` at 14 px in `#5f6168`, centred. Hover: border `#b3b3b6`, glyph
`#1f2126`. Pressed: background `#f0f0f1`. It is the only interactive element in the
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
| Thumb background      | `#cccdd1`                                               |
| Thumb hover           | `#b3b3b6`                                               |
| Thumb active/drag     | `#90929a`                                               |
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
- Top border: 1 px `#e4e4e6`.
- Background `#fafafa`, explicitly painted — it must be opaque so scrolled body content
  passes behind it, not through it.
- Buttons in a single row, vertically centred, **gap 10 px** between adjacent buttons.

### 5.1 Button model

The programmer supplies an ordered list; each entry is:

```haxe
{
  label:String, // display text
  widthPct:Float, // percent of the available row width
  emphasized:Bool, // marks the primary action; treatment per §5.4
  enabled:Bool, // optional, default true
  onClick:Void->Void
}
```

`emphasized` states *that* a button is the primary action, not *how* it looks — the
treatment is chosen once by `emphasisStyle` (§5.4). More than one emphasized button is
permitted but discouraged; two primary actions usually means the dialog is asking two
questions.

### 5.2 Width resolution

```
available = containerW − 44           // footer padding
                       − 10 × (n − 1)  // inter-button gaps
buttonW_i = widthPct_i / 100 × available
```


Percentages are expected to sum to 100. If they sum to less, the row is left-aligned
with trailing slack; if more, widths are scaled down proportionally so the row never
overflows. The reference design's footer is Cancel at 25% and Create at 75%.

### 5.3 Base button styling

Common to every variant: vertical padding 11 px (≈37 px tall), corner radius 5 px, font
size 13 px, single line, centred, no wrapping.

**Normal** — transparent background, 1 px `border`, text `inkMuted`, weight 500.
Hover: border `borderHover`, text `ink`.

**Disabled** (any variant) — background `surfaceSunken`, 1 px `divider`, text
`inkFaint`, cursor `not-allowed`, no hover response. **A disabled emphasized button
loses its emphasis treatment entirely** and renders as the disabled style above; this is
how the overlay signals "not submittable" without a modal error.

### 5.4 Emphasis treatment — `emphasisStyle`

The emphasized button has two treatments. Both are first-class; the framework user
picks one. `EmphasisStyle` (`Filled`/`Outlined`) is not declared here — it is a
general form-component model type (see `form-components.md` §6), reused by this footer
button rather than owned by it, so a form's own controls and the overlay presenting it
agree on what "active" looks like.

Settable at two levels: a theme-wide default, and a per-host override — for this footer
button, that override sits alongside the title and button spec that `Modern` already
requires (§0). Default is `Filled`, so a call site that says nothing gets the stronger
treatment.

**`Filled`** — background `accent`, 1 px `accent`, text `accentInk`, weight 600.
Hover: background `accentHover`. The strongest available emphasis; reads unambiguously
as the action to take.

**`Outlined`** — background `accentTint`, 1 px `accentMuted`, text `accent`, weight
600. Hover: border `accent`. Quieter, and it keeps the footer in the same visual
register as the rest of the dialog.

The outlined border is `accentMuted`, deliberately **weaker** than the accent itself.
The tint and the label weight already mark the state; a full-strength border makes three
signals for one condition, which reads as shouting. If an outlined button needs
strengthening, deepen `accentTint` — do not promote the border to `accent`.

#### Which to choose

`Filled` is the default and correct in most themes.

`Outlined` exists for one specific situation: **when the theme's accent shares a hue
family with the site's own content imagery.** Intellector is the motivating case — its
accent is brass and its boards are tan and orange, so a filled brass button sitting near
a board reads as a piece of board that came loose. An outlined button avoids the
collision by treatment rather than by hue. The rule:

- Accent hue-distant from content imagery → `Filled`.
- Accent inside the content's hue family → `Outlined`.

**This choice must agree with how the host draws selected states inside the body.** A
dialog with filled selection chips and an outlined primary button, or the reverse, gives
the user two competing definitions of "active". The framework cannot enforce this —
the body is the framework user's `OverlayContent` — so it stands as a contract:
whichever `emphasisStyle` an overlay uses, its content should use the matching
selection treatment.

## 6. Colour tokens (light)

| Token             | Value     | Used for                                        |
| ----------------- | --------- | ----------------------------------------------- |
| `surface`         | `#fafafa` | container, header, footer fill                   |
| `surfaceSunken`   | `#f0f0f1` | disabled fills, inset boxes in the body          |
| `surfaceDeep`     | `#ffffff` | input fills in the body                          |
| `border`          | `#d4d4d6` | container and control borders                    |
| `borderHover`     | `#b3b3b6` | hover borders                                    |
| `divider`         | `#e4e4e6` | header/footer hairlines, disabled borders        |
| `ink`             | `#1f2126` | primary text                                     |
| `inkMuted`        | `#5f6168` | secondary text, labels, normal button text       |
| `inkFaint`        | `#9a9ca2` | disabled text                                    |
| `accent`          | `#2f3540` | emphasis fill (`Filled`), emphasis label (`Outlined`) |
| `accentHover`     | `#232832` | emphasis hover (`Filled`)                        |
| `accentMuted`     | `#8d939e` | emphasis border (`Outlined`)                     |
| `accentTint`      | `#e7e9ee` | emphasis fill (`Outlined`)                       |
| `accentInk`       | `#ffffff` | text on a solid accent fill                      |
| `danger`          | `#b3261e` | validation text                                  |
| `dangerBorder`    | `#c4392f` | invalid field borders                            |
| `scrollThumb`     | `#cccdd1` | scrollbar thumb                                  |
| `scrollThumbHover`| `#b3b3b6` | scrollbar thumb hover                            |
| `scrollThumbDrag` | `#90929a` | scrollbar thumb while dragging                   |
| `scrim`           | `rgba(24,26,31,0.35)` | mobile sheet scrim only                |

Measured contrast: `ink` on `surface` ~15:1 · `inkMuted` on `surface` ~6.2:1 ·
`inkMuted` on `surfaceSunken` ~5.9:1 · `accentInk` on `accent` ~11.6:1 · `accent` on
`accentTint` ~9.9:1 · `danger` on `surface` ~6.4:1. All above 4.5:1, which leaves a
host theme room to shift hue without falling below the floor.

### 6.1 Why graphite is the default accent

A framework default accent must satisfy a condition no site-specific accent does: it
has to be **wrong for nobody**. Graphite is the only thing that qualifies.

- It carries no semantics. Green means success or victory somewhere, red means error or
  loss, blue means links or trust, and any of those may already be spoken for by a host
  product. Graphite claims nothing.
- It cannot collide with a host's content imagery by hue, because it has effectively no
  hue — so `Filled` works out of the box, and a host needs `Outlined` only if its own
  override creates the collision described in §5.4.
- Its darkness carries `accentInk` at ~11.6:1, so an overriding theme can move to almost
  any hue and still clear 4.5:1 without redesigning the button.
- Emphasis by *value* rather than by *hue* reads as restraint rather than as branding,
  which is the right posture for a presentation the host is expected to re-skin.

Stated plainly, the trade-off: graphite is not memorable, and a dark grey primary button
looks slightly severe beside colourful content. That is the intended default — the
framework should be unopinionated and let the host add the opinion.

### 6.2 The neutrals are neutral for the same reason

The greys above are hue-neutral rather than warm or cool. A framework default cannot
inherit one product's palette, and a hueless accent on tinted surfaces reads muddy — the
two decisions go together. A host theme that tints its surfaces should tint its accent
to match, and vice versa.

### 6.3 Overriding for a host theme

A host may override any token. Three rules constrain that:

1. **Keep the contrast floor.** Every pair listed above must stay above 4.5:1. The
   framework's ratios are generous precisely so a hue shift does not break them.
2. **Keep the elevation direction.** `surfaceDeep` ≥ `surface` > `surfaceSunken`, and
   the host's page background below `surface` — with no scrim on desktop (§2.1),
   lightness is the only cue that the dialog floats. A page lighter than `surface` makes
   it read as inset.
3. **Re-evaluate `emphasisStyle` after changing `accent`.** A hue change can create the
   content collision of §5.4 where the default had none. This is the one override with a
   structural knock-on.

Geometry — heights, paddings, radii, the scrollbar lane — is **not** themeable. The
invariants in §8 depend on it.

## 7. Typography and label fitting

Onest (400/500/600) for all UI text; IBM Plex Mono (400/500/600) for numeric
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
    "Mobile" here means the framework's single existing breakpoint —
    `ResponsivityController.isCollapsed` (driven by `HaxeFolioConfig.menuCollapseWidth`,
    the same flag `HaxeFolioApp.showOverlay` already uses to pick this presentation's
    Modal vs. SideBar chrome) — not a new, component-local pixel threshold. Reintroducing
    a bespoke breakpoint per component is exactly the `ResponsiveToolbox`/
    `ResponsivenessRule` pattern CLAUDE.md rejects.

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
8. **Colour is themeable; geometry is not.** Hosts override tokens, never heights,
   paddings or radii.
