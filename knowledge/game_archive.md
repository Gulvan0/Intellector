`?p=games` page.

Basic layout: "Game database" ("База партий") header, then Formula box with its peripherals, then result table.

Entry points will be added to the app later. As of this plan, it is only accessible by its URL.

This page has no prejudice about aborted or external games. All games are shown, unless excluded by the filter conditions.

All search requests are executed on the server-side by a separate read-only DB user; with a mandatory time limit (when exceeded, a timeout error is returned and results in an error notification on the frontend).

Guests are allowed to use this page in all aspects. The only exception is that guests are not allowed to save filters.

# Filters

## Formula Box

A card holding filtering conditions. Is a scrollview.

Has expanded and collapsed state, toggleable by pressing a respective button. In collapsed state, has a fixed height and, if it's exceeded, scrolls vertically. In expanded state, doesn't scroll vertically and instead occupies all the necessary height (which may also increase and decrease as the formula changes).

Initially (if not pre-filled) appears like this:

```
AND
└── (+ Add condition)
```

Over time, gets conditions and nesting levels (see "Adding a condition: the flow"), example:
```
AND
├── (Started At < 13.06.2024 ×)
├── OR ×
│   ├── (Time Control = Blitz, Rapid ×)
│   ├── (Winner = PaulNotIntellector, Guest 23, Bot, ... ×)
│   ├── NOT (+ Specify condition) ×
│   └── (+ Add condition)
└── (+ Add condition)
```

What's important in the above example is that property names are presented as human-readable strings.

The hierarchy contours should be drawn as lines, not placed as text like in the examples above.

Braces denote the start and end of the pill-shaped card. Crosses denote the "delete condition" buttons - see "Deleting a condition".

Condition pill cards are clickable, and this click should trigger an edit, but the exact behaviour is still an open question.

## Formula finalization

Happens in two cases: when the player presses the "Search" button and when the player saves a filter, both are described in later sections.

The algorithm:

1. Delete all partially filled conditions.

2. In a loop remove all AND/OR conditions with zero subconditions (except for the root AND) and NOT conditions with unspecified subcondition, until none such remains.

Of course, visually, it should appear to the user as a single-step process. For example, they press the "Search" button and the formula in the formula box takes its final optimized shape.

Needless to say, "Add/Specify condition" buttons do not count as subconditions.

Important: root AND condition does not get removed even if it is empty. In this case, all games are returned, not filtered by any condition.

## Formula box periphery

### Above

Depends on the mode

#### Unsaved filter

Two right-aligned buttons: "Save filter" and "Open filter". Both with light monochrome icons.

"Save filter" prompts for a name (matching `[\w ]{1,32}` in unicode mode), then finalizes and saves the formula (sending a save request to the game server). It also transitions to the saved user-owned filter mode. If the filter with the name provided by the user already exists among this user's filters, an overwrite confirmation is shown first. For guests, "Save filter" invokes login overlay instead.

"Open filter" opens a dropdown of all filters saved by user, identified by their names. Clicking an entry requests the filter from the game server, then fills the formula and transitions to the saved user-owned filter mode.

#### Saved user-owned filter

Left-aligned filter name; right-aligned buttons "Share filter", "Delete filter" and "Open filter", the latter behaves identically to the one in unsaved filter mode.

"Share filter" copies a public link to the filter. It has a `?p=games/<filter owner login>/<filter name>` address. When such link is opened, it requests the respective filter from the server, then fills the formula, resets the URL back to `?p=games`, and, if the user is the owner, enters the saved user-owned filter mode, otherwise, enters the unsaved filter mode. It also performs the search and presents the results. Note that filter name gets URL-encoded and so should get URL-decoded before being used in a request to the game server.

There are also authorless saved filters managed by the server; they are accessible via the `?p=games/<filter name>` link. They behave the same, provided they could never lead the user into the saved user-owned filter mode, because they are not owned by anyone. In the very first iteration, two authorless filters will be defined: `Ongoing games` for `Result = Still Ongoing` condition and `Game archive` for `NOT Result = Still Ongoing` condition.

A dead link redirects to `?p=games`.

On the server-side, the filters will be stored in a table with a composite primary key: author (possibly noone, represented by an empty string) + name.

"Delete filter" shows a confirmation and, if confirmed, sends a delete request to the game server and enters the unsaved filter mode whilist not changing the formula in the formula box.

