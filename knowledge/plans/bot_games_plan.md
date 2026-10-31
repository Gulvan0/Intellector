# Bot games: plan

Games against Haxaconda bots, computed on the user's device and recorded through the server's
external games API. Deferred parts: `[[bot_games_deferred]]`. Design source: the "Challenge Creation
Overlay" canvas (https://claude.ai/artifact/5gGkYqdbDTwBFp6Fv2JFAj), boards "Against bot, …" and the
`guest`/`bot` notes. Earlier overlay decisions: `[[challenge_creation_overlay]]`.

## 1. Bots

Five members of the `hxconda` family, in this UI order. Names are not localized; descriptions are
(`en`/`ru`, the Russian ones translated from the user's English).

| avatar id | code | name | style |
|---|---|---|---|
| `intellector` | `std` | Haxaconda Standard | flagship, no bias |
| `progressor` | `trl` | Haxaconda Trailblazer | pushes progressors, marches the Intellector |
| `aggressor` | `vrz` | Haxaconda Vrezh | checks and sacrifices |
| `defensor` | `frt` | Haxaconda Fortress | keeps every piece defended |
| `liberator` | `unc` | Haxaconda Unchained | trades, open board, long moves |

- **Ref**: `+hxconda_<code>_<strength>`, e.g. `+hxconda_std_9`. Pre-v3 bot games keep the migrated
  `+Anaconda`.
- `client.datatypes.bot.BotKind`: `enum abstract(String)` over the codes (stored and sent as is).
- `client.datatypes.bot.BotSettings`: kind, strength (1..9), think time cap in seconds (null = no cap).
- `client.logic.bot.BotStrengthRules`:
  - availability: strength 9 for `std` only; 1..8 for all;
  - weakness = `(9 - strength) * 25` centiprogressors (9 → 0, 1 → 200);
  - half-depth: 9 → 6, 5..8 → 5, 3..4 → 4, 1..2 → 3 (depth 12 / 10 / 8 / 6).
- `client.logic.bot.BotKinds`: display name, description locale key, avatar path, engine style.
- `client.logic.bot.BotRefs`: builds and parses refs (`+hxconda_<code>_<strength>` → kind and
  strength; `+Anaconda` → legacy; anything else → unknown bot).

### Nicknames (localized on the client)

The server keeps sending English nicknames for guests and bots (a convenience for other API users);
this client ignores them for `_`/`+` refs and builds a localized name from the ref instead. A bot's
name: the bot name, the strength, and a localized suffix: "Haxaconda Standard 9 (Bot)" /
"Haxaconda Standard 9 (Бот)". Legacy: "Anaconda (Bot)" / "Anaconda (Бот)". Unknown bot refs: the
server's nickname. Guests get the same treatment ("Guest 123" / "Гость 123"), which the participant
mappers didn't do before. The mappers produce a locale binding as the nickname, so labels follow a
live language switch; places that pass a nickname as a template parameter or concatenate it resolve
it first.

### Avatars

`assets/images/common/bot_avatars/haxaconda/<id>.png`: padded to a square with transparent
rows/columns split equally on both sides of the lesser dimension (odd difference: the extra pixel
goes to the bottom/right), then downscaled to 512×512 (Lanczos). Current sizes: aggressor 681×591,
defensor 832×1272, intellector 816×1292, progressor 767×845, liberator 1024×1024. Done once with a
Pillow script from the scratchpad, overwriting the files in place.

## 2. Engine entry point (the single engine change)

Behavior of every existing search stays bit-identical: `scripts/hxconda/compare.js` must still pass.

- `engine.hxconda.search.budget.DepthBudget` (final class, inline methods, like `TimeBudget`):
  stops starting iterations once the completed depth reaches `maxDepth`, or (with a cap) once the
  deadline passes; `isExhausted` only on the deadline, so a capped search abandons the running
  iteration like `TimeBudget` does; `tracksLines` true; reports each completed iteration.
- `engine.hxconda.HxcondaStyle`: `enum abstract(String)` with the five styles (`std`, `trl`, `vrz`,
  `frt`, `unc`), engine-side so the engine stays self-contained.
- `Hxconda.bestMoveByDepth(notation, history, maxDepth, timeCapMs, onIteration)`.
- Protocol: request kind `SearchByDepth` with `halfDepth`, `?timeCapMs`, `weakness`, `style` (the
  last two carried but unused); responses reuse `Iteration` and `Completed`.
- `HxcondaEngine.searchByDepth(notation, history, halfDepth, timeCapMs:Null<Float>, weakness = 0.0,
  ?style, onCompleted:(score:Float, mainLine:Array<HxcondaMoveMessage>)->Void,
  ?onDepthReached:Int->Void, ?onFailed:String->Void)`:
  - depth = `halfDepth * 2`;
  - `onDepthReached(plies)` once for every newly completed depth, 1, 2, … (an iteration abandoned on
    the cap reports nothing); the final one fires right before `onCompleted`;
  - `onCompleted` with the score (positive favours white) and the main line of the deepest completed
    iteration, starting with the chosen move (to verify: the line recorded at the root's last
    improvement starts with `move`; where the aspiration re-search can break this, fall back to
    `[move]`);
  - `onFailed`: worker errors (needed by the caller although the spec didn't name it).
- Weakness and style are documented as "accepted, not applied yet".

## 3. Client engine wrapper (`client.botengine`)

- `AnacondaNotation`: `Position` → engine notation (see `Board`'s doc), engine move → `RawPly`
  (morphs included).
- `BotMoveSearch`: given the game's position history, `BotSettings` and the time allowance, converts,
  calls `HxcondaEngine.searchByDepth`, returns a `RawPly` (+ score and line, for later display). Owns
  one `HxcondaEngine`; `stop()` terminates the worker.
- `BotTimeAllocation.secondsToMove(secsLeft, incrementSecs, moveNum, pieceCount)`: the old
  `BotTimeData.getSecsToMove` verbatim (the unused `botMovesFirst` dropped; `moveNum` = plies played
  + 1, as the old `LiveGame.makeBotMove` passed it).
- Time cap passed to the engine = min(user cap, allocation); the allocation only for timed games;
  neither → no cap. `secsLeft` is the bot's clock when the search starts (a resumed game uses what
  is left).

## 4. Server (IntellectorServerV2)

1. **Bot registry**: family `hxconda`, members by code with display names. `UserReference.pretty()`
   for bots uses it ("Haxaconda Standard 9 (Bot)", "Anaconda (Bot)" for `+Anaconda`, "`<Title>` (Bot)"
   otherwise). This is the fallback nickname; the client localizes its own.
2. **Bot settings per game**: a new table `game_bot_settings` (`game_id` PK/FK, `think_cap_secs`
   nullable), written by `/game/external/create` when one side is a bot. `ExternalGameCreatePayload`
   gains `bot_think_cap_secs: int | None` (1..1800); `GamePublic` and `GameSummaryPublic` gain
   `bot_think_cap_secs`. The game's bot settings are thereby known on every device: resuming after a
   reload or elsewhere, and rematch, read them. Migration for the new table; pre-v3 games have none.
3. **External game creation is validated**: right now any client can create a game between any two
   refs. Require the uploader to be one side and a registered bot ref the other (422 otherwise);
   `bot_think_cap_secs` only allowed with a bot side.
4. Moves go through `/game/external/append_ply` **without** `time_remainders`: the server computes
   the clocks itself, like for internal games (clocks stay server-authoritative). Takebacks through
   `/game/external/rollback`.
5. Verify guests can create external games (`MandatoryUserDependency`), since guests may play bots.

## 5. Challenge creation overlay

Against bot follows the canvas: two phases inside the type slot.

- **Choose**: Wide, a sideways-scrolling row of square cards (avatar + name); Narrow, a two-column
  grid scrolling down. The current bot is outlined. "Play the bot" stays disabled while choosing.
- **Set up**: Wide, a square portrait left; right: name + About (?) + "Change bot", Difficulty (one
  strip of joined buttons 1–9; 9 disabled except for Standard), Think time cap (duration stepper
  0:01–30:00 over the canvas's step list, a No cap toggle beside it; the stepper stays, greyed, while
  No cap is on). Narrow: portrait and name on top, both fields full width below. Hints/errors
  right-aligned on the label line.
- **About**: a nested overlay over the challenge overlay (the player search's frame) with the bot's
  name and description.
- **Names that fit**: the card's name line is 166 px (Wide) / 132 px (Narrow); "Haxaconda
  Trailblazer" and "Haxaconda Unchained" are the longest. Measure at the real font; if they don't fit,
  the card's name wraps to two lines and the avatar shrinks to keep the card square (no ellipsis).
  Same check for the set-up name row beside "Change bot".
- **Slot height animates** with the type (180 ms ease-out, none under reduced motion): Direct 150 /
  164, Open 105 / 112, Against bot 222 / 282 px (Wide / Narrow). Both bot phases share one height.
  Implemented in haxefolio's `SwapSlot` as optional per-variant heights plus an animated transition
  (a library feature, not tailored to the app); the overlay frame stays fixed, only the scroll
  region's content changes height.
- **Other sections for bot games**: time control as usual; Game locked on Unrated with the reason
  "Games against bots are unrated" (external games are always unrated), the guest lock's pattern;
  colour and starting position as usual (a random colour is resolved by the client, since the
  external API takes both refs).
- The old `bot_note` locale entry goes.

### Draft and storage

- `ChallengeDraft` gains `bot:Null<BotKind>` (null → the Choose phase), `botStrength`,
  `botCapEnabled`, `botCapSeconds`: one strength and cap shared by all bots. Picking a bot that can't
  have the current strength (anything but Standard at 9) clamps it to 8.
- `ChallengeTarget.Bot` becomes `Bot(settings:BotSettings)`; `ChallengeDraftRules` validates the
  settings (strength allowed for the kind, cap in range when enabled).
- `ChallengeDraftStorage`: four new `LocalStorageKey`s. A bot submit saves everything, as now; a
  non-bot submit saves everything except the bot keys, so the bot selection changes only when a bot
  game actually starts. Opening the bot tab shows the remembered bot in the Set up phase.
- `ChallengePrefills.versusBot` keeps only switching the type; `ChallengePrefills.rematch` for a bot
  game opens Against bot with the same bot, strength and cap (from the ref and
  `bot_think_cap_secs`), same time control and position, colours swapped.

### Submit

`Main.createChallenge`'s `Bot` branch: resolve the colour, `CREATE_EXTERNAL_GAME` with the user's
ref, the bot ref and the cap, then `GameRedirect` to the new game and `onOutcome(GameStarted)`;
failures go to `RequestFailureNotice` (a new `FailedAction` if needed) with `Failed`.

## 6. Playing the game

`LiveGameInfo.external:Bool` becomes the uploader's ref, and the info gains the bot's
`BotSettings` (parsed ref + `bot_think_cap_secs`), so the page knows "this is my bot game".

- **Commands by game kind**: `LiveGamePage`'s REST calls move behind a small interface
  (`LiveGameCommands`: move, resign, abort, takeback, …) with an internal and an external
  implementation, so the page doesn't branch at every call. External: `append_ply` for both the
  user's and the bot's plies, `end` with `RESIGN`/`ABORT`, `rollback` for takebacks.
- **Actions against a bot**: draw offer and add time hidden. **Takeback** is an instant rollback to
  before the user's last move (2 plies back on the user's turn, 1 on the bot's), dropping any running
  search; disabled until the user has made a move. Chat stays (for spectators); the bot never writes
  to it. Rematch → §5's prefill.
- **`client.botengine.BotGameRunner`** (one app-wide instance, wired in `Main`): owns the running
  searches by game id.
  - Opening a bot game's page where it is the bot's turn (on load, on reconnect refresh, after the
    user's ply, after a takeback): if this tab already runs a search for that game, keep it;
    otherwise start a fresh one.
  - Leaving the page doesn't stop the search: the found ply is submitted wherever the user is in
    the app. A search is never started for a game whose page wasn't opened in this tab.
  - A result is dropped if the game moved on meanwhile (ply count changed, ended, rolled back).
  - Game ended → stop. Search failed → a notice with Retry on the page.
- **One driver per game**: tabs of the same browser hold a per-game lease in localStorage
  (`client.tabs`, heartbeat, taken over when stale), so only one computes. Across devices, a
  duplicate submit fails with "impossible ply" (422) and that side resyncs silently.
- **Bot clocks**: the server ticks the bot's clock while it thinks; latency is covered by the
  server's 60 s external grace. A user leaving during the bot's turn is `[[bot_games_deferred]]`'s.

## 7. Nicknames everywhere

"Haxaconda Trailblazer 9 (Bot)" (29 chars) must fit wherever a nickname shows: player bars (every
tier, Rail at 280 px), moves/info cards, ongoing games widget and home lists, profile game lists,
spectator strip, share overlay text, notifications. Audit each at its narrowest designed width
(`[[viewport_test_sizes]]`): ellipsis where the place already ellipsizes long nicknames, otherwise
fix the layout. Bot refs never link to a profile (`PagePaths` already excludes `+`).

## 8. Verification

- `compare.js` and `compare.js --baseline` pass (existing searches unchanged); a scratch Node driver
  checks `SearchByDepth`: stops at depth `2·halfDepth`, stops on the cap, one `onDepthReached` per
  depth, the last right before `Completed`, line starts with the move.
- `AnacondaNotation` round-trips random game positions against `intellectorboard`.
- Local server (`STAGE=test`, the test accounts): bot game as guest and as a player, timed and
  correspondence, user white/black/random, custom position; reload during the bot's turn → fresh
  search with the same cap; navigate away and back → the same search kept; two tabs → one search;
  takeback on either turn; resign/abort; pre-v3 game shows "Anaconda (Bot)" / "(Бот)".
- Overlay per the UI verification depth rules: both tiers, both languages, Choose/Set up/About,
  strength 9 disabled and the clamp, cap on/off/invalid, the slot animation between all type pairs,
  Rail 280 px.
