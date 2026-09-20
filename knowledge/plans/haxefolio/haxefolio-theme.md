# HaxeFolio default theme

The framework's shipped appearance: hue-neutral graphite, Onest with IBM Plex Mono for
values, and the geometry table every height calculation reads from. This ships upstream
and is used by several sites, so nothing here assumes any one product. `design-theme.md`
is Intellector's override of this file, not a peer of it.

Light mode only for now. Styling is constrained to what HaxeUI's style engine supports —
in particular **no `letter-spacing` and no `text-overflow: ellipsis`** anywhere; see
`haxefolio-typography.md` §4 for what replaces truncation.

## 1. What lives where

Two override mechanisms, per the generalization plan §6.0:

| Concern | Mechanism | Scope |
| --- | --- | --- |
| Colour, typography | **Stylesheet** | Cascade: theme sheet, or a per-overlay style class |
| Geometry (§3) | **Code** — `GeometryTokens` | Theme-wide default, or `AppearanceOverrides` per overlay |
| `EmphasisStyle` (§5) | **Code** — semantic, not a colour | Same two scopes |

Colour and type are not duplicated into code. Geometry is not settable from CSS, because
the framework computes with it before layout resolves.

## 2. Colour tokens

| Token | Value | Used for |
| --- | --- | --- |
| `surface` | `#fafafa` | frame fill: header, scroll region, actions |
| `surfaceSunken` | `#f0f0f1` | disabled fills, inset boxes, field-group backgrounds |
| `surfaceDeep` | `#ffffff` | input fills |
| `border` | `#d4d4d6` | frame and control borders |
| `borderHover` | `#b3b3b6` | hover borders |
| `divider` | `#e4e4e6` | region hairlines, disabled borders |
| `ink` | `#1f2126` | primary text |
| `inkMuted` | `#5f6168` | labels, secondary text, normal button text |
| `inkFaint` | `#9a9ca2` | disabled text |
| `accent` | `#2f3540` | emphasis fill (`Filled`), emphasis label (`Outlined`) |
| `accentHover` | `#232832` | emphasis hover (`Filled`) |
| `accentMuted` | `#8d939e` | emphasis border (`Outlined`) |
| `accentTint` | `#e7e9ee` | emphasis fill (`Outlined`), selected chip fill |
| `accentInk` | `#ffffff` | text on a solid accent fill |
| `danger` | `#b3261e` | validation text |
| `dangerBorder` | `#c4392f` | invalid field borders, tab error markers |
| `scrollThumb` | `#cccdd1` | scrollbar thumb |
| `scrollThumbHover` | `#b3b3b6` | thumb hover |
| `scrollThumbDrag` | `#90929a` | thumb while dragging |
| `scrim` | `rgba(24,26,31,0.35)` | behind the frame, both width classes |

Measured contrast: `ink` on `surface` ~15:1 · `inkMuted` on `surface` ~6.2:1 · `inkMuted`
on `surfaceSunken` ~5.9:1 · `accentInk` on `accent` ~11.6:1 · `accent` on `accentTint`
~9.9:1 · `danger` on `surface` ~6.4:1. The margins are deliberately generous so a host
can shift hue without dropping below the 4.5:1 advisory floor.

### 2.1 Why graphite

A framework default accent has to satisfy a condition no product accent does: it must be
**wrong for nobody**.

- It carries no semantics. Green means success somewhere, red means loss, blue means
  links or trust, and any of those may already be spoken for by a host. Graphite claims
  nothing.
- It cannot collide with a host's content imagery by hue, because it has effectively no
  hue — so `Filled` works out of the box, and `Outlined` becomes necessary only if the
  host's own override creates the collision (§5).
- Its darkness carries `accentInk` at ~11.6:1, so an overriding theme can move to almost
  any hue and still clear the floor without redesigning the button.
- Emphasis by *value* rather than by *hue* reads as restraint rather than as branding,
  which is the right posture for something the host is expected to re-skin.

The trade-off, stated plainly: graphite is not memorable, and a dark grey primary button
looks slightly severe beside colourful content. That is the intended default — the
framework stays unopinionated and lets the host add the opinion.

The neutrals are hue-neutral for the same reason. A hueless accent on tinted surfaces
reads muddy, so the two decisions travel together: a host that tints its surfaces should
tint its accent to match, and the reverse.

### 2.2 Advisory rules for host overrides

Neither is enforced. Both are stated because breaking them produces an overlay that looks
wrong for reasons hard to diagnose from the symptom.

1. **Contrast floor.** Keep every text-on-surface pair above 4.5:1.
2. **Elevation direction.** `surfaceDeep` ≥ `surface` > `surfaceSunken`, with the host's
   page background below `surface`. A page lighter than the frame makes it read as inset
   rather than floating; the scrim helps, but lightness is what carries it.

Changing `accent` has a structural knock-on — re-evaluate `EmphasisStyle` (§5).

## 3. Geometry tokens

