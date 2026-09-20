# HaxeFolio — new overlay system

How the overlay work becomes framework primitives, and where generalization should stop.

**This replaces the whole existing overlay system** — `HaxeFolioApp.showOverlay`,
`ModalOverlay`, `SideBarOverlay`, `OverlayLayout`, `OverlayCloseButton` and the
`OverlayContent` class — and `showPreferences` is rebuilt on top of it. A few mechanics of the
old system carry over deliberately (dialog on expanded / sheet on collapsed, the exclusive
full-viewport sheet backdrop, live viewport measurement); §9 lists exactly what is kept and what
is dropped.

**Vocabulary.** The breakpoint is HaxeFolio's existing one: `HaxeFolioConfig.menuCollapseWidth`,
read through `ResponsivityController.isCollapsed`. Its two states are called **expanded** and
**collapsed** throughout this document; no second vocabulary (`Wide`/`Narrow`) is introduced.
"Dialog" and "sheet" name the two presentations, which correspond to expanded and collapsed.

The default style of HaxeFolio (overridable by the framework user) is described in @knowledge/plans/haxefolio/haxefolio-theme.md.

## 0. The principle

**Universality by composition, not by configuration.**

The tempting path is one `Overlay` component that grows a property for every case:
`hasTabs`, `tabStyle`, `footerMode`, `titleFollowsTab`. Forty properties later it covers
everything and is comprehensible to nobody, and every new case is a framework release.

The alternative: a **small region model** plus a set of **contracts**. Cases are built by
composing regions; the framework guarantees the properties that are hard to get right by
hand. A new case is a new composition by the host, not a new flag upstream.

Everything below follows from that.

---

## 1. The core abstraction: `RegionStack`

Every overlay built so far — plain, tabbed, auth, preferences — is the same structure:

> A fixed-size frame containing an ordered list of regions, **one of which is the scrolling
> area**. Every other region has a constant height.

```haxe
enum Region {
  Header(title:String, ?height:ByWidth<Int>, ?hideClose:Bool);
  Tabs(role:TabRole, pages:Array<TabPage>, ?stripHeight:ByWidth<Int>);
  Actions(bar:ActionBar, ?height:ByWidth<Int>);
  Search(bar:SearchBar, ?height:ByWidth<Int>);
  Custom(height:ByWidth<Int>, content:Component);
  Scroll(content:Component);
}

typedef TabPage = {
  label:    String,
  ?icon:    String,
  content:  Component
}
```

**The scrolling area is either `Scroll` or the pages of `Tabs` — never both.** `Tabs` owns the
tab strip (the fixed row of labels) *and* its pages: it contributes a constant-height strip
region and, below it, the scrolling area. A composition therefore has at most one `Scroll` or
`Tabs`, and a tabbed one lists no separate `Scroll`. Tab pages are switched by a `SwapSlot`
(§3) whose declared height is `scrollHeight`; each page sits in its own `ScrollView` that fills
it. A plain `Scroll` region is a single `ScrollView`.

