# Challenges widget - implementation plan

Implements [[challenges-widget]] and the icon handoff (two arrows, see §3 below). Deferred items:
[[challenges_widget_deferred]].

## 1. Decisions

- The trigger and dropdown are a new generic HaxeFolio component, `haxefolio.menu.DropdownWidget`.
- Trigger: 44 px square target with a 24 px icon on both breakpoints (the icon handoff wins over
  the spec's narrow 30 px image). Badge 3 px from the top and 2 px from the right of the target.
- The widget sits in the right group of the menu bar, before Account, as a persistent widget.
- Wide dropdown: 372 px, right-aligned to the trigger, 6 px under the bar (same gap as narrow),
  `max-height` = viewport - bar - 24 px. Narrow: viewport - 12 px each side, 6 px under the bar, down
  to 12 px above the bottom edge.
- The dropdown closes on: trigger click, outside pointer press, Esc, breakpoint flip, navigation, an
  overlay being presented, the side bar opening, and an Accept anywhere.
- Outgoing accepted by the other side: the entry leaves; the app fetches the challenge
  (`GET_CHALLENGE`) for `resulting_game` and navigates to `live/<id>`, unless an ongoing
  non-correspondence game is open (stubbed to "never"), in which case a "game started"
  notification would be shown (deferred).
- Challenges arriving while the dropdown is open never raise a notification, not even after it
  closes; they count as announced.
- The facts wrap onto a second line when they don't fit in the entry width minus the Preview button
  and its gap; the button stays right-aligned on the first line and the entry grows taller. Each
  separator dot travels with the fact after it.
- Preview titles: "Position from <nickname>" (incoming), "Your challenge to <nickname>" (direct
  outgoing), "Your open challenge" (open outgoing).
- The badge uses the medium mono weight (500): no 600 mono is bundled.
- The incoming arrow is accent while there is an incoming challenge the user hasn't seen since the
  dropdown was last opened; opening it clears that.

## 2. HaxeFolio: `DropdownWidget`

`haxefolio.menu.DropdownWidget extends Box` - the trigger, given to `Widget(factory, true)`.

- `new(icon:Component, content:Component, expandedWidth:Float)`; `setBadgeCount(count)` (hidden at
  0); `setAccessibleName(name)` (`aria-label`); `open()`, `close()`, `isOpen`, `onOpened`,
  `onClosed`; `attach(component)`/`detach(component)` for things outside the frame's layout (placed
  with `Anchoring`); `setCover(component)` for a panel covering the top of the frame at its width.
- The frame is a Screen root added on open (marked with the breakpoint class), the menu dropdown
  shadow token, and a `ScrollArea` around `content` sized to `min(content height, max height)`.
- `DropdownWidget.closeOpen()` is called by `HaxeFolioApp.switchToPage`, `OverlayController.present`
  and `SideBarController.open`.
- Styling: `.haxefolio-dropdown-widget` (+ `-open`), `-badge`, `-frame`; README section.

## 3. Intellector: data

- `client.datatypes.OutgoingChallenge` (callee null for an open challenge; `ownColor` is the user's
  colour - the opposite of the acceptor's) and `OutgoingChallengeMapper`.
- `ChallengeQueue` keeps only what's on display in the notifications; the acceptance lock moves out;
  `skip(id)` marks a challenge announced without showing it.
- `client.datatypes.ChallengeInbox` - the single source of truth: pending incoming and outgoing,
  the notification queue, the acceptance lock, the unseen flag. Unit-tested.

## 4. Intellector: UI

- `client.ui.common.challenges`: `ChallengesController` (replaces `IncomingChallengesController`;
  owns the inbox, the notification stack and the widget, enforces one preview at a time),
  `TimeControlTag` and `PositionPreviewPopover` (moved from the notification package; the popover
  gains an optional title and close button).
- `client.ui.common.challenges.widget`: `ChallengesWidget` (wraps `DropdownWidget`),
  `ChallengesIcon` (two-arrow SVG), `ChallengeList` (sections, empty lines), `ChallengeEntry`
  (incoming/outgoing rows, actions, preview toggle).
- Layouts under `assets/layouts/common/challenges/`, styles in `main.css`, locale keys
  `intellector.challenges_widget.*`.

## 5. Intellector: wiring (`Main`)

- Subscribe to `OutgoingChallenges` alongside `IncomingChallenges`: refresh → `syncOutgoing`,
  rejected / cancelled by server → `removeOutgoing`, accepted → remove + fetch + navigate.
- Cancel challenge → `CANCEL_CHALLENGE`; Accept/Decline as before, from either place.

## 6. Verification

Unit tests for `ChallengeInbox`/`ChallengeQueue`; in the browser (test hook): badge and icon states,
sections and empty lines, ordering, Accept/Decline/Cancel from the widget, Accept closing everything,
suppressed notifications while open, arrival highlight, wide/narrow placement and scroll, previews
(wide popover, narrow cover, one at a time).
