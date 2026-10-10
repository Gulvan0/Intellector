# Challenges widget - deferred

Items consciously left out of [[challenges_widget_plan]].

## 1. "Game started" notification: the ongoing game check

**Why deferred:** when the other side accepts an outgoing challenge while the user is in an ongoing
non-correspondence game, the app shows `GameStartedNotice` instead of navigating away. The live game
page (which decides "an ongoing game is open") isn't built, so the check is stubbed.

**How to apply:** replace `Main.isOngoingGameOpen` with the live game page's state. Only the tab
`GameRedirect` picks gets to decide ([[multi_tab_challenges_plan]] §1).