typedef OverlayContent = {
  title:        String,
  regions:      Array<Region>,
  ?onDismissed: Void->Void
}
```

`onDismissed` is the content's own teardown hook: whatever the content registered while it
was built — a `Preference.onChange` handle, a `ChoiceGrid` breakpoint binding — is released
there. The framework calls it exactly once when the overlay is gone, before the `onDismissed`
argument of `present` (which belongs to the host that called `present`, not to the content).
It replaces the old `OverlayContent.addDetachable` / `dispose` pair.

**The host does not supply heights.** Every provided region knows its own from the
geometry tokens (§6.1) — `Header` is 60, `Actions` 68, `Tabs` 44 — so the optional
`height` is an override, not a requirement, and `Custom` is the only constructor that
insists on a number because HaxeFolio has no constant for a region it did not design.

Nor is the **frame size the host's to set** — it arrives from the presentation layer (§2),
which knows the screen. The framework computes
`scrollHeight = frameHeight − Σ fixed heights` for the active state (expanded or collapsed),
and the scroll region absorbs whatever difference the frame has. That single computation is
what every variant currently does by hand, and it is where the layout-stability guarantee
actually lives.

`ByWidth<T>` is either one value or an `{expanded:T, collapsed:T}` pair. Where a value
differs between the two states, this is how it is said. It is the framework's single
"value per breakpoint state" type and replaces the form layer's `ChoicesPerRow`
(same shape, same job); see §3.7 for the one mechanism that consumes it.

One consequence worth stating plainly: **adding a field to the body requires no
arithmetic anywhere.** The scroll region absorbs it; the overlay simply begins scrolling
at a smaller screen. Heights are only ever declared for regions and for components whose
own height varies, and those are computed from the token table, not by hand.

A per-instance height override is legal where an instance genuinely differs — a header
carrying a subtitle line, a footer with a legal notice above the buttons. It is **not** a
remedy for overflow: content that does not fit is a design error (§1.1), and a taller
region only conceals it one screen size longer.

What this buys immediately:

| Composition | Regions |
| --- | --- |
| Plain form | Header 60, Scroll, Footer 68 |
| Tabbed form | Header 60, Tabs (strip 44 + scrolling pages), Footer 68 |
| Preferences | Header 60, Tabs (strip 44 + scrolling pages), Footer 68 |
| Searchable list | Header 60, SearchBar 52, Scroll, Footer 68 |
| Wizard | Header 60, StepIndicator 40, Scroll, Footer 68 |
| Toolbar panel | Toolbar 48, Scroll |
| Confirmation | Scroll, Footer 68 |

None of those needs a framework change. **That is the test of whether the abstraction is
right**: new shapes are compositions, not releases.

### 1.1 Declared, never measured

Every height in the system traces to a geometry token or to a sum of tokens. The
framework computes composition — tallest variant, stacked row, scroll remainder — and
**never asks a child how tall it is.**

The distinction is not "the numbers are fixed": tokens are overridable (§6.1), and so is
any single region instance. What is forbidden is *obtaining* a height by measurement.
Auto-sizing to content, `flex-wrap`, and reflow triggered by a measured overflow are all
out, and a component that declares two layouts (§3.7) picks between them by breakpoint
state, never by measuring whether the first one fit.

A region that sizes itself to its content reintroduces exactly the jumping this whole
system exists to prevent, and an overlay whose frame changes size when the user clicks a
tab is worse than one with empty space at the bottom.

If content does not fit its region, that is a design error to correct, not a runtime case
to accommodate.

**The one exemption: the content inside a `ScrollView`.** It is always its natural size and
has no declared height — that is what a scroll view is for. The scrolling area itself is not
exempt: its height is `scrollHeight`, a number from the arithmetic, never a measurement. The
arithmetic never needs the content's size, because
`scrollHeight = frameHeight − Σ fixed heights` does not depend on what is inside. Consequently
the pages of a `Tabs` region may each have a different height; each page scrolls on its own
inside a slot whose size never changes, and no space is reserved for the tallest page. The
exemption ends at the edge of the `ScrollView`: a fixed region, or a component with siblings
after it inside the scroll content (a `SwapSlot` between two fields), still declares its
height.

---

## 2. Presentation is internal

The frame is one thing; how it meets the screen is another — and only the first is the
host's business.

```haxe
HaxeFolioApp.present(
  slug:String,
  contentFactory:(dismiss:Void->Void)->OverlayContent,
  ?mobileContentFactory:(dismiss:Void->Void)->OverlayContent,
  ?appearance:AppearanceOverrides,
  ?onDismissed:Void->Void
):Void
```

There is no presentation argument. `slug` identifies the overlay for CSS (§6.0) and must be
unique per call site. `contentFactory` receives a `dismiss` handle so a footer action can
close the overlay; `mobileContentFactory`, when given, is used instead of it while the
breakpoint is collapsed — this is how a host branches for the two states (see below). The
optional `appearance` argument carries this overlay's own geometry and emphasis overrides
(§6.1). A call while an overlay is already open is a no-op.

Inside, the framework reads `ResponsivityController.isCollapsed` **once, when `present` is
called**, and renders the content as a centred desktop dialog (expanded) or a full-height
mobile sheet (collapsed). Both are private implementations of one job: give the region stack
a stable frame and a way out.

**The presentation is fixed for the lifetime of that overlay.** If the viewport crosses the
breakpoint while it is open, the dialog does not turn into a sheet or vice versa; the frame
keeps tracking the viewport within its presentation (§2.1), and breakpoint-aware components
inside it still reflow live (§3.7). The alternative — swapping presentation live — would
have to rebuild the content from the other factory and lose whatever the user had typed.

```haxe
private enum Presentation {
  Dialog;   // centred window, scrim, fixed width
  Sheet;    // full-height, edge-anchored, viewport width
}
```

**Both are modal, and neither is draggable.** Scrim, focus trap and page-scroll lock
apply in both presentations; dismissal is Esc, the header's close control, or a footer action,
and nothing else. The scrim covers the whole screen, menu bar included. The close control is
**present by default and may be hidden** (`hideClose` on `Header`) by a host that has its own
exit in the footer; a composition with no `Header` region has no close control and relies on
Esc or a footer action. Dragging is refused outright — a movable frame needs a drag handle
region, a position to remember and a viewport-edge policy, all to serve a window the user
cannot do anything behind anyway.

This is the abstraction worth defending. A host that names its presentation has to make
the breakpoint decision at every call site, and will get it wrong at one of them; worse,
it starts writing content that only works in the shape it asked for. Keeping the choice
internal means every overlay in the application responds to screen size identically, and
the framework can change how it responds — a different breakpoint, a tablet case, a
larger sheet — without touching a single host.

Presentation owns: frame size, scrim, focus trap, page-scroll lock, dismissal — including
Esc-to-dismiss, which belongs here and nowhere else — entry animation, corner radii.
The stack owns: regions and their fixed heights. Neither knows the other.

### 2.1 The frame tracks the viewport; only the scroll region notices

Within a presentation the frame is not a constant. A desktop dialog has a preferred height, but
a short viewport shrinks it — down to a floor, below which it stops rather than becoming
unusable — and it keeps tracking as the window is resized instead of staying pinned
to whatever was measured when it opened.

This is the clearest case for the height arithmetic of §1. Fixed regions read their
heights from tokens, so a changing frame changes exactly one number:
`scrollHeight = frameHeight − Σ fixed heights`. **The scroll region is the only region
that ever resizes** — header, the tab strip and actions are untouched by a window resize, and
no content reflows. For a `Tabs` region, `RegionStack` pushes the new `scrollHeight` into the
pages' `SwapSlot`, which is why that slot's height is settable after construction. A system where regions shared the slack would re-lay-out the whole
overlay on every drag of the window edge.

### 2.2 One breakpoint, application-wide

The breakpoint is `HaxeFolioConfig.menuCollapseWidth`, and its current state is
`ResponsivityController.isCollapsed` — the same flag that collapses the application's
navigation, never a threshold a component invents for itself. A component-local pixel
threshold is how a UI ends up switching layouts at four different widths, and it is the
pattern this project has already rejected once.

Components do not subscribe to the flag themselves. They accept a `ByWidth<T>` and hand it
to the one shared mechanism described in §3.7; that mechanism is also what makes a
`FieldGroup` reflow because the state changed, not because it measured anything or holds a
number of its own.

**Hosts may branch on the breakpoint state — through `mobileContentFactory`, or by passing a
`ByWidth` value. Hosts may never name a presentation.** The state is a public fact about
available space, and a host that reflows needs it. Dialog-versus-sheet is a private rendering
decision that merely correlates with it, and keeping it private is what leaves scrim, edge
anchoring, dismissal and frame size out of host code entirely.

The flag is a boolean by design. If HaxeFolio ever grows a third state, `ByWidth` is the type
that generalises; nothing else in this document assumes two.

The cost the host does carry: **content must be valid in both states.** Percentage sizing
(§4.1) and character budgets (§4.6) are therefore stated against **collapsed**, not against
the expanded frame.

No other keyboard shortcut is part of the framework. Tab cycling and overlay submission
are deliberately not bound: a host may want those keys for its own controls, and a footer's
primary action is frequently destructive or disabled, so a global Enter would commit the
wrong thing. Hosts that want either bind it themselves against their own composition.

### 2.3 Inline is a different call, not a third presentation

An embedded settings panel is not an overlay that happens to lack a scrim — nothing
presents it, nothing dismisses it, and its width comes from the page. It takes the same
`OverlayContent` through a separate entry point:

```haxe
HaxeFolioApp.embed(slug:String, content:OverlayContent, into:Component, ?appearance:AppearanceOverrides):Void
```

So the region model is reused while `present` stays free of a presentation argument. What
`embed` does not inherit is the commit point — see §3.5.

---

## 3. Tabs are a region, and there are two kinds

Not two components — one `Tabs` region with a stated role, because the role determines three
other things.

`Tabs` owns the whole tabbed area: the **strip** (the fixed row of tab labels, drawn by
`TabStrip`) and the **pages** those labels switch between. The pages sit in a `SwapSlot` whose
declared height is `scrollHeight` (§1, §2.1), and each page is wrapped in its own `ScrollView`
that fills the slot. So the slot never changes size when the user switches tabs, pages may
differ in height (§1.1), and every page keeps its own scroll offset — switching away and back
returns the user to where they were, which is what "state persists" means for `Navigate` and
costs `Choose` nothing.

```haxe
enum TabRole {
  Navigate;   // one form cut into groups; shared state and footer
  Choose;     // alternative forms; nothing shared
}
```

| | `Navigate` | `Choose` |
| --- | --- | --- |
| Visual | Underlined tabs, flush | Segmented control on a recessed track |
| Footer | One, constant, shared by all tabs (commits all of them, or under per-control autosave holds only shared actions such as Reset) | Primary action relabels per tab |
| Frame title | Fixed | Follows the tab |
| Switching | Defers; state persists | Abandons; nothing shared |
| Validation | Must surface on the strip (§4.3) | Active form only |

Making the role explicit is what stops the two from being built as one confused thing.
The commonest real-world bug here is a preferences dialog whose Save only commits the
visible tab — which is `Navigate` styling with `Choose` semantics.

**Rule:** if the tabs can be saved together, it is `Navigate`. If choosing one discards
the other, it is `Choose`.

---

## 3.5 Where forms may go

Whether form components may be used is decided not by how the content reaches the screen
but by two properties of the composition itself — which is the other reason the host does
not need to know its presentation:

- **A commit point** — somewhere for the primary action to live, so §4.4 (one-step
  commit) and §4.3 (visible blame) have an anchor.
- **A stable, known width** — without it, percentage sizing (§4.1) and character budgets
  (§4.6) are both meaningless.

`present` satisfies both by construction: it always has a footer region available, and
its width is one of two known values. Forms are unconditionally legal there, with
multi-control rows handled by `FieldGroup` (§3.7).

`embed` satisfies neither automatically, so it is the one case the host must think about.

A framework is stronger for not offering a surface that breaks its own rules. If a host
needs a form near a trigger, the answer is `present`, not an anchored panel.

### Embedded content needs an explicit commit strategy

An embedded panel often has no footer, which leaves the primary action homeless. Two
legal answers, and the host must pick one deliberately:

1. **Give it an `ActionBar` region** of its own. The panel then behaves exactly like a
   dialog body and every contract holds unchanged.
2. **Commit each field on change.** Legal under §4.4 — each field *is* one-step — but it
   makes §4.2 non-negotiable: a field that saves silently and rejects silently is the
   worst behaviour in the system. Reserved message lines must report both the save and
   the rejection.

Mixing the two — some fields autosaving under a Save button — is not legal. The user
cannot tell which of their changes are already committed.

---

## 3.6 Theme first, build second

The framework has two jobs, and confusing them is how it doubles in size for no gain:

1. **Skin what HaxeUI already provides.** `Button`, `TextField`, `CheckBox`,
   `ScrollView`, `MenuBar`/`Menu`/`MenuItem`, `Slider`. These need tokens applied, not
   reimplementation.
2. **Build only what enforces a contract HaxeUI does not.** `RegionStack` exists because
   nothing upstream guarantees a frame that will not resize. `SwapSlot`, `HintLine` and
   `FieldHeader` exist for the same reason — each encodes a rule from §4 that is
   otherwise re-decided by hand at every call site.

**The test before writing a component:** name the contract it enforces. If there isn't
one, it is a skin.

`Tabs` is the one region that cannot be a skin. HaxeUI's `TabView` handles switching
perfectly well, but its tab labels take no custom renderer, so the per-tab error marker
(§4.3) has nowhere to go. `TabStrip` is therefore built — a strip of `ChoiceButton`-style
labels — and it owns `TabRole` (§3) and the marker. The page switching underneath it is not
new: it is the existing `SwapSlot` (a fixed-height, keyed `Stack`) holding one `ScrollView` per
page. The `Tabs` region stays thin: no content management beyond showing the active page.

---

## 3.7 One reflow mechanism, and `FieldGroup` — the container that uses it

Two fields side by side when expanded and stacked when collapsed is a recurring need —
player colour beside rated/unrated is the case that produced it. Several existing
components also change layout at the breakpoint, and **each must not implement its own
subscription.** Reflow is one mechanism, in two parts.

**1. `ByWidth<T>` plus one binder.** `ResponsivityController` gains the framework's only
breakpoint subscription:

```haxe
ResponsivityController.bind<T>(value:ByWidth<T>, apply:T->Void):Detachable
```

It applies the value for the current state immediately, re-applies it whenever
`isCollapsed` flips, and returns the handle to detach on disposal. Nothing else in the
framework calls `onCollapseChange` — that method becomes internal to the binder. Anything that
varies by breakpoint takes a `ByWidth` and passes it through `bind`: a row's direction, cells
per row, a region height.

**2. `FieldGroup` is the reflowing container.** Its `direction` becomes
`ByWidth<FieldGroupDirection>`; the doc's earlier `FieldRow` is `FieldGroup` configured as
`{expanded: Horizontal, collapsed: Vertical}` and is not a separate component. The host
declares one group with its children and never branches.

| | Expanded | Collapsed |
| --- | --- | --- |
| Layout | Side by side, percentage widths | Stacked |
| Labels | One shared header line | Each child keeps its own |
| Message lines | One per child, in a shared row | One per child, under it |

The shared header line and shared message row are behaviours of the horizontal
configuration; `FieldGroup` does not own `FieldHeader`/`HintLine` today, so they are added
when the first host (the create-challenge overlay) needs them — not before. The earlier
"stacks at expanded once the child count exceeds a threshold" rule is not automatic: the
caller says `Vertical` for the expanded state when a group has three or more controls.

The other consumers move onto the same mechanism:

- `ChoiceRow`'s `stackOnCollapse:Bool` becomes the same `ByWidth` direction, applied through
  the same binder.
- `ChoiceGrid`'s `perRow` becomes `ByWidth<Int>`; `ChoicesPerRow` is deleted.
- Region heights and other structural tokens (§6.1) are `ByWidth<Int>` already.

Both heights are the group's own business: it sums its children's declared field heights
and gaps from the token table. The host supplies no number.

What it must not do is wrap. Wrapping decides layout by measurement (§1.1) and produces
ragged half-wrapped states between the two states.

---

## 4. The contracts — the actual product

Components are replaceable; these are what make a HaxeFolio UI behave consistently. State
them once, at framework level, and have every component cite them.

### 4.1 Stability

- A component's height is a property of its **type**, not of its content. §4.2 exists to
  make that true: with the message line reserved, every instance of a field is the same
  height whatever its text, which is what lets containers sum heights without measuring.
- A fixed region whose content varies is **sized to its tallest variant** — within a
  breakpoint state. Across states, the two heights are simply different (§1). The scroll
  region is exempt (§1.1): its content is whatever size it is.
- A control that reflows between states declares a layout for each (§3.7). Reflow is
  never a consequence of measurement.
- Frames never resize in response to content.
- The scrollbar gutter is **always reserved**, so usable width is constant.
- Scrolling that reaches the end of the scrolling area **stops there**. It never continues
  into the page behind, however the user got to the end — wheel, drag or touch momentum. This
  is a property of the `ScrollView` treatment itself, so it holds for every tab page's own
  `ScrollView` as much as for a plain `Scroll` region.
- Multi-child rows size children in **percentages**, never pixels.

### 4.2 Reserved message lines

Every validated control reserves a fixed-height line for its message, present whether or
not there is a message. Valid: the constraint, muted. Invalid: the reason, in `danger`.
**Nothing moves between those states** — validation is a colour change, not a layout
change.

### 4.3 Visible blame

A blocked action must always show *what* is blocking it, within one interaction of the
user's attention:

- Field invalid → that field is marked.
- Field invalid on an unopened tab → **the tab is marked**, and the primary action is
  disabled.
- Never an error summary listing fields by name; never a disabled button with no cause.

This generalizes: any container that can hide an invalid descendant must be able to
display an error marker. `TabStrip` is the first case; a collapsible section or a wizard
step indicator is the next.

### 4.4 One-step commit

No control defers its effect. A preset click, a toggle, a stepper — all apply
immediately. The **one** exception is an explicit commit field (expensive validation,
free-text parsing), which must show a pending state in its own message line. Anything
else that needs confirmation is a design mistake.

### 4.5 Disable in place

A parameter that stops applying keeps its row, greyed, with the reason shown. Hiding it
moves the layout *and* conceals that the setting exists. The reason is stated once, by
whoever locks: a host that locks a whole section passes the reason to the section and does
not also lock its fields. This is a convention, not an enforced rule — there is no `Lockable`
type and no upward resolution; each component simply takes `locked` and `lockReason`
parameters and states the reason in its own header hint.

### 4.6 Fit by construction

No truncation is available, so every control with a known width states a character budget
and translators receive it. Budgets are measured at **collapsed** (§2.2), since the host
cannot know which frame it will get. Prefer a layout that
cannot overflow — stacking, wrapping, percentages — over a budget that might.

---

## 5. Layering

```
entry          present · embed          (Dialog · Sheet are private)
structure      RegionStack · Region · SwapSlot
regions        HeaderBar · Tabs (TabStrip + SwapSlot of page ScrollViews) · SearchBar · ActionBar · Toolbar
containers     FormSection · FieldGroup · PreviewPane
fields         ChoiceRow · ChoiceGrid · SteppedValueField · CommitTextField · ToggleButton
primitives     FieldHeader · HintLine · ChoiceButton · Stepper
model          FieldState<T> · HintState · EmphasisStyle · TabRole · ByWidth<T>
theme          stylesheet (colour · type) · Appearance (GeometryTokens · EmphasisStyle)
```

A layer may depend only on layers below it. The two rules that keep this honest:

- **No layer skipping.** A field never draws label text directly; it uses `FieldHeader`.
- **`ActionBar` is a region, not a footer.** The button-row model (percent widths,
  emphasis, disabled-loses-emphasis) is independent of where it sits, so a toolbar at the
  top uses the same component.

---

## 6. Themeability, in four classes

Not one axis. Hosts get this wrong because frameworks usually state only the first.

| Class | Examples | Consequence of changing |
| --- | --- | --- |
| **Free** | Colour tokens, radii | None, if the advisory floors hold |
| **Structural** | Region and field heights, paddings, gaps | Sums recompute automatically; vertical fit when collapsed must be re-checked |
| **Coupled** | Accent hue | May force `EmphasisStyle` to change with it |
| **Invalidating** | Font family | Every character budget must be re-measured |
| **Fixed** | The height arithmetic, the reserved-line rule, one-step commit | Not themeable; every other invariant rests on them |

### 6.0 Two override mechanisms, and the line between them

**The style engine owns appearance. Code owns values the framework computes with, and
semantic choices.**

Colour and typography stay in stylesheets, where hosts already override framework
defaults. They are consumed by the renderer, the cascade is the correct mechanism for
them, and duplicating them into a code struct would give hosts two ways to set one thing
— with the code path silently winning, which is the worst of both.

What cannot live in a stylesheet is anything feeding the height arithmetic. Region
heights, gaps and the reserved-line height are inputs to
`scrollHeight = frameHeight − Σ fixed` and are needed *before* layout. Reading them back
out of the style engine would make the arithmetic depend on cascade timing, and a host
that set `headerHeight` in CSS would get a header at the new size with the scroll region
still sized for the old one — a stability bug caused by the very mechanism meant to be
free.

```haxe
typedef Appearance = {
  geometry: GeometryTokens,   // the framework does arithmetic on these
  emphasis: EmphasisStyle     // a semantic choice components read, not a colour
}
```

`EmphasisStyle` sits on the code side despite looking like styling. It is not a colour;
it is *which treatment means primary*, and components must agree with each other on it —
`ChoiceButton` reads it and draws selections to match the footer, so filled chips under an
outlined primary button become impossible rather than merely discouraged. A stylesheet
can restyle both treatments; only code can say which is in use. **There is no CSS channel
for it**: the `haxefolio-emphasis-outlined` ancestor class the form components read today is
removed, and components take the value from the `Appearance` of the overlay (or embedded
panel) they are built into, falling back to the theme-wide one outside any.

For a colour difference in one overlay, the mechanism is the cascade, not a struct field.
The framework emits ids and classes for every overlay so a host's stylesheet can target it:
`#haxefolio-overlay-<slug>-frame`, `-header`, `-tabs`, `-scroll`, `-actions`, `-close`, plus a
fixed class per part (`.haxefolio-overlay-frame`, `.haxefolio-overlay-header`, …) and one per
presentation. `AppearanceOverrides` additionally carries an optional style class that the
framework puts on the overlay root, for a variant shared by several overlays.

