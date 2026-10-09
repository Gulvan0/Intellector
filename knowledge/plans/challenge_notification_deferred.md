# Incoming challenge notification - deferred

## 1. Challenges widget interplay

**Why deferred:** the menu-bar challenges widget ([[challenges-widget]]) doesn't exist yet. Its rules
for notifications - "no notification while the dropdown is open", "one preview at a time across the
dropdown and the notifications" - have nothing to hook into, and hidden challenges have no permanent
home until it's built.

**How to apply:** when building the widget, have `IncomingChallengesController` own it next to the
stack, both rendered from the controller's `ChallengeQueue`; the cross-view rules (suppressing
arrivals, one preview at a time) go in the controller.

## 2. Request error handling

**Why deferred:** there is no app-wide presentation for failed requests yet. Decline (single and
"Decline all") removes the entry at once and a failed request is silently ignored - the challenge
stays pending on the server. A failed Accept re-enables the card's buttons.

**How to apply:** once failed requests have a common presentation, route Accept/Decline failures
through it; a 404 on Accept (challenge already gone) should remove the entry instead.