Once the formula is changed in any way, the mode switches to unsaved filter one. This, in particular, means that the only way to update the filter is by overwriting it via "Save filter" on an unsaved filter.

### Below

Right-aligned sits accent-tinted "Search" button, which finalizes the filters, requests the data and uses it to refresh the result table (see "Result presentation" below).

## Adding a condition: the flow

Describes what happens when a user clicks "Add condition"/"Specify condition" button.

Important: upon completing each step, the formula should update to show the partially filled condition at its place.

Mid-flow, an outside click or Esc press should trigger cancellation, leading to this condition being removed.

### 1. First dropdown

A choice is given between:
- All available properties (if one is clicked, GOTO 2a)
- All available recursive conditions (if one is clicked, GOTO 2b)

### 2a. (only for parametrized properties) Parameter selector

If a property is not parametrized, GOTO 3a straight away.

Otherwise, a value selector dropdown for the parameter is shown. Once it's selected, GOTO 3a.

### 2b. Formula expansion

The whole formula input restructures to incorporate the new structural member.

For NOT, this is simple: on the condition row, the NOT keyword appears, followed by the "Specify condition" button. This button is styled identically to the "Add condition button", and reacts the same way.

For AND or OR, a layer of nesting is added, prepended by the respective keyword.

### 3a. (not a real step)

If a property type implies operator conditions, GOTO 3aa.

If a property type implies custom condition, GOTO 3ab.

If a property type implies sole equality condition, GOTO 3ac.

### 3aa. Operator dropdown

The user is presented with the dropdown of all the operators that make sense for the selected property (determined by its type, see below).

Once one is clicked, GOTO 4aa.

### 4aa. Operand value selectors

For each operand the selected operator requires, the user is presented with a value selector. This happens in sequence, and each individual operand selection is counted as a separate step, which means, that formula updates the partially filled condition every time an operand is chosen.

### 3ab. Custom condition dropdown

A widget specifically for this condition is shown.

As part of it, it may (or may not) feature some value selectors. If it does, though, they do not appear in sequence. The process is two-step: the user fills all the blanks in the custom condition widget, then commits it by pressing the confirmation button.

### 3ac. Sole equality condition

Just a value selector dropdown appears.

## Deleting a condition

Each condition has a cross mark in the rightmost part of it. When clicked, it removes the respective condition and makes the formula readjust by removing its row.

Recursive conditions also have such cross mark to the right of the keyword. Deleting such condition also means deleting all its descendants at once.

## Value selectors

Dropdown widgets whose job is to provide a value (or a set of them, as `MultiSelection`, for example). All value selectors have a submission button ("Confirm"), except for `SingleSelection` (and `Bot`, trying to mimic it). Once a selector is submitted, the dropdown is closed and the value(s) is/are provided where requested.

### String, Int

Just an input field.

### SIP

String input field on the top, position preview on the bottom. Position preview updates along with the string input field's text.

### User

String input field with a magnifying glass button on the right. When the latter is clicked, a player search overlay is opened, and, on this overlay's submission, its output fills the string input field.

It is a login, it expects a user to enter a login. Player search overlay, despite searching by the nickname, fills in the login. But the input is always converted to lowercase upon confirmation.

### Guest

Just an integer input field prepended with static "Guest" text (label).

### Bot

Two-step selector with each step mimicking `SingleSelection` of a set of fixed options (see below).

First step's options are "any", plus bot families: "Anaconda", "Haxaconda Standard", "Haxaconda Trailblazer", "Haxaconda Vrezh", "Haxaconda Fortress", "Haxaconda Unchained". If "any" is selected, the selector short-circuits with a "Bot" value. If "Anaconda" is selected, the selected short-circuits with an "Anaconda" value.

Second step's options are "any", plus difficulties: for Haxaconda Standard, nine in total, from "1" to "9"; for other families, eight (up until "8"). If "any" is selected, the selector short-circuits with a value equal to the selected family. If a difficulty is selected, the value returned is a fully qualified bot, for example, "Haxaconda Vrezh 6".

### DateTime

Calendar widget. Should also allow to set time or opt-out of it. Also should provide an alternative: picking an option from `SingleSelection` filled with predetermined event days: appear as event names, yield event date.

`DateTime` is selected in a widget and presented in the UI in a local timezone, but in code and game server requests it should always be UTC.

