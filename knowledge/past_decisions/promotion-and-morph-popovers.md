# Promotion fan and capture-morph popovers

Two board-anchored popovers. Each is tied to one hex and leaves the rest of the board visible. Reuses the existing theme tokens (surface, border, accent, shadow), the 44 px touch target and the piece art component. Reference components by name, not by link.

## Shared rules

- No sheet or full overlay, on wide or narrow layouts. The board stays visible.
- The popover opens next to its anchor hex and does not cover it. The anchor hex gets the accent fill so the link is visible.
- Piece names are not shown. Piece art identifies a piece.
- Popover surface: `surface` fill, 1 px `border`, 9 px radius, popover shadow (0 8 px 28 px at 16% ink).
- No dismiss. Both are decisions the player must make, so there is no outside-click close and no close button.
- If the popover would leave the viewport, shift it along the board edge and keep the anchor visible. The fan mirrors upward when the hex is near the bottom edge.

## Promotion: fan below the hex

**Anchor:** the hex where the Progressor reached the last rank.

**Options:** Aggressor, Defensor, Liberator, Dominator, left to right, fixed order.

**Layout:**
- Four round buttons, 48 px diameter, on an arc centred on the anchor hex, opening toward the board interior.
- Offsets of button centres from the hex centre: (-72, +44), (-25, +70), (+25, +70), (+72, +44) px.
- Button: `surface` fill, 1 px `border`, small shadow (0 4 px 14 px at 18% ink). Piece art sits in a 34 px circle inside.
- No connecting strip between the buttons. Proximity groups them. A thin arc reads as a slider track, which suggests order and dragging.

**States:**
- Hover and focus: hover fill and accent border. Focus ring as in the theme.
- Pressed: accent-tint fill.
- No default selection and no highlighted option.

**Behaviour:**
- Click or tap a button: promote and close.
- Keyboard: arrow keys move between buttons, Enter or Space selects. Focus starts on the first button.
- The promoted piece's hex stays visible above the fan.

**Narrow screens:** same geometry. The buttons meet the touch floor, and the arc spans 144 px plus one button width.

## Capture morph: two labelled buttons

**Anchor:** the hex where the capture happened.

**Question:** whether the capturing piece changes into the type of the piece it captured, or keeps its own type. Neither answer is a default.

**Layout:**
- Popover below the anchor hex, 200 px wide, 8 px padding, buttons stacked with 6 px gap.
- Two full-width buttons, 44 px tall, 10 px horizontal padding, 10 px between art and label. Art sits in a 28 px circle on the left.
- Top: "Become <captured piece type>", with the captured piece's art. Emphasised (accent-tint fill, accent border, accent text, weight 600).
- Bottom: "Stay <capturing piece type>", with the capturing piece's art. Neutral (transparent fill, `border`, muted text, weight 500).
- Example: an Aggressor captures a Liberator. The labels are "Become Liberator" and "Stay Aggressor".
- Piece types are named in the labels because "Morph" and "Stay" alone are too abstract.
- The emphasis on the top button is visual order only. It does not preselect.

**States, behaviour and narrow screens:** as for the promotion fan. Tab order goes top to bottom. Width is fixed at 200 px, so long localised labels wrap to two lines and the button grows in height.

## Open items

- Real piece art for the lettered placeholders in the mockup.
- Whether the fan needs a tray if it reads as scattered over the board pattern.

## Revisions after implementation (supersede the sections above where they differ)

- **Cancelling:** both popovers can be cancelled - the fan by a fifth, cross-icon button, the morph popover by a close button in its top row - and both by a press outside them or Esc. "No dismiss" above no longer holds. Cancelling closes the popover and abandons the move (the piece returns to its origin).
- **Promotion layout replaced by the piece ring (decided after implementation, not yet built):** the fan described in "Fan geometry" below gives way to the ring shared with the premove chameleon prompt: six fixed slots at the anchor hex's vertex angles (Dominator upper-left, Liberator upper-right, Aggressor right, Defensor lower-right, Progressor lower-left, cancel left), the Progressor slot left empty for promotion so every kind keeps the same position in both prompts, and a hub disc showing the moving piece at the centre. Near a viewport edge the whole ring, hub included, slides inward as a unit. Button sizes stay as below. Details: `knowledge/plans/board_plan.md` §1.17 ("Piece ring").
- **Scrim (decided after implementation, not yet built):** the popovers are no longer non-modal. While one is open, a very light scrim covers the whole viewport, board and menubar included: the ink color at about 0.08-0.12 opacity (the exact value settled in the browser), light enough that the anchor hex and the moved piece stay readable. A press outside the popover lands on the scrim and only cancels it; the control underneath (menubar, the board's control row, a flip button) does not act. The board's own input stays suspended while the popover is open. Details: `knowledge/plans/board_plan.md` §1.17 ("Scrim").
- **Keyboard:** no arrow-key navigation, focus start or focus ring (dropped project-wide); only Esc.
- **Fan geometry:** five buttons on an arc around the hex. A button's diameter is 0.9 of the hex's on-screen height (radius close to the hex's inner radius; at least 44 px); the arc's radius keeps neighbours 6 px apart and clear of the hex. Nothing is a fixed pixel offset any more. Over files b-h the arc spans 40 degree steps and is symmetric about the vertical through the hex (its middle button straight above/below it); it only turns toward the board's centre, as far as needed (capped at 60 degrees), when it would not fit the viewport, and what that cannot fix is slid into the viewport. Over the outer files (a, i) it is a quarter of a circle, from straight below/above the hex to straight beside it, toward the board's centre, with its own, larger radius (whatever keeps its neighbours 6 px apart). Turning is done by positioning, not rotating.
- **Morph popover:** one and a half times the size first specified (390 px wide, 84 px buttons, 60 px art slots, 22 px labels; narrower if the viewport is). Its surface is 94% opaque. It has a header with the question ("Use aura?") on the left of the close button. It sits on the side of the hex facing the board's centre, vertically and horizontally (approximately - it only has to fit on screen). "Become X" and "Stay Y" both show the capturing piece's colour.
- **Art slot:** no border of its own (a rim lighter than the slot's fill read as a halo).
- **Locale:** piece names are global `intellector.piece.<kind>.<case>` strings; a template names the case it needs in its own `.case` key.