So **geometry is the only thing a host overrides in code** — which is what makes §6.1's
two scopes coherent, while colour and type keep a third, older scope of their own.

```haxe
typedef AppearanceOverrides = {
  ?geometry: PartialGeometryTokens,
  ?emphasis: EmphasisStyle,
  ?styleClass: String
}
```

### 6.1 `GeometryTokens` — the structural override surface

Every constant the height arithmetic uses lives in one named table:

```haxe
typedef GeometryTokens = {
  headerHeight:    ByWidth<Int>,   // 60
  actionBarHeight: ByWidth<Int>,   // 68
  tabStripHeight:  ByWidth<Int>,   // 44
  searchBarHeight: ByWidth<Int>,   // 52
  fieldHeight:     ByWidth<Int>,
  messageLine:     Int,
  rowGap:          Int,
  padding:         Int
}
```

Every sum in the system reads from it, so an override propagates on its own — nothing is
recomputed by hand. Because the tokens are `ByWidth`, a host can raise header height when
collapsed alone for a larger touch target, which the old flat constants could not express.

Overrides arrive at two scopes, both partial:

- **Theme-wide**, when the host constructs its theme. The default and the right place for
  a house style.
- **Per overlay**, inside the optional `AppearanceOverrides` argument to `present` /
  `embed` (§2). For the one overlay that legitimately differs — a compact confirmation, a
  header that must carry a subtitle.

