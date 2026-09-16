# Form components — design plan

A **general-purpose form/data-entry component library**, independent of any particular
host. A host is whatever gives a component its available width and hosts its children —
a plain page section, a sidebar panel, a card, or (one option among several) the modern
overlay's scrollview body from the generic overlay spec. None of these components know
or care which one they're in; a host only needs to give them a width to size their
percentages against and a place to sit.

First identified while building the Intellector challenge-params overlay, but specified
here without reference to it — nothing in this plan assumes an overlay is involved.
§7's composition example happens to use the overlay body as its host because that is
where the pattern was first validated, not because it is the only valid host. §8 lists
what deliberately stays in Intellector.

---

## 0. Why these components exist

Every parameter form — inside an overlay, on a settings page, in a sidebar — runs into
the same three problems. The challenge-params overlay is simply where they were first
solved; those repeated solutions are the components:

1. **Layout must not jump.** Every region whose contents vary is sized to its tallest
   variant, and every validated field reserves its message line whether or not it has a
   message. Done ad hoc, this is easy to forget in one place out of twelve; done as a
   component, it is structural.
2. **Validation must be visible without being loud.** The constraint and the error
   occupy the same reserved line — grey when satisfied, red when not.
3. **Settings must commit in one step.** No "press confirm to apply your selection",
   which was the single worst flaw of the overlay's previous iteration.

Two platform constraints apply throughout: **no `letter-spacing`**, and **no
`text-overflow: ellipsis`**, so every component that renders a label must state a
character budget rather than relying on truncation.

---

## 1. Layer map

```
containers   FormSection · FieldGroup · SwapSlot · PreviewPane
fields       ChoiceRow · ChoiceGrid · SteppedValueField · CommitTextField · ToggleButton
primitives   FieldHeader · HintLine · ChoiceButton · Stepper
model        FieldState<T> · Lockable · EmphasisStyle
```

Fields compose primitives; containers arrange fields. Nothing skips a layer — a field
never draws its own label text, it uses `FieldHeader`.

---

## 2. Primitives

### 2.1 `FieldHeader`

A label on the left, an optional hint on the right, on one baseline-aligned row.

```haxe
{
  label:String,
  hint:Null<String>, // right-aligned; constraint text or per-field status
  state:HintState, // Normal | Error | Muted → colours the hint
  locked:Bool // greys the label (see Lockable, §6.2)
}
```

Label: 12 px, weight 500, `inkMuted`. Hint: 11 px, same colour, or `danger` when
`state == Error`. Bottom margin 5–6 px. Height is fixed regardless of whether `hint` is
present.

The right-hand hint is the load-bearing idea. Putting each constraint on its own field's
header ("max 6:00:00" over the initial-time field, "max 120" over the bonus field) is
what makes a multi-field group comprehensible; one combined line below the group forces
the reader to work out which limit belongs to which control.

**Budget:** label + hint share the host's available width; at 12 px/11 px a 288 px
half-width column holds roughly 22 label characters plus 14 hint characters.

### 2.2 `HintLine`

A fixed-height (16 px) line of message text that is **always present**.

```haxe
{ text:String, state:HintState }
```

Used below a control or a group when the message is too long for a header hint — a
validation explanation, an applied/not-applied status. The height is reserved when
`text` is empty. This is the component that makes "validation appeared" a colour change
rather than a layout change.

### 2.3 `ChoiceButton`

One selectable button. The atom of both `ChoiceRow` and `ChoiceGrid`.

```haxe
{
  label:String,
  icon:Null<ImageRef>, // optional leading or trailing glyph
  iconAlign:IconAlign, // Leading | Trailing
  selected:Bool,
  enabled:Bool,
  onClick:Void->Void
}
```

