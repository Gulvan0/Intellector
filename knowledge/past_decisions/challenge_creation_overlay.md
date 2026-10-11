# Challenge creation overlay

Source design: the "Challenge Creation Overlay" canvas (https://claude.ai/artifact/5gGkYqdbDTwBFp6Fv2JFAj)

1. **Against bot** stays a selectable type as designed, but its primary action ("Play the bot") does
   nothing yet - no bot engine exists. See `[[challenge_creation_overlay_deferred]]` item 1.
2. **Open visibility** is Public / Link only (the design's "Private" was a slip; the server knows
   `public` and `link_only`).
3. **Hints sit on the label row** (haxefolio's `FieldHeader`, intellector-style.md §6.2), not under
   the control as drawn in the canvas.
4. **The last used parameters are remembered** in local storage - everything, the opponent's login
   and guest number included. Saved on a successful submit only.
5. **Submit flow**: the primary button is disabled while the request is in flight, the overlay stays
   open. `CREATED` closes it (the challenge reaches the challenges widget via WS); if the callee of a
   direct challenge is offline, an informational toast says so. `MERGED` (a game started at once)
   closes it and opens the game through `GameRedirect`. A `callee_not_found` error code marks the
   opponent field ("Player not found" / "Guest not found"). Anything else: `RequestFailureNotice`
   (which names the coded reasons: identical challenge, active challenge limits, server restarting),
   overlay left open.
6. **Guests** get the Game row locked on Unrated with the reason "Log in to play rated" (the server
   would downgrade a guest's rated challenge silently).
7. **Calling guests** (user-provided delta spec): inside the Direct slot, a Player / Guest ChoiceRow
   above the field. Guest: a "Guest number" field, digits only, above 0, no upper bound, a
   non-editable "Guest" prefix inside the input, mono value, numeric keyboard. The Direct slot grows
   to 150 px (Wide) / 164 px (Narrow) for all three types. Switching keeps both fields' texts.
   Additionally, the Player login field parses leniently: `123`, `#123`, `_123`, `Guest 123`,
   `Гость 123` all mean guest 123 (logins always start with a Latin letter, so this is unambiguous),
   and the hint then reads "Guest 123".
