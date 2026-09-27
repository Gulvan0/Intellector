# Incoming challenge notification

A non-blocking card announcing a direct challenge. It uses the existing Intellector theme
tokens, type scale, button styles and the time-control kind icons. Nothing here introduces
new tokens. References to other specs are by name, not by section number.

---

## 1. Content

Every card shows the same six items, always, in the same place:

| Item | Representation |
| --- | --- |
| Caller | Nickname, 17 px / 600, `ink`, under a 12 px `inkMuted` "Challenge from" label |
| Time control | Kind icon (18 px) + string in mono 14 px / 500 (`5+3`, `15+10`) |
| Rated | "Rated" (600) or "Unrated" (500) |
| Your colour | 13 px disc + "White" / "Black" / "Random" |
| Starting position | "Default" (500) or "Custom" (600) + **Preview** button when custom |
| Actions | Decline (normal button) · Accept (primary button) |

- **Emphasis marks the unusual.** Rated and Custom are set in 600; Unrated and Default in
  500. No colour is used for this: green/red are reserved, and brass on a fact would read as
  a control.
- **Colour disc:** 1 px board-seam border (`#664126`), fill = white piece colour, black piece
  colour, or a vertical half-and-half split for random. The board values are allowed here
  because the disc *is* a piece colour, not UI chrome. The word is always present, so the
  disc is never the only signal.
- **"You play" is from the recipient's side.** If the caller chose White, the card says
  "Black".
- **Nickname fits by construction:** at 17 px / 600 the 304 px content width holds ~24
  Latin or ~22 Cyrillic characters. Longer nicknames need a server-side cap, or a step down
  to 15 px; there is no ellipsis.

## 2. Layout

```
┌──────────────────────────────────┐
│ Challenge from               [✕] │  label row
│ Nickname                         │  17 px / 600
│ ┌───────────────┬──────────────┐ │
│ │ Time control  │ Game         │ │
│ │ (icon) 15+10  │ Unrated      │ │  2×2 fact grid
│ ├───────────────┼──────────────┤ │
│ │ You play      │ Position     │ │
│ │ ● White       │ Custom [Prev]│ │
│ └───────────────┴──────────────┘ │
│ [ Decline ]      [  Accept   ]   │
└──────────────────────────────────┘
```

- **Card:** `surface`, 1 px `border`, 9 px radius, overlay shadow. Width 340 px on desktop.
- **Padding:** 18 px sides. Label row 14 px from top; nickname 2 px under it, 14 px above the
  grid; actions 14 px above, 16 px below.
