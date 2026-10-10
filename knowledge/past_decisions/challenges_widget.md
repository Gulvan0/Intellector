# Challenges widget

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
