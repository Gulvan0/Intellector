# Challenges widget

Companion to the incoming challenge notification spec; it reuses that spec's fact vocabulary, Preview button and popover, and the existing theme, menu-bar widget and dropdown components. References are by name.

A **persistent** menu-bar widget listing every pending challenge, incoming and outgoing.
It is the permanent home of what the notifications announce: a hidden notification is
still here, and anything resolved in either place disappears from both.

## 1 Trigger

- Standard widget target and image slot (host-supplied challenge icon).
- **Badge:** count of **incoming** challenges only, which are the ones waiting on the
  user. Outgoing challenges are not counted. Hidden at 0. 16 px tall, min 16 px wide, 8 px
  radius, `accent` fill, `accentInk` mono 10 px / 600, 1.5 px ring in the bar colour so it
  separates from the image. Top-right of the target.

## 2 Dropdown

- Standard widget dropdown frame, right-aligned to the trigger. Width **372 px**.
  `max-height` = viewport − bar − 24 px; the list scrolls inside with the scrollbar gutter
  reserved.
- Two sections, always in this order: **Incoming**, **Outgoing**. Header: section name as a
  group label (12 px / 500 `inkMuted`) + count (mono 11 px `inkFaint`). Direction is shown
  once per section, so the entries themselves carry no direction marker.
- An empty section keeps its header and shows one 36 px line, "No incoming challenges" /
  "No outgoing challenges" (12 px `inkFaint`), so the sections never swap places.
- **Newest first** within each section. In both the dropdown and the notification stack,
  the newest entry is the one closest to where the component is anchored.
- Entries are separated by 1 px `divider` hairlines, not boxed.

## 3 Entry

Three rows, 6 px apart, 10 px vertical padding:

1. **Opponent + time control:** nickname 13 px / 600 on the left. On the right: kind icon
   (18 px) + time string (mono 13 px, or Archivo 13 px for word strings, as in the notification spec). An open
   outgoing challenge has no opponent and shows "Open challenge" at 500 `inkMuted`.
2. **Facts:** one line at 12 px: colour disc (11 px) + colour · Rated/Unrated · Default/Custom
   position, separated by `inkFaint` middots. Same emphasis rule as the card (Rated and
   Custom at 600). "Custom position" gets the **Preview** button at the right end of the
   line (same button as the notification card). Colour is always **the user's** colour, for outgoing too.
3. **Actions**, right-aligned, 30 px tall, 6 px apart:
   - incoming: **Decline** (normal) and **Accept**;
   - outgoing: **Cancel challenge** (normal).

- **No close or delete control.** An entry leaves only through its actions, or when the
  other side accepts, declines or withdraws.
- **Accept is not a filled primary.** The list can hold several Accept buttons, and a
  screen has only one filled primary. Accept uses the selected treatment (`accentTint`
  fill, `accentMuted` border, `accent` 600) so it still outranks Decline.
- Budget: the facts line is ~300 px wide in Russian at 12 px, inside ~318 px available.

## 4 Preview

The same position-preview popover as the notification card's, opened to the **left** of the dropdown, top-aligned
with it, with a title line naming whose position it is ("Position from <nickname>", or
"Your open challenge"). One preview at a time across the dropdown and the notifications.
It closes with the dropdown, or when its entry is resolved.

## 5 Interplay with notifications

- **One source of truth.** Accept or Decline in either place resolves the challenge in
  both. Hide / Hide all affect notifications only; the entries stay in the widget.
- **Accept anywhere** closes the dropdown and every notification; the other entries stay
  pending in the widget.
- **While the dropdown is open, new incoming challenges do not raise a notification.**
  They appear at the top of Incoming with the notification stack's arrival highlight and bump the badge.
  Showing the same challenge twice on one screen is noise.
- Opening the dropdown does not dismiss existing notifications.

## 6 Narrow

- The dropdown spans the viewport minus 12 px on each side, 6 px under the bar, and can
  grow to 12 px above the bottom edge; the list scrolls inside.
- Trigger uses the 44 px widget target and 30 px image; badge as on Wide.
- Entry rows as on Wide, except:
  - actions fill the entry width, split equally (Decline | Accept), 44 px tall, 8 px apart,
    13 px text; Cancel challenge spans the full width;
  - the Preview button is 28 px tall, and its facts line grows to match. This is still under
    the 44 px touch floor; accepted because it is not a resolving action;
  - the empty-section line is 44 px.
- **Preview** opens as an overlay pinned to the top of the dropdown, at its full width,
  covering the top of the list. It has a title row ("Position from <nickname>" 12 px / 500 +
  a 44 px ✕), then the side-to-move row and the board, centred. Closing it returns to the
  list without moving its scroll position.