Defaults for the table in the generalization plan §6.1. `ByWidth` values give `Wide` then
`Narrow`; a single value is the same at both.

| Token | Default | Notes |
| --- | --- | --- |
| `headerHeight` | 60 | title row with close control |
| `actionBarHeight` | 68 | button row |
| `tabStripHeight` | 44 | |
| `searchBarHeight` | 52 | |
| `fieldHeight` | per field type | sum of control + label + reserved message line |
| `messageLine` | 16 | reserved whether or not there is a message |
| `padding` | 22 | region horizontal padding; scroll region 18 top, 22 bottom |
| `rowGap` | 10 | between adjacent controls in a row |
| `frameWidth` | 620 / viewport | `Narrow` is full width, no side margins |
| `framePreferredHeight` | 720 / viewport − 124 | `Narrow` leaves scrim visible above |
| `frameMinHeight` | 420 | the floor the frame shrinks to, never past |
| `frameRadius` | 9 / 12 top only | `Narrow` sits on the bottom edge |

Frame borders are 1 px `border`; at `Narrow` the bottom border is off-screen. Elevation is
`0 8px 28px rgba(24,26,31,0.16)` at `Wide` and `0 -4px 20px rgba(24,26,31,0.18)` at
`Narrow`. Entry is a fade at `Wide`, a slide from the edge at `Narrow`.

## 4. Region chrome

**Header** — `divider` bottom hairline, `surface` fill, title left at 17 px/600 `ink`,
close control right, both vertically centred. Single line, no wrapping.

**Close control** — 26 × 26 px, radius 4 px, 1 px `border`, transparent fill, `✕` at
14 px in `inkMuted`, centred. Hover: border `borderHover`, glyph `ink`. Pressed:
background `surfaceSunken`. Present by default; a host may hide it when its footer
carries the exit.

**Actions** — `divider` top hairline, `surface` fill painted **opaque** so scrolled
content passes behind rather than through it.

**Scroll region** — vertical only, horizontal disabled. Overscroll contained: reaching
either end stops there and never scrolls the page behind.

### 4.1 Scrollbar

The scrollbar is framework chrome, not a platform default — a thin permanently-guttered
track, so content never reflows when it appears.

| Property | Value |
| --- | --- |
| Lane width | 10 px, always reserved |
| Track | transparent; the surface shows through |
| Thumb | `scrollThumb`, hover `scrollThumbHover`, drag `scrollThumbDrag` |
| Thumb radius | 4 px |
| Thumb inset | 2 px each side → 6 px visible thumb in a 10 px lane |
| Thumb minimum length | 32 px |
| Step arrows | none |

The lane sits inside the scroll region's 22 px right padding, so the thumb ends about
8 px from the inner edge and content keeps its full 22 px on the left. Do not compensate
by shrinking the right padding.

The gutter is reserved **at all times**, including when content is too short to scroll.
This is the single most important detail here: a scrollbar that appears and disappears
changes usable width, which silently re-wraps percentage rows and reintroduces exactly
the instability the region model exists to prevent.

No scroll shadows or edge fades — the region hairlines are the only separators. On touch
platforms momentum scrolling is native and the thumb may auto-hide; the gutter stays
reserved regardless.

## 5. `EmphasisStyle`

Default **`Filled`**, so a call site that says nothing gets the stronger treatment. Both
treatments are first-class.

**`Filled`** — background `accent`, 1 px `accent`, text `accentInk`, weight 600. Hover:
background `accentHover`. The strongest emphasis available; reads unambiguously as the
action to take.

**`Outlined`** — background `accentTint`, 1 px `accentMuted`, text `accent`, weight 600.
Hover: border `accent`. Quieter, and it keeps the primary action in the same visual
register as the rest of the frame.

The outlined border is deliberately **weaker** than the accent itself. The tint and the
label weight already mark the state; a full-strength border makes three signals for one
condition, which reads as shouting. If an outlined button needs strengthening, deepen
`accentTint` — do not promote the border to `accent`.

**Which to choose.** `Filled` is correct in most themes. `Outlined` exists for one
situation: when the theme's accent shares a hue family with the site's own content
imagery. Intellector is the motivating case — brass accent, tan and orange boards, so a
filled brass button near a board reads as a piece of board that came loose. The rule:

- Accent hue-distant from content imagery → `Filled`.
- Accent inside the content's hue family → `Outlined`.

Because the value is read by components as well as by the footer, selection treatment
inside the content follows it automatically, and the two cannot disagree.

## 6. Typography

Full detail in `haxefolio-typography.md`; the defaults are `uiFamily` **Onest**
(400/500/600) and `monoFamily` **IBM Plex Mono** (400/500), self-hosted WOFF2 with Latin
and Cyrillic subsets.

Mono is for numeric values only — clock readouts, ratings, notation, IDs. A host may
substitute either family but must keep the split, and must re-measure its own character
budgets afterwards: a family change invalidates every one of them.

Field labels are sentence case, not mono uppercase.
