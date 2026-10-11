# General deferred entries

## 1. Against bot does nothing

**Why deferred:** no bot engine exists in v3.0 (`client.botengine` is empty) and the server rejects
bot challenges, so "Play the bot" has nothing to start.

**How to apply:** once a bot engine exists, handle `ChallengeTarget.Bot` in `Main.createChallenge`
(start a local game instead of a REST call). The Play → Versus Bot menu item already opens this
overlay with the bot type preselected.

## 2. Other entry points

**Why deferred:** their pages don't exist yet.

**How to apply:** the old dialog was also opened prefilled for a rematch (live game page), "play from
this position" (analysis, live game) and a direct challenge from a profile. Give
`ChallengeCreationOverlay.present` an optional initial `ChallengeDraft` (not saved back when the
caller asks so, as the old `dontCacheParams`), and call it from those pages. The home page's own
Create Game button should call the same entry point as the menu item.

## 3. "Game started" notification: the ongoing game check

**Why deferred:** when the other side accepts an outgoing challenge while the user is in an ongoing
non-correspondence game, the app shows `GameStartedNotice` instead of navigating away. The live game
page (which decides "an ongoing game is open") isn't built, so the check is stubbed.

**How to apply:** replace `Main.isOngoingGameOpen` with the live game page's state. Only the tab
`GameRedirect` picks gets to decide ([[multi_tab_challenges_plan]] §1).

## 4. Watch Player / Player Profile stubs

Create Game and Versus Bot (the same overlay, bot type preselected) are built:
`[[challenge_creation_overlay_plan]]`.

**Why deferred:** each used to open a plain `Dialogs.prompt` login-input, and no overlay
equivalent exists yet.

**How to apply:**
- Watch Player / Player Profile: need a simple login-input prompt overlay — smaller in scope than
  the challenge-params dialog, but no generic "prompt for a string" overlay utility exists in
  `haxefolio` yet (only `showOverlay` with a full custom content factory). Worth checking whether
  a small reusable prompt-overlay helper belongs in `haxefolio` itself (used by more than one
  future page) before building a one-off.
- Both handler stubs are named (`onWatchPlayerPressed`, `onPlayerProfilePressed` in `Main.hx`)
  specifically so they're easy to find and fill in later — bodies currently empty.

## 5. Client/server clock skew

Estimate the server time offset (e.g. from a server timestamp on connect) and
apply it wherever a `GameTimeUpdate` is extrapolated - the live game page needs the same.
Server time offset must be available globally through an utility.