Geometry: 11 px vertical padding, radius 5 px, 13 px label, centred, single line, no
wrapping. Its **selected treatment follows `EmphasisStyle`** (§5) —
`Filled` gives `accent` fill with `accentInk` label; `Outlined` gives `accentTint` fill,
`accentMuted` border, `accent` label at weight 600. Unselected is `surfaceSunken` fill,
`border`, `inkMuted`. Disabled is `surfaceSunken`, `divider`, `inkFaint`.

Selection style is **not** a per-button property. It comes from the enclosing theme or
host, because a form with some chips filled and others outlined has two definitions of
"active". The generic overlay spec's footer button (its §5.4) applies the same enum to a
different control, so a form and the overlay presenting it agree on what "active" looks
like without either one hard-coding the other.

### 2.4 `Stepper`

The `−` / value / `+` triple, with no header and no hint.

```haxe
{
  text:String, // the rendered value; the field owns parsing
  onText:String->Void,
  onStep:Int->Void, // −1 / +1
  enabled:Bool,
  invalid:Bool,
  buttonWidth:Int // default 26 px
}
```

The buttons are **fixed width**, the input flexes and may shrink to nothing. That
direction matters: fixed-width inputs with flexing buttons is what broke the mobile
layout in the first iteration.

Input: `surfaceDeep` fill, 1 px `border` (`dangerBorder` when `invalid`), radius 4 px,
mono 14 px, centred. Minimum height 44 px on touch platforms.

---

## 3. Fields

Every field is `FieldHeader` + control + optional `HintLine`, and every field exposes its
validity so a form can disable its primary action.

### 3.1 `SteppedValueField<T>`

Your example. A `Stepper` with a header and a right-aligned constraint hint, generic over
the value type via a parse/format pair.

```haxe
{
  label:String,
  value:T,
  onChange:T->Void,
  parse:String->Null<T>, // null = unparseable
  format:T->String,
  step:T->Int->T, // apply −1 / +1
  validate:T->FieldState<T>,
  hint:String, // shown when valid, e.g. "max 6:00:00"
  enabled:Bool
}
```

Two ready-made instantiations ship with it:

- **`IntField`** — `parse` = decimal integer, `step` = ±1, bounds supplied.
- **`DurationField`** — `parse`/`format` handle `m:ss` and `h:mm:ss`, `step` = ±60 s.
  The format is stated in the hint or the label, never inferred.

Invalid input does **not** revert or clamp the text. It marks the field and reports
invalidity upward; the user's keystrokes are theirs. Clamping on blur is the one
alternative worth considering and is currently rejected as surprising.

### 3.2 `ChoiceRow<T>`

An enumerable parameter as a row of equal-width `ChoiceButton`s under a header.

```haxe
{
  label:String,
  options:Array<{ value:T, label:String, icon:Null<ImageRef> }>,
  selected:T,
  onSelect:T->Void,
  stackOnCollapse:Bool, // stack vertically once ResponsivityController.isCollapsed
  locked:Bool,
  lockReason:Null<String>
}
```

Buttons divide the available width equally **in percentages**, never pixels.
`stackOnCollapse` exists for localisation: three equal buttons at mobile-sheet width give
each roughly 106 px of label, and a row of four does not survive Russian at all — so once
the row stacks it gets full sheet width instead. This is the mechanism that let
«Случайно» fit without a contraction.

This must key off the framework's single existing, app-wide breakpoint,
`ResponsivityController.isCollapsed` (driven by `HaxeFolioConfig.menuCollapseWidth`) —
the same flag that already collapses the menu bar and, where the host happens to be the
modern overlay, chooses its Modal vs. SideBar chrome (§2 of the overlay spec) — rather
than a new, component-local viewport-px threshold. A per-field pixel breakpoint would
reintroduce the `ResponsiveToolbox`/`ResponsivenessRule` pattern CLAUDE.md has already
rejected; a single global, live-updating flag is what the framework provides instead, and
every host (overlay or otherwise) shares it.

**Budget:** state it per row as `rowWidth / n`, and give translators that number.

### 3.3 `ChoiceGrid<T>`