Event days are hardcoded on the client-side in a JSON resource file.

### Duration

May have been just a number input field (for seconds or ms), but, for the sake of better UX, uses a separate selector widget, allowing users to set hours, minutes, seconds independently. In addition, certain properties may restrict the assignable units and their admissible range.

At its widest choice (which practically should never happen), allows to set these units:
- milliseconds
- seconds
- minutes
- hours
- days
- months (defined as 30-day intervals)

### SingleSelection, Bool, OptionalColor, PlayerOrColor

In the simplest case, `SingleSelection`'s selector is a dropdown of all the possible choices; only one may be picked. Such options are called _fixed_. In this document, these are written in quotes.

It gets more interesting, however, when _appended_ options are introduced. In this document, these are prepended with a plus sign.

Each appended option appears as a single item in the dropdown's choice list with a label starting with plus sign. When clicked, unlike fixed options, that are automatically selected as a value, it opens a prompt dropdown. Those are basically just value selectors themselves. Upon this prompt dropdown's commit, the input value gets selected.

Options may have icons, in that case, for fixed options, they are placed in the leftmost part of the dropdown item. For appended options, they are placed right after the plus sign. In other words, they are always placed right before the option label.

`Bool` is a `SingleSelection` with two fixed choices: "yes" and "no".

`OptionalColor` is a `SingleSelection` with three fixed choices: "any", "white", "black".

`PlayerOrColor` is a `SingleSelection` with the following choices: "white", "black", +`User`, +`Guest`, +`Bot`.

### MultiSelection, MultiTimeControlKind, MultiOutcomeKind

`MultiSelection`'s selector is a dropdown of all the possible choices (once again, they may be fixed or appended). It differs from `SingleSelection` in appearance and behaviour.

Appearance-wise, `MultiSelection` dropdown's items have a checkbox on the left.

When a fixed option is clicked, unlike `SingleSelection`, the selector is not submitted. Only the checkbox toggles.

When an appended option is clicked, similar to `SingleSelection`, the prompt dropdown gets opened. However, when this prompt gets committed, the selector is not submitted. Instead, a new already-ticked fixed option is added between the existing fixed options and appended options. It then behaves as a regular fixed option.

Just like `SingleSelection` items, the items of `MultiSelection` may have icons. The placement rules are the same. When a new fixed option is created via the appended option, it inherits the appended option's icon.

While no single option is ticked, the confirmation button is disabled.

`MultiTimeControlKind` is a `MultiSelection` with one fixed choice per `TimeControlKind` enum member. They use standard icons associated with `TimeControlKind` members.

`MultiOutcomeKind` is a `MultiSelection` with one fixed choice per `OutcomeKind` enum member (both decisive and drawish).

## Properties and their types

Property type follows the dash. For parametrized properties, the parameter type is presented in the braces.

In UI, the names should be presented as human-readable strings, for example, "Is ELO provisional?".

Operator condition properties:
- `started_at` - `DateTime` (allows UNKNOWN, which corresponds to legacy games for which this field is not filled)
- `ended_at` - `DateTime` (allows UNKNOWN, which corresponds to legacy games for which this field is not filled)
- `initial_time` - `Duration` (operands: h, m, s assignable; usual time control restrictions apply to the ranges)
- `bonus_time` - `Duration` (operands: m, s assignable; usual time control restrictions apply to the ranges)
- `duration` - `Duration` (operands: anything assignable except for s and ms; allows UNKNOWN, which corresponds to legacy games for either the start timestamp or the end timestamp are not filled; for ongoing games substitutes end timestamp with 'now' timestamp, calculated on server during the processing of the search request)
- `time_left` (`PlayerOrColor`) - `Duration` (allows UNKNOWN; operands: h, m, s assignable)
- `move_cnt` - `Int`
- `elo` (`PlayerOrColor`) - `Int`

Sole equality condition properties:
- `player` (`OptionalColor`) - `MultiSelection` (+`User`, +`Guest`, +`Bot`)
- `time_control_kind` - `MultiTimeControlKind`
- `rated` - `Bool`
- `outcome` - `MultiOutcomeKind`
- `starting_position` - `MultiSelection` ("default", +`SIP`) - will later be subsided by much more generic `arrangement`
- `opening` - `MultiSelection` (of a list of several dozens of fixed values; in actuality, is implemented as 'one of the SIPs associated with this opening has occurred in that game, with the cancelled plies excluded')
- `elo_provisional` (`PlayerOrColor`) - `Bool`
- `winner` - `MultiSelection` ("None yet (Ongoing game)", "Noone (Draw)", +`User`, +`Guest`, +`Bot`)
- `result` - `MultiSelection` ("Still ongoing", "White won", "Black won", "Draw")