Both scopes also carry `emphasis`. Advice, unenforced: overriding emphasis per overlay is
reasonable; overriding colour per overlay almost never is — an overlay in different
colours reads as a different application.

What neither scope permits is a per-call-site *number* on an ordinary field. The reason
heights were kept out of host code was never that the values are sacred; it is that
per-call-site values diverge, and an application whose dialogs have four different header
heights looks broken. A table override cannot cause that, which is what makes it safe.

### 6.2 Two colour rules, advised and unenforced

The framework checks neither of these. Both are stated because a host that breaks them
produces an overlay that looks wrong for reasons that are hard to diagnose from the
symptom.

1. **Keep the contrast floor.** Every text-on-surface pair should stay above 4.5:1. The
   default tokens sit well clear of it precisely so a hue shift does not break them.
2. **Keep the elevation direction.** `surfaceDeep` ≥ `surface` > `surfaceSunken`, with
   the host's page background below `surface`. A page lighter than the overlay makes the
   overlay read as inset rather than floating — the scrim helps, but lightness is what
   actually carries it.

The coupled case is the interesting one and the one to document loudly: an accent that
falls inside the host's content-imagery hue family cannot use filled selections, because
a filled chip then reads as a piece of content. That is one decision with two outputs,
and hosts will otherwise change half of it.

