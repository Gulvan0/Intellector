# Overlay system — design rationale

What replaced HaxeFolio's original overlay system, and why. API and usage live in the haxefolio
README; this file keeps only the reasoning, so a later change can tell which decisions are
load-bearing. Colour, type and geometry defaults are in `plans/haxefolio/haxefolio-theme.md`.

Built in eight steps: `ByWidth`/`bind`, `Appearance`, `RegionStack`, `present`/`embed`,
`HeaderBar`/`ActionBar`, `Tabs`, the preference window, and (unbuilt, only when a real case
demands them) `SearchBar`, `Toolbar`, `StepIndicator`.

## 1. Composition, not configuration

The old system was one overlay class growing a flag per case. Every overlay built so far (plain,
tabbed, auth, preferences) is the same thing: **a fixed-size frame holding an ordered list of
regions, exactly one of which scrolls.** So the framework offers a small `Region` model
(`Header`, `Tabs`, `Actions`, `Custom`, `Scroll`) and a set of contracts; a new case is a new
composition by the host, not a new flag upstream. That is the test of the abstraction.

The scrolling area is either a `Scroll` region or the pages of `Tabs` - never both.

## 2. Declared, never measured

Every height is a token or a sum of tokens; nothing asks a child how tall it is.
`scrollHeight = frameHeight - sum of fixed heights`, and the scroll region is the only thing that
ever resizes - so adding a field, switching a tab or resizing the window never moves another
region. Auto-sizing, wrapping and "reflow when it overflows" are out: they decide layout by
measurement and produce jumping. Content that does not fit is a design error, not a case to
accommodate. The one exemption is the content *inside* a `ScrollArea`, whose natural size never
feeds the arithmetic (so tab pages may differ in height, each keeping its scroll offset).

## 3. Presentation is private

`present` takes no presentation argument. The framework picks dialog (expanded) or sheet
(collapsed) from `ResponsivityController.isCollapsed` once, at present time, and it stays fixed
for that overlay's life (swapping live would rebuild the content and lose typed input). Hosts may
branch on the breakpoint *state* (`mobileContentFactory`, `ByWidth`), never on the presentation:
a host that names it makes the breakpoint decision at every call site and starts writing content
valid in only one shape.

Both are modal (the rest of the app is `inert`, menu bar included), neither is draggable, and
dismissal is Esc, the header's close control, a footer action or navigation - nothing else (no
click-outside). `embed` is a separate call, not a third presentation: nothing presents or
dismisses embedded content, and it has no commit point unless the host gives it one (either an
`Actions` region, or per-field commit with save *and* rejection reported; mixing the two is not
legal, since the user cannot tell what is already committed).

## 4. One breakpoint, one mechanism

The only breakpoint is `menuCollapseWidth`. Components never subscribe to it themselves or invent
a pixel threshold; they take a `ByWidth<T>` (one value, or `{expanded, collapsed}`) and pass it
through `ResponsivityController.bind`. That replaced `ChoicesPerRow`, `stackOnCollapse` and every
direct `onCollapseChange` subscription. `FieldGroup` is the reflowing container built on it.

## 5. Code vs. stylesheet

Colour and type stay in CSS (the cascade is the right mechanism; duplicating them in code gives
two ways to set one thing, with code silently winning). What the height arithmetic reads must be
in code, because it is needed before layout and reading it back from the style engine would make
stability depend on cascade timing - hence `GeometryTokens`. `EmphasisStyle` is code-side despite
looking like styling: it is *which treatment means primary*, and components must agree on it, so
there is no CSS channel for it. Overrides arrive theme-wide or per overlay
(`AppearanceOverrides`, with an optional `styleClass` for a shared variant); per-overlay colour
goes through the generated `#haxefolio-overlay-<slug>-*` ids. No per-call-site numbers on
ordinary fields - that is how dialogs end up with four header heights.

## 6. Tabs: a region, two roles

`Tabs` owns the strip and its pages (a `SwapSlot` of per-page `ScrollArea`s). It is built rather
than skinned because HaxeUI's `TabView` cannot carry a per-tab error marker. `TabRole` states the
meaning: **`Navigate`** if the tabs can be saved together (one footer, state persists), **`Choose`**
if picking one discards the other (title follows the tab, primary action relabels). Making it
explicit stops the classic bug of a Save that only commits the visible tab.

## 7. Contracts every component cites

Stability (height is a property of the type; scrollbar lane always reserved; scroll stops at the
end; percentage widths in rows); reserved message lines (validation is a colour change, not a
layout change); visible blame (a blocked action shows what blocks it, incl. a marker on a tab
hiding an invalid field); one-step commit; disable in place with a stated reason; fit by
construction (no ellipsis exists, so character budgets are stated against the collapsed width).
The framework owns stability, states and spacing; the host owns meaning, copy, domain
validation and policy. No global keyboard shortcuts beyond Esc.

## 8. The preference window

Rebuilt in full on `present` (slug `preference`): `Header`, `Navigate` `Tabs`, `Actions` with
Reset only. Every preference autosaves, which is what makes a Save-less footer legal; nothing
may reintroduce a mixed state. The autosave notice was dropped, and the old `TabView`, row
components and `.haxefolio-preference-*` CSS were deleted. The window is now a modal dialog/sheet
- an accepted behaviour change (it was a non-blocking box beside a live menu bar).

Control per preference is fixed in one place (`PreferenceWindowBuilder`) by kind and value count:
toggle -> `ToggleButton`; 2-4 values -> `ChoiceRow` (stacked when collapsed); 5-20 -> `ChoiceGrid`;
more throws. `locale` follows the same rule. Each preference is its own `FormSection` with a
header, so all read identically. Controls render from `Preference.get()` and follow `onChange`
(cross-tab sync), which required a silent `ChoiceRow.select`. The host customizes the window via
`HaxeFolioConfig.preferenceWindowAppearance` and the per-overlay ids. Reset is a non-primary
`ActionButton` (`ActionBar` takes only those), not a plain `Button`: a destructive secondary
action must not be presented as *the* action.

## 9. ToggleButton (departs from the original plan)

The plan refused a switch and had a label-only full-width button whose fill alone carried the
state. In use, that blended with `ChoiceButton`s and an off toggle read as an unselected choice.
Settled design:

- **Switch marker** at the trailing edge (rounded-square track and thumb, matching the 5px radius
  language, not a round pill), so the state and the affordance are visible.
- **Per-state captions** (`ToggleLabels {on, off}`, plain strings or `{{key}}`), defaulting to
  the host-defined keys `haxefolio.toggle.on/off`. The original "label never changes with state"
  rule is dropped: with a switch carrying the state, an "Enabled/Disabled" state word is
  unambiguous and the setting's name lives in the section header. `caption` and `glyph` were
  removed (the marker takes the icon slot).
- **Layout: full width, label left, switch pinned right** - a settings row. Tried and rejected:
  centring label+switch (reads off-centre against the seam of neighbouring choice rows, and the
  group jumps as the state word changes width); a content-sized left-aligned chip (viable, but
  breaks the uniform width every other control has); 80% centred (a near-miss width reads as a
  misalignment). A two-half "shared axis" split was considered and not built: the axis is a seam
  only in 2-value rows, and it needs an overlay composite instead of a `Button`.

## Known gaps

`ToggleButton` has no `locked`/`lockReason` (add when a host needs it). A control-height token
(40px, 44px on touch) is owed to `GeometryTokens`. The menu bar and side bar still carry their
original styling and must be brought onto the theme. Not every built-in component consumes the
geometry tokens yet; each is wired up as its region lands.
