# Form components — design rationale

Why the `haxefolio.form` components are shaped the way they are. The API, geometry and usage
live in the haxefolio README; this file keeps only the reasoning, so that a later change can
tell which decisions are load-bearing.

The library is host-agnostic: a page section, a sidebar panel, a card or the modern overlay's
body are all equally valid hosts. A host only gives a component a width to size its percentages
against. Nothing here assumes an overlay is involved, though the challenge-params overlay is
where the problems below were first met and solved.

The dividing line between the library and an app: the library owns *stability, states and
spacing*; the app owns *meaning* (game rules, product taxonomy, curated content, product
policy).

---

## 1. Why these components exist

Every parameter form runs into the same three problems, and the components are the repeated
solutions:

1. **Layout must not jump.** Every region whose contents vary is sized to its tallest variant,
   and every validated field reserves its message line whether or not it has a message. Done ad
   hoc it is easy to forget in one place out of twelve; done as a component it is structural.
2. **Validation must be visible without being loud.** The constraint and the error occupy the
   same reserved line — grey when satisfied, red when not.
3. **Settings must commit in one step.** No "press confirm to apply your selection", which was
   the single worst flaw of the overlay's previous iteration.

Two platform constraints apply throughout: **no `letter-spacing`** and **no
`text-overflow: ellipsis`**, so every component that renders a label must state a character
budget instead of relying on truncation.

## 2. Layering

Primitives (`FieldHeader`, `HintLine`, `ChoiceButton`, `Stepper`) → fields → containers, and
nothing skips a layer: a field never draws its own label text, it uses `FieldHeader`. That is
what keeps the anti-jump guarantee in one place.

## 3. Primitives

- **The header's right-hand hint is the load-bearing idea of `FieldHeader`.** Putting each
  constraint on its own field's header ("max 6:00:00" over the initial-time field, "max 120"
  over the bonus field) is what makes a multi-field group comprehensible; one combined line
  below the group forces the reader to work out which limit belongs to which control.
- **`HintLine` is always present**, height reserved when empty. That is what turns "validation
  appeared" into a colour change rather than a layout change.
- **Selection style is not a per-button property.** It comes from the enclosing theme or host
  (`EmphasisStyle`), because a form with some chips filled and others outlined has two
  definitions of "active". The overlay's footer button applies the same enum to a different
  control, so a form and the overlay presenting it agree on what "active" looks like without
  either hard-coding the other.
- **Disabled-and-selected is a muted grey-blue under both emphasis styles** — clearly chosen,
  clearly inert. A locked row must still show which value is in effect.
- **`Stepper` buttons are fixed width and the input flexes.** The other way round — fixed-width
  inputs with flexing buttons — is what broke the mobile layout in the first iteration.

## 4. Fields

- **Invalid input is never reverted or clamped.** It marks the field and reports invalidity
  upward; the user's keystrokes are theirs. Clamping on blur was considered and rejected as
  surprising. Clamping on a stepper button press is different — there is no "unparseable" case
  there — so `step` keeps its result in bounds.
- **`SteppedValueField` has no slider variant.** Steppers suit bounded integers; sliders cannot
  express exact values, which a time control needs.
- **`ChoiceRow` divides width in percentages, never pixels.** `stackOnCollapse` exists for
  localisation: three equal buttons at mobile-sheet width leave roughly 106px per label, and a
  row of four does not survive Russian at all, so once the row stacks it gets the full sheet
  width. That is what let «Случайно» fit without a contraction.
- **Responsive behaviour keys off the framework's single app-wide breakpoint**,
  `ResponsivityController.isCollapsed` (driven by `HaxeFolioConfig.menuCollapseWidth`), never a
  component-local viewport threshold. A per-field pixel breakpoint would reintroduce the
  `ResponsiveToolbox`/`ResponsivenessRule` pattern CLAUDE.md rejects; one global, live-updating
  flag is what the framework provides, and every host shares it. `ChoiceGrid`'s `perRow` is a
  two-value switch on that flag, not an independently invented desktop/mobile split.
- **`ChoiceGrid` cell width is `100% / perRow − gap`, as a percentage.** A pixel width would let
  a reserved scrollbar gutter, a container resize or a theme padding change push the last cell
  onto a second row.
