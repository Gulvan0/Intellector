# Watch system

Source designs: the "Watch widget" canvas (https://claude.ai/artifact/2CU4gXNwvLCAoykmcaGwiM) and
the watched-player eye on the "Intellector game page" canvas
(https://claude.ai/artifact/2RpJ51udqkotP3YA4AAHWN, `.g-who`/`.g-eye`). Deferred:
`[[watch_deferred]]`.

The user watches at most one player at a time; watching another one replaces them. Watching
follows the games that player starts: each one either opens in the app or is announced with a
notification whose action opens it.

## Decisions taken with the user (2026-10-25)

1. **Own timed game blocks navigation.** While the user plays an unfinished timed game, a watched
   game is only announced, whatever the preference. Their own correspondence game page may be left.
2. **Preference** `watched_game_opening` (general tab), values `always` / `unless_spectating` /
   `never`, default `unless_spectating`:
   - `always`: navigate unless the page refuses leaving (`canLeave`, e.g. unsaved analysis edits)
     or decision 1 applies;
   - `unless_spectating`: also not while spectating an unfinished timed game;
   - `never`: always announce.
   Strings, kept short: EN "Watched player's games": "Always open" / "Unless spectating" /
   "Only notify"; RU "Партии наблюдаемого игрока": "Всегда открывать" / "Кроме просмотра" /
   "Только уведомлять". The middle value is short to fit its segment.
3. **Tabs.** The watched player lives in local storage, synced across tabs. A started game is
   claimed by one tab: the focused one at once, else the first one focused while the game is still
   going. The claiming tab navigates (or announces, when navigation isn't allowed); every other tab
   announces it. No tab blinking.
4. **Profile button toggles.** While the user watches that player, the profile's Watch button reads
   "Stop watching" in the selected look and stops on press. The hint becomes "Follow each game they
   start" / "Следить за каждой их новой партией".

## Decisions taken without asking (defaults, open to change)

- Watching is client-side only: `PlayerOngoingGames(watched_ref)` and `PlayerStatus(watched_ref)`
  are open to any subscriber. Guests may watch too.
- Only `OngoingGameStarted` triggers a reaction; the games already going when watching starts are
  listed in the widget, not opened. A refresh after the first one (a reconnect) treats games it
  newly lists as started.
- Games the user plays in themself are left to the user's own redirect (`GameRedirect`): ignored
  by the watch. A game already open on the page is ignored too.
- The own account can't be watched: left out of the search, and the field rejects it.
- The widget's field takes a nickname. Nicknames are logins with different capitalisation and extra
  spaces, so the login is the lowercased nickname without spaces. A malformed one is rejected as
  typed ("No player named “X”"); a well-formed one is looked up (`GET_PLAYER`) on Start watching,
  and a 404 shows the same error until the next edit, like the challenge overlay's unknown callee.
  A player picked in the search fills the field with their nickname and needs no lookup.
- The search opened from the widget's field reopens the dropdown after the pick.
- The announcement ("[watched] started a game" / "vs [opponent]", Open game) stays until closed or
  followed. Each tab keeps at most one: a newer one replaces it.
- The watched games list is one section ("Games", with a count), newest first, built from the games
  widget's entries: no turn marker, "vs" before the opponent, the watched player's colour and clock
  first. Preview and Open game work as in the games widget; the open game reads "Current game".
- The menu item "Follow Player" is renamed "Watch Player" (EN only; RU already says "Наблюдать за
  игроком"): "follow" is the friendship action.
- The player row in the watching state opens the watched player's profile; the status text uses
  the player search legend's strings.