---

## 7. What should *not* be generalized

Resisting these is as important as building the rest.

- **Content rendering.** Board widgets, charts, avatars. The framework offers
  `PreviewPane` — a fixed-size hole with a caption — and knows nothing about what goes
  in it.
- **Domain validation.** SIP parsing, password policy, login availability. Hosts supply
  predicates; the framework supplies the *display* of their results.
- **Taxonomies and their icons.** Time-control kinds, rating classes, badge tiers. The
  framework sees `ImageRef` and `String`.
- **Policy.** "Rated games use the default position" is a host rule expressed through
  the `locked` / `lockReason` parameters, not a framework feature.
- **Copy.** Including the message strings in reserved lines.

The dividing line, stated once: **the framework owns stability, states and spacing; the
host owns meaning.**

---

## 8. Build order and status

Most of the form layer was built ahead of the overlay work, following the plan in
@knowledge/past_decisions/form-components.md.

**Already built** (`haxefolio.form`, `haxefolio.form.plumbing`): `FieldHeader`, `HintLine`,
`HintState`, `FieldState<T>`, `ChoiceButton`, `ChoiceRow`, `ChoiceGrid`, `SwapSlot`,
`FieldGroup`, `FormSection`, `PreviewPane`, `Stepper`, `SteppedValueField`, `IntField`,
`DurationField`, `CommitTextField`, `ToggleButton`, `EmphasisStyle`.

