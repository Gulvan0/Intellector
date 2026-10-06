# Incoming challenge notification - implementation plan

Implements the design spec [[challenge-notification]]. Decisions taken with the user before
implementation:

- **No HaxeUI `NotificationManager`.** Its template (title/close/rule/icon/text body), 300 px height
  cap, add/remove-only repositioning and app-wide singleton layout don't fit. A generic notification
  layer is added to HaxeFolio instead, covering only what every notification shares; layouts are the
  host's.
- **Correspondence time string** is Onest 13 / 500 (the spec's "Archivo" is a slip; the theme allows
  only Onest and IBM Plex Mono).
- **Several challenges from one caller are shown separately** (the server allows up to
  `max_same_callee_active_challenges` of them, each with its own id, each accepted on its own).
  The spec's "replace in place" rule is not implemented.
- **Time-control kind icons:** the old repo's coloured set (`assets/symbols/time_controls`, all six
  kinds), ported to `assets/images/common/time_controls`.
- **Board preview:** a bare `BoardSurface` (the "mini-board" of the spec).
- **Refresh semantics:** every pending challenge this tab hasn't announced yet raises a notification
  (on a fresh load - all of them; after a reconnect - only new ones). Hidden ones stay hidden for the
  session; challenges missing from a refresh are removed.
- **Spacing of the notification layer:** 12 px from the viewport edges in both layouts, 10 px between
  separate notifications.

## 1. HaxeFolio: notification layer

`haxefolio.notification`:

- `NotificationLayer` (framework-internal): a `VBox` added to `Screen` by `HaxeFolioApp.init`, after
  the app root, so overlays and the side bar (added to `Screen` when shown) paint above it. Holds
  notifications in the order they were shown; the newest is closest to the anchor (bottom).
  - Expanded: anchored to the bottom-right corner, 12 px from both edges; each notification keeps its
    own `expandedWidth`, right-aligned.
  - Collapsed: every notification is `viewport width - 24` wide, 12 px above the bottom edge.
  - Re-anchors on: show/dismiss, any change of its own height (a notification's content changing
    size), the debounced viewport resize, and the breakpoint flip.
  - Hidden while empty. Made inert together with the app root while an overlay or the side bar is
    open (it is part of "the app beneath"), via the existing `InertHolds`.
- `Notification`: the handle `HaxeFolioApp.notify` returns - `dismiss()` (idempotent) and `isShown`.
- `HaxeFolioApp.notify(content:Component, expandedWidth:Float):Notification`.

No frame on the layer itself, no auto-expiry, no animation: a notification may be several cards (the
challenge stack is), and nothing in this iteration needs expiry.

- `NotificationCard`: the parts most notifications share, as an optional building block - surface
  frame, header (optional caption over a title, a close control once `onClose` is set), body, and a
  row of `ActionButton`s split evenly. Follows the breakpoint by itself (a `-collapsed` class for the
  close control's 44 px hit area; buttons take the `fieldHeight` token). Usable from XML: children go
  into the body, `<action-button>`s into the action row. `attach`/`detach` add a component outside
  the card's layout, positioned relative to it (`includeInLayout = false`) - e.g. a popover.
- `ActionButton` can be declared in XML: every constructor argument optional, `primary` a property.
  Both components are registered in HaxeFolio's `module.xml`.

README: new "Notifications" section; reference entry for the layer's CSS id/class.

## 2. Intellector: data

- `client.datatypes.ChallengeSide` (`White`/`Black`/`Random`) - the colour the challenged player gets.
- `client.datatypes.IncomingChallenge` - id, caller login + nickname, `TimeControl`, `TimeControlKind`,
  rated, `ChallengeSide`, `Null<Position>` custom starting position.
- `net.models.challenge.mappers.IncomingChallengeMapper.dtoToDatatype(ChallengePublic)`.
  `acceptor_color` *is* the recipient's colour (server: `assign_player_colors`), so no inversion.
- `Assets.timeControlKindIcon(kind)`, `Assets.colorIcon(side)` (the original iteration's colour rings:
  hollow White, filled Black, half-filled Random).

## 3. Intellector: UI (`client.ui.common.notifications.challenges`)

- `ChallengeNotificationStack` - the one notification shown through `HaxeFolioApp.notify` while any
  challenge is on display; owns the state of spec §5: arrival-ordered entries, the active one, the
  hidden ids, the per-breakpoint row limit (3 / 1), the arrival highlight, the single open preview.
  Exposes `add`, `remove`, `sync(pending)`, `closeAll`, and takes `onAccept(id)`, `onDecline(id)`
  callbacks. Builds, from top to bottom: `ChallengeStackBar`, `ChallengeCompactRow`s,
  `ChallengeCard`.
- `ChallengeCard` - a `NotificationCard` holding the 2×2 fact grid, spec §1-§2; fixed height because
  every grid row has one.
- `ChallengeCompactRow` - spec §5.1, with the mobile count pill.
- `ChallengeStackBar` - spec §5.3; count with plural forms as HaxeUI locale expressions (`intellector.challenge_notification.count`).
- `PositionPreviewPopover` + the Preview toggle - spec §3; the popover sizes itself and is attached
  to the card (`NotificationCard.attach`), so it follows the card: left & bottom-aligned on desktop,
  above on mobile. The card places it by its laid-out size.
- `TimeControlTag` (kind icon + string) - shared by card and row; an XML component (`<time-control-tag>`,
  registered in `src/module.xml`).

Every one of these has its structure in an XML layout under `assets/layouts/common/notifications/`;
the classes fill in values and handle behaviour. Sizes that differ per breakpoint are CSS on a
`-collapsed` class. Styles in `assets/styles/main.css` (`intellector-challenge-*`, plus the theme's
colours for `haxefolio-notification-card-*`), strings in both locales (`intellector.challenge_notification.*`).

## 4. Wiring (`Main.hx`)

- On every identity change: drop the previous `IncomingChallenges` subscription and the stack's
  content; subscribe for the new identity (`login`, or `_<guestId>` for a guest with a known id).
- `IncomingChallengesRefresh` -> `stack.sync`; `IncomingChallengeReceived` -> `stack.add`;
  `IncomingChallengeCancelled` / `IncomingChallengesCancelledByServer` -> `stack.remove`.
- Accept -> `ACCEPT_CHALLENGE` -> `navigateTo('live/<game id>')`; Decline / Decline all ->
  `DECLINE_CHALLENGE` per id. Buttons of a challenge whose request is in flight are disabled.

## 5. Verification

Build with `haxe build.hxml --debug`; in the browser (127.0.0.1:5500, server on 8443): create direct
challenges to the logged-in player from a second identity via REST and check arrival, highlight,
ordering, row limits, bar, preview, Decline/✕/Accept/Decline all/Hide all, withdrawal, and both
breakpoints.