The same selection semantics as `ChoiceRow`, but wrapping, for 6–20 curated options.
Supports both single- and multi-select, chosen per instance by the framework user —
the two modes carry different callback shapes, so the choice is an enum rather than a
`Bool` flag plus a pair of fields that would otherwise sit unused depending on the mode:

```haxe
enum ChoiceGridSelection<T> {
  Single(selected:Null<T>, onSelect:T->Void);   // null = none of the presets matches
  Multi(selected:Array<T>, onToggle:T->Bool->Void); // Bool = the option's new membership
}

{
  label:String,
  options:Array<{ value:T, label:String, icon:Null<ImageRef> }>,
  selection:ChoiceGridSelection<T>,
  perRow:{ expanded:Int, collapsed:Int }, // keyed by ResponsivityController.isCollapsed
  gap:Int // default 6 px
}
```

Cell width is `100% / perRow − gap`, computed as a percentage. Never a pixel width: a
host's reserved scrollbar gutter, a container resize, or a theme change in padding will
otherwise push the last cell onto a second row. `perRow` is a two-value switch on the
framework's one existing, app-wide breakpoint (`expanded` when
`!ResponsivityController.isCollapsed`, `collapsed` when it's `true`) — the same flag
every host already shares (including the overlay's own Modal/SideBar choice, where that
happens to be the host) — not an independently invented desktop/mobile split.

**In `Single` mode, `selected` is nullable, and that is the design.** A grid of presets
is a *shortcut into* a value, not the value itself. When a neighbouring field holds the
same underlying value, the grid must derive its highlight from that value rather than
remembering which cell was clicked — otherwise the user types a custom value and a
preset still looks active. See §7 for the binding pattern. `Multi` mode has no
"shortcut into a neighbouring field" use case yet, so `selected` there is exactly the
set of checked options — the component's own state, not a derived view of something
else.

### 3.4 `CommitTextField`

A text input whose value applies on an explicit action, for inputs too expensive or too
error-prone to validate per keystroke.

```haxe
{
  label:String,
  text:String,
  onText:String->Void,
  onCommit:String->CommitResult, // Applied | Rejected(message)
  commitLabel:String, // e.g. "Apply"
  commitTrigger:CommitTrigger, // Button | BlurAndEnter | Both
  idleHint:String, // "Edit the value, then press Apply"
  enabled:Bool
}
```

It owns a `HintLine` cycling through three messages: the idle instruction, the success
confirmation, and the rejection reason. That line is why the component exists — a commit
button with silent failure is worse than live validation.

`onCommit` returns rather than throws, so the host's validator stays a pure function.

### 3.5 `ToggleButton`