- **`ChoiceGrid` supports single- and multi-select, chosen per instance**, as an enum rather
  than a `Bool` plus a pair of callbacks that would sit unused depending on the mode. Single
  mode's `selected` is nullable **by design**: a grid of presets is a *shortcut into* a value,
  not the value itself, so the highlight is derived from the neighbouring field's value instead
  of remembering which cell was clicked — otherwise the user types a custom value and a preset
  still looks active. Multi mode has no such shortcut use case, so there `selected` is exactly
  the set of checked options.
- **`CommitTextField` exists because a commit button with silent failure is worse than live
  validation** — for inputs too expensive or error-prone to validate per keystroke. Its
  `HintLine` cycles idle / applied / rejected. `onCommit` returns a result rather than throwing,
  so the host's validator stays a pure function. There is deliberately **no blur trigger**:
  HaxeFolio disables HaxeUI's `FocusManager`, so no focus-out event is delivered, and a
  blur-commit would fire before the click on the commit button and commit twice.
- **`ToggleButton` is for a boolean that reads as a mode**, where "off" is the normal state.
  Use a checkbox when the boolean is an attribute, and a two-option `ChoiceRow` when both
  states deserve equal visual weight (rated/unrated).

## 5. Containers

- **`SwapSlot` is a thin typed wrapper over HaxeUI's `Stack`**, which already shows one child at
  a time and, given an explicit height, does not resize on selection change. Its value is
  narrower than "swap without a jump": selection by an arbitrary key (typically an enum)
  instead of a string id or index, and a **mandatory** height. A bare `Stack` will happily
  auto-size and jump if a caller forgets to size it; making the height part of the type turns
  a convention someone can skip into a contract. A variant that does not fit the height is a
  design error to fix, not a case to accommodate. A runtime measurement is explicitly wrong for
  the same reason. Switching challenge type in the Intellector overlay changes a login field
  into a visibility row into an explanatory sentence — without the enforced height every
  switch moves everything below it.
- **`FieldGroup.fixedHeight` is a caller-supplied constant**, strongly recommended whenever the
  group's contents can change and sized to the tallest variant. `direction` is set per
  instance by the caller, not derived from a breakpoint system.
- **`PreviewPane` must not appear and disappear with a mode toggle.** It shows the effective
  value in every mode, including the default one. Showing it only in "custom" mode both moves
  the layout and hides the information the user needs in order to choose.
- **`FormSection` keeps inter-section rhythm out of every caller's hands.**

## 6. Model

- **`touched` is not decoration.** A form must not open covered in red: a required, empty field
  is `valid: false, touched: false`, which blocks submission while showing only its neutral
  constraint hint. A form aggregates validity, and its primary action is disabled and loses its
  emphasis fill while any field is invalid.
- **`EmphasisStyle` is the one model type not about a field's own state.** It governs how any
  component with a selected or primary state marks it. `Outlined` uses a tint plus a border
  deliberately weaker than full strength, so tint and label weight carry the signal. It is
  settable as a theme-wide default and overridable per host context, so whichever a host picks,
  every component inside speaks the same definition of "active".

## 7. Cross-cutting behaviours

- **One-step commit.** Except for `CommitTextField`, no component defers its effect. Any
  component that needs a confirmation step must show, in its own `HintLine`, that a change is
  pending — which is exactly what `CommitTextField` does and nothing else is allowed to.
- **Lock, never hide.** A parameter that stops applying is disabled in place, keeping its row,
  greyed, with the reason stated in a header hint. Hiding it moves the layout *and* conceals
  that the setting exists, so the user cannot learn why it disappeared. A locked control shows
  the value that will actually be used, not the value the user last chose; setting that value
  is the host's job, showing it while locked is the component's.
- **A lock belongs to whatever owns a place to state its reason.** `ChoiceRow`, `ChoiceGrid`
  and `FormSection` have a header hint, so they own a lock. `FieldGroup` has neither a header
  nor a reserved hint line, so a lock is not its to own: the host locks the fields inside it
  and puts the reason in a `HintLine` beneath.
- **Percentage sizing for every multi-child row.** The failure mode is shared: a reserved
  scrollbar gutter or a theme padding change silently re-wraps a pixel-sized row.

## 8. Presets plus custom: one value, two editors

A `ChoiceGrid` of presets and the stepper fields beside it are **views of one value**. The
grid's `selected` is computed by comparing each preset against the current value, so typing a
custom time clears the highlight and clicking a preset fills the fields — one value, two
editors, no synchronisation state. This is the pattern that replaced the two-step selection,
and it generalises to any "presets plus custom" control.