Several of those need rework to match this document, and are folded into the steps below:
`ChoiceRow`, `ChoiceGrid` and `FieldGroup` (subscribe to the breakpoint individually today, §3.7),
`EmphasisStyle` / `ChoiceButton` / `ToggleButton` (select emphasis through a CSS class, §6.0),
and `SwapSlot` (its `height` is constructor-only; it must become settable so `RegionStack` can
push `scrollHeight` into it, §2.1).

**Package layout.** `SwapSlot` has moved to `haxefolio.structure`, the package for the §5
structure layer; `RegionStack` and `Region` land there too. The rest stays as it is:
`haxefolio.form` (containers and fields), `haxefolio.form.plumbing` (primitives and model
types), `haxefolio.overlay` (`present`, the presentations, the regions). `haxefolio.form` is
not cluttered enough to split yet.

**Still to build, in order:**

1. `ByWidth<T>` and `ResponsivityController.bind` (§3.7); migrate `ChoiceRow`, `ChoiceGrid` and
   `FieldGroup` onto them; delete `ChoicesPerRow` and the `stackOnCollapse` flag. Nothing in
   the overlay work depends on the old shape, and everything after this assumes `ByWidth`.
2. `GeometryTokens` and `Appearance` (§6); move `EmphasisStyle` to the code side and remove the
   CSS-class channel, updating `ChoiceButton` and `ToggleButton` to read it.
3. `RegionStack` + `Region` — the height arithmetic and the table it reads from. Includes making
   `SwapSlot.height` settable, and the shared `ScrollView` treatment (reserved gutter,
   scroll-stops-at-end) that the plain `Scroll` region and every tab page use.
4. `present` with both private presentations, built from scratch on the mechanics §9 keeps;
   the old overlay classes and `showOverlay` are deleted in the same step. The new close
   control and Esc dismissal land here. `embed` after.
5. `HeaderBar` (including the close control), `ActionBar` — the two regions every composition
   uses.