Provisional:
- `arrangement` (will have a very special selector and unique conditions)

## Implicit restrictions

Will be better off explicitly highlighted to a user to keep them informed.

These apply only to the games subject to this condition. So, for example, a complex condition `initial_time > 20s OR time_control_kind IN ('CORRESPONDENCE',)` WILL include correspondence games, because implicit exclusion applies only to the first OR operand.

- Specifying any condition on `initial_time` or `bonus_time` automatically excludes all correspondence games
- Specifying any condition on `elo` or `elo_provisional`  automatically excludes all unrated games
- Specifying any condition on `elo`, `elo_provisional` or `time_left` bound to a specific player (user/guest/bot) automatically restricts the game set to the games where this player participated exclusively
- Specifying any condition on `ended_at` (even UNKNOWN) automatically excludes all ongoing games

These apply even if the condition is put inside the NOT block.

## Operator conditions for each property type

They may (and usually do) require operands (values) to be provided, their expected types are listed in brackets.

### DateTime

- `<` (`DateTime`) - if compared against a date without a time, assumes `00:00:00` time
- `>` (`DateTime`) - if compared against a date without a time, assumes `23:59:59` time
- BETWEEN (`DateTime`;`DateTime`) - behaves as a conjunction of `<` and `>`, but both bounds are inclusive (so more like `<=` and `=>` if they were available)
- UNKNOWN - but only if this specific property allows it

### Duration, Int (exact type expressed as T)

- `<` (`T`)
- `>` (`T`)
- `<=` (`T`)
- `>=` (`T`)
- `=` (`T`) - has a special behaviour for duration: compares with the precision matching the lowest assignable unit
- BETWEEN (`T`;`T`)
- UNKNOWN - but only if this specific property allows it

## Custom condition dropdowns

NONE YET

## Recursive conditions

- OR (`list[condition]`)
- AND (`list[condition]`)
- NOT (`condition`)

Important: in X block, recursive condition X appears disabled and, hence, cannot be selected. For example, in NOT block, among recursive conditions, one may only choose AND/OR. In AND block - only OR/NOT. Et cetera.

# Result presentation

A paginated table, whose contents (not pagination controls, those sit outside) are a horizontal scrollview (vertically occupies all the needed space).

Above the table, right-aligned, sits an "Export as XLSX" button with an Excel icon. It opens an export options overlay. Right now, only one option is available: a checkbox for including move columns.

Submitting the overlay sends a request to the game server making it query the whole result set from the database, convert it to xlsx and respond with a file so that a file download on the client-side will start. If move columns are set to be included, several columns are appended to the right of the usual ones: starting from "Move 1" up to "Move X", where X is the maximum move count in the queried game set; every column holds a notation string of the respective ply in the game (obviously, ply i becomes move i+1, because plies use 0-based indexing). For a game with move count equal to M < X, all columns starting from the "Move M+1" one and further to the right up until the last one should remain blank.

Important: all text occurrences in cell values should be selectable.

Column list should be customizable: a user must be able to toggle the inclusion of each invidividual column. The column roster also propagates to exported XLSX spreadsheet.

Results should be sortable by a column value. This applies to the result set as a whole, not to a single page. Hence, it emits a new search request and re-fills the result table on response. If multi-level sorting may be achieved without hurting or overcomplicating the UX, it should be implemented. Default sorting is by `ID` column in descending order. In exported XLSX, the columns are presented in the same order as in result table.

All available columns, in order:

