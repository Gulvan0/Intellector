# Challenge notification cleanup - plan

Goal: `client.ui.common.notifications.challenges` classes keep behaviour only; layout and styling
move to XML/CSS, and what CSS can't express moves into one constants class.

## 1. HaxeUI: `clip: true` and rounded corners

haxeui-html5's `ComponentImpl.handleClipRect` clips with the CSS `clip: rect(...)` property even when
the rect is the whole component (`style.clip == true`, no explicit `componentClipRect`). That
property is always rectangular (ignores `border-radius`) and also cuts the element's own
`box-shadow`. Repro: `knowledge/haxeui_clip_border_radius_repro.xml`.

Proposed fix (needs approval, haxeui-html5 fork): whole-box clip -> `overflow: hidden` on the
element; sub-rect clip (scrollers) unchanged. Then `.intellector-challenge-facts { clip: true; }`
replaces `facts.element.style.overflow = "hidden"`.

## 2. HaxeFolio: typed shadows

- `ElementShadow.apply(element, shadow:Shadow)`, `Shadow` = `{offsetX, offsetY, blur, ?spread,
  color:Int (0xRRGGBB), opacity:Float}`; the string form goes.
- HaxeFolio's own shadows (`NotificationCard`, menu bar, side bar, overlays) become one
  `ShadowTokens` group in `Appearance`, overridable by the host like the geometry tokens.

## 3. HaxeFolio: breakpoint class on the roots

`ResponsivityController` keeps `haxefolio-collapsed` / `haxefolio-expanded` on every
`Screen.instance.rootComponents` member (app root, notification layer, overlays, side bar, menu
dropdowns). HaxeUI doesn't restyle descendants when an ancestor's class changes, so a flip also
invalidates the style of each root's subtree. Roots added later get the class when HaxeFolio adds
them. CSS: `.haxefolio-collapsed .intellector-challenge-row { height: 44px; }` etc.

`NotificationCard`'s own `-collapsed` class and binding move to the same mechanism.

## 4. HaxeFolio: anchor utility

`haxefolio.Anchoring.attach(floating, anchor, placement:ByWidth<AnchorPlacement>):Detachable`

- `AnchorPlacement` = `{side: Left|Right|Above|Below, align: Start|Center|End, ?stretch:Bool}`;
  `stretch` matches the anchor's extent along the side (the mobile full-width preview).
- `floating` is a child of `anchor`'s coordinate space, excluded from layout; the caller inserts it
  (`NotificationCard.attach` for a card, `addComponent` otherwise).
- Gap = `floating`'s CSS margin on the side facing the anchor.
- Re-places on either component's size change (ResizeObserver) and on the breakpoint flip.
- `MovePrompt` stays as is: its ring is radial and its popover is anchored to a board point.

## 5. Intellector: constants

`client.ui.Styles` - every style value Haxe code still needs: the app's shadows (row, preview
popover, both `MovePrompt` ones), the host overrides of HaxeFolio's `ShadowTokens`, the stack's
expanded width.

## 6. Intellector: the package

- `ChallengeCompactRow`: `pointer-events: true` in CSS (HaxeUI's own `:hover`/`:down` + pointer
  cursor); arrival highlight = `@keyframes` + `animation-name` on an `-arrived` class.
- `PreviewToggle` removed: `<button toggle="true">` in the card XML, `:down` style.
- `ChallengeCard`: preview button declared in XML; placement via `Anchoring`.
- `ChallengeNotificationStack`: own XML layout (spacing, row box); no `collapsed` constructor
  arguments or rebuild on the breakpoint flip - the row limit is the only breakpoint-dependent
  behaviour left, through `ResponsivityController.bind`.
- `PositionPreviewPopover`: board width in XML; only the aspect-ratio height in code.
- Comments and docstrings: drop the obvious, cut the rest to what has to be stated.

`TimeControlTag`/`PositionPreviewPopover` relocation (earlier point 5) and the stack's state/view
split (points 1, 3, 4) are separate steps, not part of this one.