6. The `Tabs` region with both roles: `TabStrip` (the label row) plus the `SwapSlot` of page
   `ScrollView`s. Needs the error-marker contract (§4.3) to exist first, and is a build rather
   than a skin (§3.6).
7. Rebuild `showPreferences` on `present` (§9): header, tabs, footer — and restyle the window
   and everything inside it to the theme, retiring its bespoke CSS (§9.1). Needs steps 4–6.
8. `SearchBar`, `Toolbar`, `StepIndicator` — only when a real case demands them.

Step 8 is the discipline: a region that nothing yet needs is a region specified from
imagination. Build it when the second host asks.

**Not scheduled, but owed:** the menu bar and the side bar still carry their original styling
(the `.haxefolio-menubar`, `.haxefolio-site-name-label`, `.haxefolio-sidebar-*` rules and the
hard-coded colours/fonts in `main.css`) and have not been brought onto the theme. They must be
revised later according to @knowledge/plans/haxefolio/haxefolio-theme.md — colour tokens,
typography scale, and geometry — the same way the overlay chrome and form components already
follow it. Until then they visibly disagree with the overlay frame that now sits over them.

---

## 9. Replacing the old overlay system

What the new system takes over, what it keeps, and what it deletes.

**Replaced.**
- `HaxeFolioApp.showOverlay` → `HaxeFolioApp.present` (§2). `showPreferences` becomes a
  `present` call.
- `OverlayContent` (a `VBox` subclass with `addDetachable`/`dispose`) → the
  `{title, regions, ?onDismissed}` typedef of §1; the teardown hook takes over the detachable
  lifecycle.
- `ModalOverlay` and `SideBarOverlay` → the private `Dialog` and `Sheet` presentations.

**Kept, as mechanics rather than code.**
- Dialog when expanded, sheet when collapsed, chosen from `ResponsivityController.isCollapsed`
  at the moment of presenting; a separate content factory for collapsed (`mobileContentFactory`).
- Sheet: a bottom `SideBar` with `method = "float"` covering the whole viewport, with its own
  full-screen backdrop present for the entire show → hidden window and torn down only on
  `UIEvent.HIDDEN`, not on `hide()`; sized from a live DOM measurement instead of `Screen`'s
  cached size, and re-measured off the debounced resize signal.
- A no-op when an overlay is already open, and force-dismissal of an open overlay when the page
  changes (browser back/forward, programmatic `navigateTo`).
- The `dismiss` handle passed to the content factory.

**Deleted.**
- Everything close-button related: `OverlayCloseButton`, `OverlayLayout` and the
  `showCloseButton`, `closeButtonSize`, `closeButtonInsetX`, `closeButtonInsetY` parameters. The
  close control is built from scratch as part of `HeaderBar` (§2).
- The `width` / `height` parameters: the frame size comes from the presentation (§1, §2.1).
- The desktop modal's non-blocking behaviour — scoped to the page container, no backdrop,
  with the `recursivePointerEvents` workaround. `Dialog` is modal with a scrim (§2).
- `ChoicesPerRow`, `ChoiceRow`'s `stackOnCollapse` flag, and every direct
  `onCollapseChange` subscription in form components (§3.7).
- The `haxefolio-emphasis-outlined` CSS class selection (§6.0).
- The preference window's autosave notice (`PreferenceAutosaveNoticeLabel`) — dropped outright,
  not moved.

**Rebuilt: the preference window.** `PreferenceWindowBuilder` composes
`Header(title)` + `Tabs(Navigate, pages)` + `Actions(footer)` instead of a
bare `TabView` plus an ad-hoc footer `HBox`. The reset button moves into the `Actions` region;
the autosave notice is dropped. `preferenceTabIcons` keeps working as the tab labels' icons. The
window is `Navigate` per §3: one shared footer, state that persists across tabs; each preference
applies immediately (§4.4), so the footer hosts Reset rather than a Save.

### 9.1 The preference window: transition and styling

The preference window is the first real consumer of everything above, and the one built-in
composition — so it is both the proof that the region model carries a real case and the place
where any leftover of the old system would show. It moves over **in full**: not "a `present`
call wrapping the old body", but a window whose structure, controls and styling all come from
the new system. Nothing of it may keep depending on `TabView`, the old overlay classes or the
`.haxefolio-preference-*` stylesheet rules after step 7.

**Transition — what has to change.**

- **`showPreferences` is a `present` call** with slug `"preference"`. `PreferenceWindowBuilder`
  stops returning an `OverlayContent` and returns the composition of §1 — `{title, regions,
  ?onDismissed}` — so it must be reworked, not merely re-typed. Every `Preference.onChange`
  `Detachable` the rows register moves onto the composition's teardown hook, which replaces
  `OverlayContent.addDetachable`; none may leak past dismissal.
- **Structure.** `Header(title)`, then `Tabs` in the `Navigate` role (§3), then `Actions`. Each
  tab page is a `ScrollView` inside the shared `SwapSlot`, so the window keeps a fixed frame
  and per-tab scroll offsets. The `TabView` and the ad-hoc footer `HBox` go away.
  `HaxeFolioConfig.preferenceTabIcons` keeps working, now as the icons on the `TabStrip`
  labels.
- **Footer.** Reset only. The preferences are *all* autosaved, which is what makes the footer
  legal at all: §3.5 forbids autosaving fields under a Save button, and the window has no Save
  — every control applies on change (§4.4). Nothing may be added that would reintroduce a
  mixed state, such as a "Save & Close". The autosave notice stays dropped (§9, Deleted).
