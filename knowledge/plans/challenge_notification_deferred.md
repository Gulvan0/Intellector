# Incoming challenge notification - deferred

Items consciously left out of [[challenge_notification_plan]].

## 1. Challenges widget interplay

**Why deferred:** the menu-bar challenges widget ([[challenges-widget]]) doesn't exist yet. Its rules
for notifications - "no notification while the dropdown is open", "one preview at a time across the
dropdown and the notifications" - have nothing to hook into, and hidden challenges have no permanent
home until it's built.

**How to apply:** when building the widget, give `ChallengeNotificationStack` a way to suppress
arrivals and close its preview from outside, and share the pending set from one place rather than
holding it in both.

## 2. Request error handling

**Why deferred:** there is no app-wide presentation for failed requests yet. Decline (single and
"Decline all") removes the entry at once and a failed request is silently ignored - the challenge
stays pending on the server. A failed Accept re-enables the card's buttons.

**How to apply:** once failed requests have a common presentation, route Accept/Decline failures
through it; a 404 on Accept (challenge already gone) should remove the entry instead.

## 3. Nickname budget

**Why deferred:** spec §1 relies on a server-side nickname cap (~22-24 characters) that isn't
confirmed. Longer nicknames are clipped.

**How to apply:** confirm/introduce the cap in IntellectorServerV2, or step the card's nickname down
to 15 px past the budget.

## 4. Generic notification features

**Why deferred:** HaxeFolio's notification layer only has what the challenge stack needs: no
auto-expiry, no entry/exit animation, no frame of its own.

**How to apply:** add them to `haxefolio.notification` when the first notification that needs them
appears, rather than in the challenge code.

## 5. Mobile Preview touch target

**Why deferred:** spec §4 leaves open whether the whole Position cell should be the tap target on
mobile. The Preview button is shorter than 44 px.

**How to apply:** if it turns out to matter, make the Position cell itself toggle the preview when the
position is custom.
