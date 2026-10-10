# Challenges widget - deferred

Items consciously left out of [[challenges_widget_plan]].

## 1. "Game started" notification

**Why deferred:** when the other side accepts an outgoing challenge while the user is in an ongoing
non-correspondence game, the app should show a notification instead of navigating away. Its design
doesn't exist, and the live game page (which decides "an ongoing game is open") isn't built.

**How to apply:** design the notification; replace the stubbed check in `Main` with the live game
page's state and show the notification there. Only the tab `GameRedirect` picks gets to decide
([[multi_tab_challenges_plan]] §1).

## 2. Ongoing games widget

**Why deferred:** requested together with item 1 but not designed.

**How to apply:** design it as another `DropdownWidget` in the menu bar.

## 3. Outgoing challenges created in this client or another tab

Resolved by [[multi_tab_challenges_plan]]: the server's `OutgoingChallengeCreated` reaches every tab,
the creating one included, so the creation overlay needn't add the challenge itself.

## 4. Other tabs of the same user

Resolved by [[multi_tab_challenges_plan]].

## 5. Failed Cancel challenge

**Why deferred:** same as [[challenge_notification_deferred]] §2 - no app-wide presentation for
failed requests. The entry is removed at once; a failure leaves the challenge pending on the server.

**How to apply:** route the failure through the common presentation once it exists.