- **Modal, sized by the presentation.** The window is now a modal dialog with a scrim on
  expanded and a sheet on collapsed (§2) — no longer a non-blocking box beside a live menu bar.
  This is an accepted behaviour change and must be called out in the README. Its size comes
  from the presentation's geometry (§2.1, §3 of the theme), so the `480x360` / `520x400`
  defaults of `#haxefolio-overlay-preference-modal` are deleted rather than ported.
- **Cross-tab reactions still work.** A preference changed from another browser tab fires the
  same `onChange` handlers as before, so the rows must keep rendering from `Preference.get()`
  and updating on the handler — the composition must not snapshot values at build time.
- **Contracts apply to it like to any other composition.** In particular §4.1: switching
  tabs, pressing Reset, or a locale change re-wrapping a label never moves the frame or another
  region; §4.6: every label and value-button caption fits its slot **in every shipped locale**
  (the sample ships `en` and `ru`; a Russian caption is the usual first overflow), against the
  character budgets of `haxefolio-typography.md` §4, since there is no ellipsis to fall back on.
- **Locale keys.** `Header` needs a localized title, so a new key joins the `Locale keys`
  table and every shipped locale file. Keys whose element is dropped or replaced
  (`haxefolio.preference.autosave_notice`, and any per-control key a rebuilt row no longer
  reads) are removed from the table in the same change.
- **Documentation.** The README's `Overlays`, `Preference window` and `CSS classes and elements`
  sections describe the old system and are rewritten together with the code (project rule:
  the README is never left outdated). The preference window's supported customization points
  are listed there explicitly — see the open question below.

**Styling — what it must end up as.** The window is styled by the theme
(@knowledge/plans/haxefolio/haxefolio-theme.md), and by nothing of its own: no colour, font
size, weight, radius or spacing that the theme already defines may be re-declared for it.

- **Chrome from the region chrome.** The header, its close control, the footer hairline and
  opaque fill, and the scrollbar are the theme's region chrome (theme §4, §4.1) exactly as
  every other overlay gets them, with no preference-specific override. The title is the
  17 px / 600 `ink` dialog title of the type scale.
- **Tabs from `TabStrip`.** Tab labels are the `ChoiceButton`-style labels of §3.6, in the
  `Navigate` (underlined, flush) treatment; the icons from `preferenceTabIcons` sit inside them
  at the size the strip defines. The old `#haxefolio-preference-tabview .icon` rule has no
  successor unless the strip needs one.
- **Controls from the form layer.** Rows are composed from `haxefolio.form` (`FieldHeader`,
  `ChoiceRow`, `FormSection`, and so on) instead of the bespoke row `HBox` with a fixed-width
  name label and a hand-styled `Button` per option. That gives them the field-label scale
  (12 px / 500 `inkMuted`), the `EmphasisStyle`-driven selected state (§6.0) and the
  disabled-in-place behaviour (§4.5) for free, and removes the preference window's own private
  idea of what a selected option looks like. Where a preference is genuinely a boolean, the
  control follows the ToggleButton-versus-checkbox guidance in the README (a mode versus an
  attribute), rather than the current slider by default.
- **Reset is a plain button.** With no primary action in the footer, Reset is not emphasized —
  it is an ordinary HaxeUI `Button` given the opt-in `haxefolio-button` class (unselected
  `ChoiceButton` treatment; plain buttons are not restyled automatically); it must not be given
  `EmphasisStyle.Filled`, which would present a destructive secondary action as *the* action to
  take.
- **Selectors.** The `.haxefolio-preference-*` rules in `main.css` (`-tab`, `-row`,
  `-name-label`, `-option-*`, `-toggle`, `-footer`, `-reset-button`, `-autosave-notice`) and
  `#haxefolio-overlay-preference-modal` are deleted, except any that survives the test of §3.6 —
  it names a contract the theme cannot express. What remains is the per-overlay ids/classes
  every overlay gets from §6.0 (`#haxefolio-overlay-preference-frame`, `-header`, `-tabs`,
  `-scroll`, `-actions`, `-close`), which are how a host restyles this window by colour or type.
- **Colour, type and geometry follow the two mechanisms of §6.0.** A host recolours the window
  through the cascade; changing its structural values goes through `AppearanceOverrides`, and
  the height arithmetic re-sums automatically.

**Open questions — to decide when step 7 is designed, not assumed here.**

1. **Preference kind → component.** The mapping for `toggle`, `option` and `locale` is not
   fixed by this plan (see the toggle guidance above; `option`/`locale` look like `ChoiceRow`,
   but a preference with many values — a long locale list — would need `ChoiceGrid` instead,
   and the choice should be made from the value count, not per call site).
2. **Per-window appearance override.** `present` takes `?appearance` (§2), but `showPreferences`
   currently takes no arguments. Either it gains an `AppearanceOverrides` parameter (or a
   `HaxeFolioConfig` field) so a host can change the window's geometry or emphasis, or the
   window is themable only theme-wide plus the cascade. Both are defensible; the second is
   simpler, the first is consistent with every other overlay.
3. **Title text and any per-tab title.** `Navigate` fixes the frame title (§3), so a single
   localized key is enough — confirm no per-tab heading is wanted before adding keys.
