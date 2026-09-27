# Login overlay — implementation plan

Implements the content spec in `login-overlay.md` ([[login-overlay]]). Decisions taken with the
user before implementation (2026-09-27):

- **Frame size is per-overlay, via haxefolio.** The dialog presentation's preferred size becomes two
  geometry tokens, so a host overrides it theme-wide or per overlay through `AppearanceOverrides`.
- **Both new building blocks go into `haxefolio.form`**: a live-validated text field and a checkbox
  row. Both are generic; the login rules stay in Intellector.
- **Both §7 proposals are accepted**: fixed "Account" title (pages carry no `title`), and tabs lock
  while a request is in flight (a new host-held `TabLock`, passed to `Region.Tabs`).

## 1. haxefolio additions

| Addition | Where | Notes |
| --- | --- | --- |
| `dialogWidth` / `dialogHeight` tokens | `GeometryTokens`, `PartialGeometryTokens`, `AppearanceContext` | Defaults 620 / 720. `OverlayController` resolves them under the overlay's own `appearance` and hands them to `DialogPresentation`. The 420 floor becomes `min(420, dialogHeight)`. |
| `TabLock` | `haxefolio.structure` | Observable flag like `ErrorMarker`. `Region.Tabs` gains `?lock:TabLock`; `TabStrip` ignores clicks and carries `.haxefolio-tab-strip-locked` while it is locked. |
| `TextInputField` | `haxefolio.form` | `FieldHeader` (label + one hint slot) over a `TextField`. Host sets `hint`/`hintState`/`invalid`/`enabled`; the field reports edits through `onText` and Enter through `onSubmit`. Its height is the `fieldHeight` token (the token's first consumer). `focus()` focuses the native input, because HaxeFolio disables `FocusManager`. |
| `CheckBoxRow` | `haxefolio.form` | A box and a caption in one row that is entirely clickable, `fieldHeight` tall. The on state follows `selectionEmphasis`. It is keyboard reachable (`tabindex`, Space/Enter). |

## 2. Intellector

- `Main.hx`: `setAppearance` adds `geometry: {fieldHeight: {expanded: 37, collapsed: 44}}` (theme §5.2/§5.4).
- `LoginOverlay.present()`: `HaxeFolioApp.present("login", build(false), build(true), {geometry: {dialogWidth: 430, dialogHeight: 486}})`
  (413 since §5).
  One factory serves both presentations (the page is never fixed-height).
- `LoginForm` (one per tab): fields in a VBox (spacing 14), then 18 px below them the checkbox and the status line.
  It owns its validation state (`attempted`, per-field `hadContent`, `takenLogin`) and reports
  `onStateChange` so the overlay can refresh the shared primary button.
- `LoginValidation`: pure functions returning the first failing rule's slug per spec §3.
- `LoginOverlay` owns the shared primary `ActionButton`, the `TabLock`, and the cross-tab behaviour:
  it carries the Login value, clears both status lines, and focuses the first empty field.
- Deleted: `TextFieldInputBox` (+ layout), `ValidatorRegistry`, `login_form.xml`. `LoginFormField` loses `restrictChars`.
- Locale: keys rewritten to spec §5; old `error.*` keys replaced.

## 3. Found during implementation

- **ScrollArea contents padding (haxefolio fix).** HaxeUI's ScrollView added 5px padding around every
  scroll area's content (the side bar already cancelled it), which overflowed the 314 page by 10px.
  In addition, `percentContentWidth` resolved against the full width, so the 10px lane was drawn over
  the content's right edge. Contents now get `padding: 0; padding-right: 10px`. This also moves the
  preference window's content by those pixels.
- **Focus state (haxefolio).** HaxeUI's `:active` on text fields depends on the disabled FocusManager, so
  `TextInputField` tracks DOM `focusin`/`focusout` and sets `.haxefolio-text-input-focused` instead.
- **Header row height.** `TextInputField`'s header is fixed at `messageLine` (16); the natural height was 18.
- **Content width is 386, not 376** (confirmed by the user; spec §1 corrected).
- **Bottom block no longer pinned** (user decision, 2026-09-27): "Remember me" follows the last field at
  18 px and the page takes its natural height, so Log In's spare height falls at the bottom. The page
  is no longer fixed-height anywhere, so the dialog and the sheet share one content factory.
- **Each tab's "Remember me" is independent** (user decision): it does not carry across tabs.

## 4. Verification

Build with `haxe build.hxml --debug`, then test on `127.0.0.1:5500`: frame 430×486; both tabs'
bottom block at the same Y; hint and error states per field; primary disabled rules; Enter reveals
all errors; in-flight lock; server errors routed (status vs Login hint); status clears on edit and
on tab switch; Login carried across tabs; sheet at narrow width.

## 5. Spec follow-up

All three open items accepted (user decisions: eye icon, on both tabs, Caps Lock notice wins over
the error while focused):

- **haxefolio.** `TextInputField`'s `password:Bool` became `mode:TextInputMode` (`Plain`/`Password`/
  `RevealablePassword`). The reveal toggle is `form.plumbing.PasswordRevealButton`, a square lane as
  tall as `fieldHeight`, over the input's right edge. The input's right padding equals the lane. Its glyph is inline
  SVG in `currentColor`, so `.haxefolio-password-reveal`'s `color` paints it per state, with no
  image per colour. Its accessible name comes from host keys `haxefolio.text_input.reveal.show`/`.hide`.
  `TextInputField` also reports `capsLockOn` / `onCapsLockChange` (key and pointer events, `false`
  on blur). The host decides what to say.
- **Intellector.** Repeat password removed (field enum, validation, fine hints, five locale keys per
  language). Both tabs have Login + revealable Password, so the page is 241 and the dialog **413**.
  `LoginForm.refresh` puts `hint.caps_lock` into the Password slot while `capsLockOn`, keeping `invalid`.
- **Docs.** Checkbox spec moved to `intellector-style.md` §5.5; reveal toggle specced in §5.3.
- Verified at `127.0.0.1:5500`: frame 430×413; toggle reveals/hides, focus and caret kept, hover `ink`;
  Caps Lock notice (synthetic event) over "At least 6 characters", error back on blur; lane 44×44 at
  the collapsed breakpoint.
