# Deferred entries from the `dict` module transition

Source: original project's `dict.Utils`, `dict.utils.OutcomePhrases`, `dict.utils.TimePhrases`,
and every phrase resolution in `dict.Dictionary.getTranslations` (the `Phrase` enum, ~200 cases).

Already resolved and filled into `assets/locale/{en,ru}.properties` under the
`intellector.common.*` prefix:
- piece color names, `guestName`, `DRAW_OFFERED_MESSAGE`/`TAKEBACK_OFFERED_MESSAGE` (as separate
  with-color/generic key pairs), outcome resolution text, outcome chatbox text
- `TURN_COLOR`, `CUSTOM_STARTING_POSITION` (the `Phrase.hx` file's own `//Common` section, minus
  `LANGUAGE_NAME` — see deferred item 6 below)
- the `//Connection-related simple dialogs` and `//Greeting-related simple dialogs` sections
  (app-wide, shown regardless of which page is active)
- the `//Copy` section (generic copy-to-clipboard widget strings)

Everything below is still open. General caveat that applies once any of it is implemented: the
original `Phrase` enum encoded the phrase catalog as Haxe enum constructors, so the compiler
enforced exhaustive handling of every case. Flat locale keys give up that safety net — a missed
case just silently renders a raw key or falls back, it won't fail to build.

## 1. `playerRef` and everything that resolves through it

`dict.Utils.playerRef`, `dict.Utils.opponentRef`, `dict.Utils.getLiveGameScreenTitle` (the
`LiveGame` case only), `OutcomePhrases.getSpectatorGameOverDialogMessage` /
`getDecisiveSpectatorGameOverDialogMessageTL`, and the `SEND_DIRECT_CHALLENGE_SUCCESS_DIALOG_TEXT`
phrase resolution (also listed under item 8, "Send challenge").

**Why deferred:** `playerRef` resolves a `PlayerRef` (Normal login / Guest / Bot) into a display
name, which depends on `LoginManager`/`BotFactory`-equivalent code that doesn't exist yet in this
project. `SEND_DIRECT_CHALLENGE_SUCCESS_DIALOG_TEXT` additionally pattern-matches on
`opponentRef.concretize()` and returns a structurally different sentence for the non-`Normal`
cases (not just a substituted name) — this can't be a single flat locale key at all; the branch
has to move into the calling Haxe code, which then picks between two separate keys.

**How to apply:** revisit once a `PlayerRef`-equivalent type and its resolution (login / guest /
bot name lookup) exist in this project.

## 2. `TimePhrases.getTimePassedString` / `getTimePassedEnglish` / `getTimePassedRussian`

**Why deferred:** the Russian variant needs numeral-agreement pluralization (singular word,
"N mod 10 == 1" form, "N mod 100 in 11..14" exception, etc.) for each of 5 time units. HaxeUI's
`LocaleString`/`LocaleStringExpression` *can* express this via conditional blocks evaluated on a
single param, e.g. `{[0] = 1 : A second ago}{[0] mod 100 in 11...14 : [0] seconds ago}{[0] mod 10
= 1 : [0] second ago}{_ : [0] seconds ago}` — but this is hand-written per key with no compiler
or test coverage, so a bracket/operator typo fails silently at runtime instead of at build time.

**Open question to resolve before implementing:** encode the pluralization directly in the
`.properties` files using this conditional-expression syntax (matches the framework's intended
usage, but fragile/untestable), or keep the branching in Haxe code and select between several
plain keys per unit (safer and testable, but doesn't use the framework's plural-expression
feature). See `[[haxeui_pending]]` for other rough edges found in this same expression engine.

## 3. `Utils.getScreenTitle` / `getLiveGameScreenTitle` (non-`LiveGame` cases)

Covers the `MainMenu`, `Analysis`, `PlayerProfile`, and `ChallengeJoining` title cases (the
`LiveGame` case is covered by deferred item 1 instead, since it also needs `playerRef`).

**Why deferred:** these are titles for pages (`Analysis`, `PlayerProfile`, challenge joining) that
don't exist yet in this project — out of scope until each page is built, per the page-by-page
transition approach. Also worth deciding at that point: in the original, these titles live as ad
hoc bilingual `[en, ru]` arrays built locally in `Utils.hx` and passed to
`Dictionary.chooseTranslation`, entirely outside the `Phrase`/`Dictionary` catalog. In the new
project, `PageBase.setTitle` already accepts `"{{key}}"` + up to 4 params directly per page (see
`TextDemoPage` in the `haxefolio` sample) — page titles should probably just be set at the call
site per page rather than centralized in a shared title-resolution function.

## 4. `Utils.getTimeControl`, `getTimeControlName`, and `TimeControlKind` display names

Covers `Utils.getTimeControl`, `Utils.getTimeControlName`, the `CORRESPONDENCE_TIME_CONTROL_NAME`
phrase, and — now that this project has its own `client.datatypes.TimeControlKind`
(`Hyperbullet`/`Bullet`/`Blitz`/`Rapid`/`Classic`/`Correspondence`) — display names for the other
five kinds, which the original never localized at all (`TimeControlType.getName()` returned raw
English only; only `Correspondence` went through the dictionary).