- `ID` - game ID
- `Link` - game URL built from ID; should appear and behave as a normal HTML link - hidden by default
- `White` - white player nickname
- `Black` - black player nickname
- `White ELO` - white player ELO formatted as usual (e.g. with ? for provisional) if rated; if unrated, dash - hidden by default
- `Black ELO` - black player ELO formatted as usual (e.g. with ? for provisional) if rated; if unrated, dash - hidden by default
- `Started at` - datetime in a usual frontend format used elsewhere (e. g. datetime in a game info card)
- `Ended at` - datetime in a usual frontend format used elsewhere (e. g. datetime in a game info card) - hidden by default
- `Duration` - duration in a "DD:HH:MM:SS" format, with leading zero components stripped
- `Time control` - time control kind prepended with its icon
- `Start time` - time control's start time in a "DD:HH:MM:SS" format, with leading zero components stripped; dash for correspondence games
- `Bonus time` - time control's bonus time in a "DD:HH:MM:SS" format, with leading zero components stripped; dash for correspondence games
- `Rated` - "Yes"/"No"
- `Starting position` - "Default" if default, otherwise, SIP with "Preview" button sitting to the right and acting like similar buttons in ongoing game and challenge menubar widgets - hidden by default
- `Result` - "White won"/"Black won"/"Draw"/"Still ongoing"
- `Outcome` - outcome kind presented the same as on the game cards in player profile and main pages; dash if the game is still ongoing
- `Opening` - opening name - hidden by default
- `Move count` - move count as an integer - hidden by default
- `Time left (White)` - remaining time for white player in a "DD:HH:MM:SS" format, with leading zero components stripped; dash for correspondence games; does not update live for ongoing games; equals time reserve at the moment the game ended for past games - hidden by default
- `Time left (Black)` - remaining time for black player in a "DD:HH:MM:SS" format, with leading zero components stripped; dash for correspondence games; does not update live for ongoing games; equals time reserve at the moment the game ended for past games - hidden by default

There is no pre-search state. When a page is first opened, the game list is loaded into the result table. It then remains there until the user presses the "Search" button.

The result table, though, has special states. One is for empty result and another is for loading state. Both look identically: instead of a table, a centered label with italics font in dimmed colour is shown. The text says "No games match these filters" or "Loading the games..." respectively. Of course, these are localized strings.

The table indicates that the results are stale (which happens when the formula was edited, but the search button has not been pressed) by a small notice label above it. When the results are sorted or when the page is switched, the last submitted formula is used.

# Deisgn references across the existing components

1. The time control kind filters in game lists in home and player profile pages are prime examples of how `MultiTimeControlKind` should look like.

2. Pagination in abovementioned game lists is the same that should be used for result presentation.

3. Game action buttons ("Flip board", "Import position", "Analyze" etc.) are how "Open Filter" and "Save Filter" buttons above the formula box should look like.

4. HaxeFolio anchors (used, for example, in ongoing games menubar widget to show the position preview) are how appended option prompts should open (at the very least; probably more components and systems described in this plan doc may benefit from this feature).

# Open questions

1. Editing conditions

Conditions should be editable by clicking them in a formula box. The exact specifics of the behaviour are yet to be designed, though.

2. Calendar widget

It's design is described declaratively, as a set of requirements. The exact implementation is undecided.

3. Duration widget

Same for this, though it's a bit simpler to design.

4. Notifying the user when the implicit restriction is active

Not designed, and difficult to fit organically without breaking and/or overcomplicating the layout.

5. Ellipsis for long conditions

What are the rules for applying it?

6. Filter DTO and storage format

How is the filter passed to the game search endpoint? How is it stored in a database column?

7. Result presentation: including/excluding columns, sorting

Design missing.

8. Export as XLSX implementation on the server-side

Can it be simplistic? Or will some queries take a lot of time and need to implement the HTTP 202 async report generaiton pattern? If the latter, then how it should be wired on the frontend to keep UX intuitive and convenient? And how the server will make sure it won't get overloaded by such requests (either in number or in weight)?

Also: will including move columns have detrimental implications?

For information: we assert that the total amount of games will never exceed few tens of thousands and that the maximum move (ply) count will always lay below 500, with 95% of games ending in a two-digit number of plies.

9. Mobile-readiness

All the components discussed should be convenient to use on mobile. Special care is needed to satisfy this condition. Anchors are, for instance, one of the hardest elements to get done correctly.

10. Missing properties

Example: `move_cnt`, `ended_at`, `time_left`.

They may be costly as they need a join with another table or even subquery. This needs addressing.

11. 'Back' button in the condition addition flow

Probably there should be a way to return to the previous step of the flow, but I cannot design it.

# Other fixes required

1. Openings

Opening book should be synchronized between the client and the server. Maybe by the equivalence test.

If they are not equivalent and the server's version will be updated, the prod database should be updated with the corrected `opening_sip` values.