- **Fact grid:** two equal columns (`minmax(0,1fr)`), cells on `surfaceSunken`, separated by
  1 px `divider` hairlines (the grid's background showing through a 1 px gap), 6 px outer
  radius. Each cell: 9 px × 12 px padding; 11 px `inkMuted` label; 4 px gap; a 20 px value
  row.
- **Fixed height.** All four facts are always present and each value row is 20 px tall, so
  every challenge produces a card of identical height. The Preview button fits inside the
  Position value row; it adds no height.
- **Close (✕):** dismisses the card without replying, as distinct from Decline, which
  notifies the caller. 24 px icon button on desktop.
- **Actions:** two equal-width buttons, 10 px apart. Standard button styles.

## 3. Position preview

Shown only for a custom starting position; a default position has no button (the cell
keeps the same height either way).

- **Trigger:** "Preview" button at the right end of the Position value row, 11 px / 600,
  `accent` text, 4 px radius, 2 × 7 px padding. Toggle: unselected is transparent with a
  `border` outline; while open it uses the selected treatment (`accentTint` fill,
  `accentMuted` border).
- **Popover:** a separate `surface` card (same border, radius and shadow as the
  notification), never an expansion of the notification itself. Content, centred:
  - side-to-move row, 20 px: 11 px disc + "White to move" / "Black to move", 11 px
    `inkMuted`, no wrapping;
  - the board, rendered by the existing mini-board component used in the challenge params
    overlay (131 × 164 px).

  Padding 10 px top, 16 px sides, 14 px bottom; 6 px between rows.
- **One at a time.** Opening a preview closes any other open preview. Clicking the trigger
  again, the notification's ✕, Decline or Accept all close it.

## 4. Placement

### Desktop

- Cards stack in the **bottom-right corner** of the viewport, newest at the bottom.
- The preview opens to the **left** of its card, 10 px away, **bottom-aligned** with the card
  so it grows upward and never runs off the bottom edge.

### Mobile

- Card width = viewport − 24 px (12 px margin each side), pinned 12 px above the bottom
  edge. At 360 px that gives 336 px, which fits the 340 px desktop layout unchanged.
  Deliberately not edge-to-edge: a full-bleed card reads as a system banner or sheet, not
  a floating notification.
- **Touch targets:** Decline and Accept are 44 px tall; the ✕ keeps its glyph size but gets
  a 44 × 44 px hit area (negative margin, so the label row does not grow).
- The preview opens **above** the card, 8 px gap, at the same width, board centred.
- No scrim: the notification is non-blocking on both platforms.
- Open: the Preview button is below 44 px. If that matters, make the whole Position cell the
  tap target when the position is custom.

## 5. Stacking

One challenge is **active** (full card); every other pending challenge waits as a
**compact row** above it. The stack is anchored to the bottom corner and grows upward.

### 5.1 Compact row

`surface`, 1 px `border`, 9 px radius, light shadow (`0 2px 10px` at 8% ink). 40 px tall on
desktop, 44 px on mobile; 14 px side padding; 10 px gaps. Content, left to right:
nickname (13 px / 600, `ink`, takes the remaining width), kind icon (18 px), time string
(mono 13 px / 500). The whole row is one button; hover `borderHover`. Only nickname and
time control are shown — the rest is read on the full card. With the nickname budget from
§1 the row fits by construction (no ellipsis).

Rows are 6 px apart and 6 px above the active card.

### 5.2 Order and arrival

- Rows are in arrival order: oldest at the top, newest directly above the active card.
- **A new challenge never replaces the active card.** It enters as the newest row, briefly
  highlighted (`accentTint` fill, `accentMuted` border, fading back over ~400 ms after
  ~1.4 s). This prevents the card under the pointer from swapping mid-click, which would
  otherwise accept or decline the wrong challenge.
- If nothing is active, the arriving challenge becomes the active card directly.
- Clicking a row makes it active; the previously active challenge returns to its place in
  arrival order.
- **Decline** or **✕** removes the active card and promotes the **newest** remaining one.
  Decline replies to the caller; ✕ only hides the notification and the challenge stays
  pending.
- **Accept** closes **every** notification. The other challenges are not declined; they
  stay pending and are no longer shown as notifications.
- A second challenge from the same caller replaces their existing entry in place (keeping
  it active if it was). A challenge withdrawn by the caller is removed silently; if it was
  active, the newest remaining one is promoted.
- There is no auto-dismiss. A challenge stays until answered, dismissed or withdrawn.

### 5.3 Stack bar: Decline all and Hide all

Shown at the top of the stack whenever **two or more** challenges are pending.
`surfaceSunken` fill, 1 px `divider` border, 9 px radius. Left: count, 12 px / 500
`inkMuted` ("5 challenges"; on desktop plus " · +N more" when rows overflow). Needs plural
forms in Russian. Right, 6 px apart:

- **Decline all** is an outlined button (`surface` fill, 1 px `border`, 12 px / 500). It
  declines every pending challenge, including the active one, and closes the stack.
- **✕ Hide all** is a borderless text button with a ✕ glyph (12 px / 500, hover fill).
  It closes every notification and declines nothing.

The two are kept apart by reusing the card's own vocabulary. Decline all looks like the
Decline button (outlined, a reply goes out) and Hide all carries the card's ✕ (nothing is
sent). The labels spell the difference out as well; neither relies on style alone.
Decline all is the outer control and Hide all sits at the far right edge, where the ✕ is
on the card.

Desktop: 38 px tall. Mobile: 44 px tall, Hide all's hit area fills the bar height.

### 5.4 Limits

**Desktop:** at most **3 rows**. Older challenges are not shown as rows; the bar's
"+N more" counts them, and they surface as newer ones are answered. Maximum stack height:
bar + 3 rows + card ≈ 440 px.

**Mobile:** at most **1 row**, showing the newest waiting challenge. When more are waiting it
carries a count pill at its right end ("+2": mono 11 px / 500, `inkMuted`, `surfaceSunken`
fill, 1 px `border`, 10 px radius, 20 px tall). Tapping the row makes that challenge active;
the next one takes the row.

## 6. Correspondence time string

Correspondence games show the product's existing locale string for correspondence time
control ("Correspondence" / «по переписке») in the time slot, in place of an `m+s` value.
Mono is for values only, so a word is set in **Archivo 13 px / 500**, not mono 14 px. At that
size both locales fit the fact cell (~100 px available after the kind icon) on desktop and
mobile. Compact rows use the same rule at 13 px.