**Why deferred:** `Utils.getTimeControl` is dead/broken code in the original — marked
`//TODO: Use` and referencing an undeclared `startSecs` variable, so it doesn't even compile as
written. Beyond that specific bug, naming for all six `TimeControlKind` cases was drafted for this
pass but held back, so it's tracked here instead of in the resolved list.

**Open questions:** (a) drop `getTimeControl` entirely, or reimplement it properly once there's a
clear source of `start_seconds`/`increment_seconds` to format (check whether
`client.datatypes.TimeControl` still has that shape); (b) how the six `TimeControlKind` names
should be keyed/worded once this is picked back up.

## 5. `Utils.getUserStatusText` / `Dictionary`'s `PROFILE_STATUS_TEXT(status:UserStatus)`

**Why deferred:** out of scope until the Profile page exists in this project. Also, when it is
tackled: the original double-encodes data here — the phrase constructor carries the whole
`UserStatus` enum as payload, while the "time passed" string is separately pre-formatted and
passed as a substitution — this should be flattened into plain keys selected by a Haxe-side
`switch` rather than carried as enum payload, consistent with how the rest of this transition is
being done.

## 6. `LANGUAGE_NAME` / `Dictionary.getLanguageName`

**Why deferred:** unlike every other phrase, this one is deliberately *not* translated relative to
the active locale — `getLanguageName(lang)` always returns each language's own native name (e.g.
"Русский" for `RU`, even while the active UI language is English), because it labels the options
in a language switcher, where showing every option in whatever language is *currently* active
would defeat the point. HaxeUI's `LocaleManager` always resolves a key against the active locale,
so this can't be a single normally-translated key; it needs one key per language whose value is
*identical* across every `.properties` file (`intellector.common.language.en=English` /
`intellector.common.language.ru=Русский`, unchanged regardless of which file it's in). This is the
same class of "forced language independent of the active locale" issue `getColorName` had, but
where dropping the forcing (as was done for `getColorName`) would actually break the intended
behavior — flagging rather than guessing which way to resolve it.

## 7. Page/feature-specific phrases (deferred until each page/feature is built)

The rest of `Phrase.hx` is organized by page/dialog already, and none of those pages exist in this
project yet. Grouped below by the section headers `Phrase.hx` itself uses, so this can be
cross-referenced 1:1 against that file when each page is finally built. No individual translation
difficulty was found in these beyond what's already called out — the reason for deferral is
uniformly "the page doesn't exist yet," except where noted.

- **Analysis screen** — `ANALYSIS_OVERVIEW_TAB_NAME` through `ANALYSIS_INVALID_SIP_WARNING_TEXT`.
  Note: `ANALYSIS_BRANCHING_HELP_DIALOG_TEXT` holds a large literal HTML blob (bold/italic tags,
  escaped quotes) — worth double-checking once implemented that embedding raw HTML through a
  locale-resolved string renders the same way as a literal, and that none of the future translated
  text for other keys accidentally contains a literal `[0]`-`[3]` or `{{`/`}}` sequence, since
  those are meaningful to the locale engine.
- **Share dialog** — `SHARE_DIALOG_TITLE` through `SHARE_COMING_SOON`.
- **Bot phrases** — `BOT_ANACONDA_THINKING`, `BOT_ANACONDA_PARTIAL_RESULT_ACHIEVED`. Also blocked
  on `client.botengine` not existing yet (CLAUDE.md notes the bot engine wrappers need to be
  reimagined, not ported as-is).
- **Open challenge joining** — `OPENJOIN_*`.
- **Menubar** — `MENUBAR_PLAY_MENU_TITLE` through `MENUBAR_ACCOUNT_MENU_GUEST_DISPLAY_NAME`. The
  `MenuFacade`/`MenuBarItem` machinery to build an actual menubar already exists in `haxefolio`;
  only the Intellector-specific menu composition is missing.
- **Menubar dialogs** — `CHANGELOG_DIALOG_TITLE`; `LOGIN_*` (login/register form); `SETTINGS_*`
  (settings dialog tabs/options). `haxefolio.preferences` already provides a generic preference
  registry/builder — the settings dialog should probably be built on top of that rather than as a
  bespoke dialog, which may reshape which of these keys are still needed.
- **Profile** — `PROFILE_ROLE_TEXT`, `PROFILE_QUICK_ACTION_*`, `PROFILE_ACTION_*`,
  `PROFILE_FRIENDS_*`, `PROFILE_GAMES_*`, `PROFILE_STUDY_*`, `PROFILE_ONGOING_*`, `PROFILE_TAG_*`.
  (`PROFILE_STATUS_TEXT` specifically is covered by item 5 above.)
- **Mini-profile** — `MINIPROFILE_*`.
- **Main menu / table view** — `MAIN_MENU_CREATE_GAME_BTN_TEXT`, `READ_FULL_CHANGELOG_TOOLTIP`,
  `TABLEVIEW_*`, `CURRENT_GAMES_TABLE_HEADER`, `PAST_GAMES_TABLE_HEADER`,
  `OPEN_CHALLENGES_TABLE_HEADER`, `CHALLENGE_COLOR_ICON_TOOLTIP`.
- **Live Game (page, in-game messages, and board controls)** — `INVALID_MOVE_DIALOG_*`,
  `GAME_ENDED_DIALOG_TITLE`, `LIVE_WATCHING_LABEL_*`, `CHATBOX_MESSAGE_PLACEHOLDER`,
  `SPECTATOR_JOINED_MESSAGE`/`SPECTATOR_LEFT_MESSAGE`, `PLAYER_DISCONNECTED_MESSAGE`/
  `PLAYER_RECONNECTED_MESSAGE`, `TIME_ADDED_MESSAGE`, the `DRAW_`/`TAKEBACK_` cancel/accept/decline
  messages (offered/by-color already resolved, see the top of this file), `OPENING_STARTING_POSITION`,
  `PROMOTION_DIALOG_*`, `CHAMELEON_DIALOG_*`, and the game control button tooltips
  (`CHANGE_ORIENTATION_BTN_TOOLTIP`, `RESIGN_BTN_TOOLTIP`, `RESIGN_BTN_ABORT_TOOLTIP`,
  `RESIGN_CONFIRMATION_MESSAGE`, `ABORT_CONFIRMATION_MESSAGE`, `OFFER_DRAW_BTN_TOOLTIP`,
  `TAKEBACK_BTN_TOOLTIP`, `CANCEL_DRAW_BTN_TOOLTIP`, `CANCEL_TAKEBACK_BTN_TOOLTIP`,
  `DRAW_QUESTION_TEXT`, `TAKEBACK_QUESTION_TEXT`, `EXPLORE_IN_ANALYSIS_BTN_TOOLTIP`,
  `REMATCH_BTN_TOOLTIP`, `ADD_TIME_BTN_TOOLTIP`, `LIVE_SHARE_BTN_TOOLTIP`,
  `PLAY_FROM_POS_BTN_TOOLTIP`). Note: several of these (board flip, promotion, chameleon) are
  plausibly board-component strings shared by both the Live Game page and the Analysis board
  rather than Live-Game-only — worth deciding whether they belong under a shared
  `client.ui.common` board-component locale namespace instead of a page-specific one once both
  pages exist, rather than assuming either way now.
- **Misc dialogs** — `INPUT_PLAYER_LOGIN`. Held back rather than treated as common because it's
  unclear yet whether it's reused identically across the "follow player" and "direct challenge"
  flows or ends up needing per-flow wording.
- **Study params dialog** — `STUDY_PARAMS_DIALOG_*`. Note:
  `STUDY_PARAMS_DIALOG_TAG_LIST_PREPENDER` returns `["", ""]` in the original (empty in both
  languages) — looks like an unused placeholder; check whether it's still needed at all before
  porting it forward.
- **Incoming challenge dialog** — `INCOMING_CHALLENGE_*` (including the
  `INCOMING_CHALLENGE_ACCEPT_ERROR_*` notification cases).
- **Send challenge** — `SEND_DIRECT_CHALLENGE_SUCCESS_*`, `SEND_OPEN_CHALLENGE_SUCCESS_*`,
  `SEND_CHALLENGE_ERROR_*`. (`SEND_DIRECT_CHALLENGE_SUCCESS_DIALOG_TEXT` specifically is covered
  by item 1 above.)
- **Challenge params dialog** — `CHALLENGE_PARAMS_*`.
- **Requests / generic errors** — `REQUESTS_ERROR_DIALOG_TITLE`,
  `REQUESTS_ERROR_CHALLENGE_NOT_FOUND`/`PLAYER_NOT_FOUND`/`STUDY_NOT_FOUND`/`PLAYER_OFFLINE`/
  `PLAYER_NOT_IN_GAME`, `REQUESTS_FOLLOW_PLAYER_SUCCESS_*`. These read as generic enough to
  eventually be "common," but each one is actually tied to a specific not-yet-built feature
  (challenges, studies, following) — deferred alongside those features rather than promoted early.
- **Notifications** — `NOTIFICATION_BROWSER_TAB_TITLE(notification:BlinkerNotification)`. The
  underlying mechanism (`PageBase.startBlink`/tab-title blinking) already exists in `haxefolio`;
  what's missing is the domain events that would trigger it (`IncomingChallenge`, `GameStarted`),
  which belong to the menubar/challenge and live-game features respectively.

## Deliberately not tracked (per explicit decision, not just deferred)

- `OutcomePhrases.getPlayerGameOverDialogMessage` (and its exclusive helpers
  `getWinningGameOverDialogMessageTL` / `getLosingGameOverDialogMessageTL` /
  `getDrawishGameOverDialogMessageTL`, which have no other caller) — the ELO-suffix string
  concatenation this function does was flagged as awkward, but the resolution is to ignore it
  rather than design around it now.
- `OutcomePhrases.getPinOutcomeText` — was already unlocalized (English-only) in the original;
  left as-is rather than treated as a gap to fix.
- Functions whose return value isn't user-facing text (e.g. `TimePhrases.secsToInterval`) were
  excluded from consideration entirely — nothing to localize there.