A boolean as one wide button that reads as a mode rather than a checkbox — for the case
where the "off" state is the normal one and "on" is a distinct mode (the "no time
control" case).

```haxe
{ label:String, icon:Null<ImageRef>, on:Bool, onToggle:Bool->Void, enabled:Bool }
```

Full width, same styling rules as `ChoiceButton`. Use a checkbox instead when the
boolean is an attribute rather than a mode, and `ChoiceRow` with two options when both
states deserve equal visual weight (rated/unrated).

---

## 4. Containers

### 4.1 `FieldGroup`

A `surfaceSunken` inset box, radius 6 px, padding 12/14 px, that groups fields belonging
to one parameter.

```haxe
{ children:Array<Component>, fixedHeight:Null<Int>, direction:Horizontal | Vertical }
```

`fixedHeight` is optional but **strongly recommended whenever the group's contents can
change**, sized to the tallest variant. `direction` is what lets a two-field group sit
side by side on desktop and stack on mobile without the caller rebuilding it.

### 4.2 `SwapSlot`

A fixed-height region that shows one of several variants. **Built on HaxeUI's `Stack`**
(`haxe.ui.containers.Stack`), not a from-scratch component — `Stack` already shows
exactly one child at a time and, given an explicit height, already won't resize when the
selection changes, since a hidden child is excluded from layout. `SwapSlot` doesn't
reinvent that; it's a thin typed wrapper around it, and its value is narrower than "swap
without a jump" alone:

```haxe
{
  variants:Map<K, Component>,
  active:K,
  height:Int // sized to the tallest variant, measured once
}
```

- **Selection by an arbitrary key `K`** (an enum, typically) instead of `Stack`'s own
  string id / int index, so a caller keying off `ChallengeType` or similar doesn't hand-rig
  an id-per-variant mapping — `active` sets `Stack.selectedIndex` via the variant's
  position in `variants`.
- **`height` is mandatory, not merely possible.** A bare `Stack` will happily auto-size
  and jump if a caller forgets to size it; `SwapSlot` makes the "constant height, never
  measured" contract part of the type itself rather than a convention someone can skip.
  If a variant does not fit the supplied height, that is a design error to fix, not a
  case to accommodate.

Reinvented badly precisely because that convention is easy to forget on a raw `Stack`.
Switching challenge type in the Intellector overlay changes a login field into a
visibility row into an explanatory sentence; without the enforced height, every switch
moves everything below it.

### 4.3 `PreviewPane`

A caption row plus a fixed-size preview area for arbitrary host content (a rendered
position, a colour swatch, a generated image).

```haxe
{ caption:Null<String>, captionIcon:Null<ImageRef>, width:Int, height:Int,
  content:Component }
```

Fixed dimensions, always rendered. **The preview must not appear and disappear with a
mode toggle** — it shows the effective value in every mode, including the default one.
Showing it only in "custom" mode both moves the layout and hides the information the
user needs in order to choose.

### 4.4 `FormSection`

Section label, content, standard 18 px bottom margin. Thin, but it is what keeps
inter-section rhythm out of every caller's hands.

```haxe
{ label:Null<String>, headerHint:Null<String>, children:Array<Component>,
  locked:Bool, lockReason:Null<String> }
```

---

## 5. Model types

```haxe
enum HintState { Normal; Muted; Error; }

typedef FieldState<T> = {
  value:T,
  valid:Bool,
  message:Null<String>, // constraint when valid, reason when not
  touched:Bool // errors show only after interaction
}

enum CommitResult { Applied; Rejected(message:String); }
enum CommitTrigger { Button; BlurAndEnter; Both; }
enum IconAlign { Leading; Trailing; }
enum EmphasisStyle { Filled; Outlined; }
```

`touched` is not decoration. A form must not open covered in red; a field that is empty
and required is `valid: false, touched: false`, which blocks submission while showing
only its neutral constraint hint.

A form aggregates: `valid` = every field valid; the primary action is disabled and loses
its emphasis fill while any field is invalid.

**`EmphasisStyle`** is the one model type here that isn't about a field's own state — it
governs how *any* component with a selected or primary visual state (`ChoiceButton`,
`ToggleButton`) marks that state. `Filled` gives a solid `accent` fill; `Outlined` gives
an `accentTint` fill with an `accentMuted` border, deliberately weaker than a full-strength
border so tint and label weight carry the signal (see `ChoiceButton`, §2.3, for the exact
mapping). It is settable at a theme-wide default and overridable per host context (a
page, a panel, or — as the generic overlay spec's §5.4 does for its footer button — a
single overlay instance), so that whichever a given host picks, every component inside it
speaks the same visual definition of "active." Nothing here assumes the host is an
overlay: a plain settings page composed from these components needs the same choice.

---

## 6. Cross-cutting behaviours

### 6.1 One-step commit

Except for `CommitTextField`, **no component defers its effect**. A preset click changes
the value immediately; a stepper click changes it immediately. Any component that needs a
confirmation step must show, in its own `HintLine`, that a change is pending — which is
exactly what `CommitTextField` does and what nothing else is allowed to do.

### 6.2 `Lockable` — conditional parameters

A parameter that stops applying is **disabled in place, never hidden**: it keeps its row,
greyed, with the reason stated in the header hint or the group's `HintLine`.

```haxe
{ locked:Bool, lockReason:Null<String> }
```

Hiding it does two bad things at once — it moves the layout, and it conceals the fact
that the setting exists, so the user cannot learn why it disappeared. `ChoiceRow`,
`ChoiceGrid`, `FormSection` and `FieldGroup` all take these two fields.

A locked control should also display the value that will actually be used, not the value
the user last chose, when those differ.

### 6.3 Percentage sizing

Every multi-child row sizes children in percentages. Stated once here rather than in each
component, because the failure mode is shared: a reserved scrollbar gutter or a theme
padding change silently re-wraps a pixel-sized row.

---

## 7. Composition example

These components compose the same way regardless of host. The example below happens to
use the Intellector challenge-params overlay's body as its host — the origin case — but
nothing in the composition is specific to being inside an overlay:

```
FormSection "Challenge type"
  ChoiceRow<ChallengeType>            direct | open | bot
  SwapSlot<ChallengeType> h=76
    direct → CommitTextField-less text field + FieldHeader hint
    open   → ChoiceRow<Visibility>
    bot    → static text

FormSection "Time control"
  ChoiceGrid<TimeControl> perRow={expanded:5,collapsed:3}   ← selected derived from the value below
  ToggleButton "No time control"
  FieldGroup h={76,142} direction={H,V}
    icon slot (host content)
    DurationField "Initial time"  hint "max 6:00:00"
    IntField      "Bonus secs / turn" hint "max 120"

FormSection
  ChoiceRow<Rated> stackOnCollapse=true
  ChoiceRow<Colour> stackOnCollapse=true  locked=rated  lockReason="Rated games use random colour"

FormSection "Starting position"
  ChoiceRow<PosMode> locked=rated
  FieldGroup
    CommitTextField commitLabel="Apply"
    PreviewPane caption="White to move" (host-rendered board)
```

The binding worth noting: the `ChoiceGrid` and the two stepper fields are **views of one
value**. The grid's `selected` is computed by comparing each preset against the current
value, so typing a custom time clears the highlight and clicking a preset fills the
fields — one value, two editors, no synchronisation state. This is the pattern that
replaced the two-step selection, and it generalises to any "presets plus custom" control.

---

## 8. What stays in Intellector

Not generalisable, and should not be pushed upstream:

- **The board widget** — game-specific geometry and piece rendering. It is host content
  handed to `PreviewPane`.
- **SIP parsing and validation** — a game rule. It is the host's `onCommit`.
- **Time-control kind classification** (hyperbullet → correspondence, and the icon per
  kind) — a product taxonomy. The framework sees only `ImageRef`s.
- **The curated preset list** — product content.
- **The rated-disables-colour-and-position rule** — a product policy expressed through
  `Lockable`.

The dividing line: the framework owns *stability, states and spacing*; the host owns
*meaning*.

---

## 9. Build order

1. `FieldHeader`, `HintLine`, `FieldState<T>` — everything depends on them, and they are
   where the anti-jump guarantee actually lives.
2. `ChoiceButton` + `ChoiceRow` — the most-used field by a wide margin.
3. `SwapSlot`, `FieldGroup` — enable stable layouts before more field types exist.
4. `Stepper` + `SteppedValueField` with `IntField` / `DurationField`.
5. `ChoiceGrid`, `ToggleButton`.
6. `CommitTextField`, `PreviewPane` — narrowest applicability, most host-specific.

## 10. Resolved questions

- **`SteppedValueField` does not need a slider variant.** Steppers suit bounded integers;
  sliders cannot express exact values, which a time control needs.
- **`ChoiceGrid` supports both single- and multi-select**, chosen by the framework user
  per instance. See the revised §3.3 typedef.
- **A group's `fixedHeight` is a caller-supplied constant.** No design-time measurement
  tool for now; a runtime measurement stays explicitly wrong (§4.2).
- **`FieldGroup.direction` belongs to the component**, set per instance by the caller —
  not derived from a breakpoint system.
