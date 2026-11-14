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
│   ├── (Winner = PaulNotIntellector, Guest 23, Bot +2 more ×)
│   ├── NOT (+ Specify condition) ×
│   └── (+ Add condition)
└── (+ Add condition)
```

What's important in the above example is that property names are presented as human-readable strings.

The hierarchy contours should be drawn as lines, not placed as text like in the examples above.

Braces denote the start and end of the pill-shaped card. Crosses denote the "delete condition" buttons - see "Deleting a condition".

Condition pill cards are clickable, and this click triggers an edit (see "Editing a condition").

A `MultiSelection` pill lists its ticked values in the selector's order and shows at most 3 of them, followed by "+N more" if there are more, as in the example above. A pill with hidden values lists all of them in its tooltip. Each value has a maximum width, beyond which it is cut with an ellipsis (long SIPs, opening names); if the pill still exceeds the formula box width, its value list is cut with an ellipsis as well.

## Formula finalization

Happens in two cases: when the player presses the "Search" button and when the player saves a filter, both are described in later sections.

The algorithm:

1. Delete all partially filled conditions.

2. In a loop remove all AND/OR conditions with zero subconditions (except for the root AND) and NOT conditions with unspecified subcondition, until none such remains.

Of course, visually, it should appear to the user as a single-step process. For example, they press the "Search" button and the formula in the formula box takes its final optimized shape.

Needless to say, "Add/Specify condition" buttons do not count as subconditions.

Important: root AND condition does not get removed even if it is empty. In this case, all games are returned, not filtered by any condition.

## Formula box periphery

The mode, the header above the formula box, the URL, the results and the buttons all follow the last search, not the formula box: edits alone change none of them.

### Modes

- Unsaved filter: the last search ran a formula that is not a saved filter (or `?p=games` with an empty formula).
- Saved filter: the last search ran a saved filter, unchanged. It may be owned by the user, by someone else, or by nobody (authorless).

A search switches to the unsaved filter mode if the finalized formula differs from the saved filter that was last searched, and keeps the mode otherwise.

### Above

Left-aligned, in the saved filter mode only: the filter name, followed by a dimmed "by <author login>" ("by you" if the user owns it; nothing for authorless filters).

Right-aligned buttons, all with light monochrome icons: "Share filter", "Save filter", "Delete filter" (only for a saved filter owned by the user) and "Open filter".

"Share filter" copies the current page URL (see "Formula in the URL"): the saved filter link, which always shows the filter's current version, or the unsaved formula, which is a snapshot. Available to guests.

"Save filter" prompts for a name (trimmed, then matching `^[\p{L}\p{N}_ ]{1,32}$` with the `u` flag on the client and the equivalent pattern on the server; plain `\w` is ASCII-only in JS, but Unicode-aware in Python), then saves the formula (sending a save request to the game server) and transitions to the saved filter mode. If the filter with the name provided by the user already exists among this user's filters, an overwrite confirmation is shown first. This is the only way to update a saved filter.

"Delete filter" shows a confirmation and, if confirmed, sends a delete request to the game server and enters the unsaved filter mode, leaving the formula box and the results as they are.

"Open filter" opens a dropdown of all filters saved by user, identified by their names. Clicking an entry requests the filter from the game server, fills the formula and runs the search. If the filter no longer exists or its formula is unreadable (see "Formula in the URL"), a notification says that the filter was not found or could not be read, and the page stays as it was: the formula box, the results, the URL and the mode are unchanged.

If the formula box diverged from the last search (see "Result presentation"), "Share filter" and "Save filter" run the search first, so they always act on what the formula box shows. "Delete filter" acts on the saved filter named in the header.

For guests, "Save filter" and "Open filter" invoke the login overlay instead.

### Below

Right-aligned sits accent-tinted "Search" button, which finalizes the filters, requests the data and uses it to refresh the result table (see "Result presentation" below).

### Saved filter storage

On the server-side, the filters are stored in a table with a surrogate id primary key. Filters saved by users are unique by (author, name). Authorless filters are managed by the server and have no author, but have a unique fixed ASCII key used in their links. In the very first iteration, two authorless filters will be defined: `Ongoing games` (key `ongoing`) for `Result = Still Ongoing` condition and `Game archive` (key `archive`) for `NOT Result = Still Ongoing` condition.

Names are compared case- and accent-insensitively, as the DB collation does: `Foo`, `foo` and `Fóo` are the same name. The overwrite confirmation check uses the same comparison, so a save never fails on the key constraint instead of asking to overwrite.

## Formula in the URL

The URL fragment identifies the last search:

- `?p=games` - the empty formula, yielding all games.
- `?p=games#/<id>` - a saved filter by its id.
- `?p=games#/<key>` - an authorless filter by its key. A key is never a number, unlike an id.
- `?p=games#<base64>` - an unsaved formula, in the stored filter format (see "Formula format"), base64url-encoded without padding, so it never starts with `/`.

Opening the page, including via Back/Forward, reads the fragment, fills the formula, enters the respective mode and runs the search; the URL is kept. A saved filter is requested from the game server first. A missing filter, or a formula that is undecodable or exceeds a cap (see "Formula limits"), redirects to `?p=games` with a notification that the filter was not found or could not be read.

Every later search that changes the fragment writes it via `HaxeFolioApp.setFragment` with `keepInHistory: true`, so Back and Forward step through the searches; a search that does not change it leaves the history alone. Saving a filter and deleting the saved one replace the fragment (`#/<id>` and `#<base64>` respectively) instead. Sorting and the result page do not touch the URL.

## Formula format

Saved filters and URL fragments share one formula schema. The database stores it as JSON, the URL fragment as base64 of that JSON. Example:

```json
{
    "version": 1,
    "root": {"and": [
        {"property": "started_at", "operator": "lt", "operands": ["2024-06-13"]},
        {"or": [
            {"property": "time_control_kind", "values": ["BLITZ", "RAPID"]},
            {"property": "winner", "values": [{"user": "paulnotintellector"}, {"guest": 23}, {"bot": {}}]},
            {"not": {"property": "elo", "parameter": "white", "operator": "between", "operands": [1500, 1800]}}
        ]}
    ]}
}
```

Nodes:

- Recursive conditions: `{"and": [<node>, ...]}`, `{"or": [<node>, ...]}`, `{"not": <node>}`. The root is always an AND.
- Operator condition: `property`, `parameter` (parametrized properties only), `operator` (`lt`, `gt`, `le`, `ge`, `eq`, `between`, `unknown`) and `operands`, with as many as the operator requires (none for `unknown`).
- Sole equality condition: `property`, `parameter` (parametrized properties only) and `values`, a non-empty array in the selector's order.

Values:

- `DateTime`: `"YYYY-MM-DD"` or `"YYYY-MM-DDTHH:MM:SS"`, without a timezone.
- `Duration`: integer milliseconds. `Int`: integer. `Bool`: `true`/`false`.
- Colors (`OptionalColor`, `PlayerOrColor`, `UserOrColor`): `"white"`, `"black"`, plus `"any"` for `OptionalColor`.
- Players: `{"user": "<login>"}`, `{"guest": <id>}`, `{"bot": {}}` for any bot, `{"bot": {"family": "anaconda"}}`, `{"bot": {"family": "haxaconda_vrezh", "level": 6}}`. Families: `anaconda`, `haxaconda_standard`, `haxaconda_trailblazer`, `haxaconda_vrezh`, `haxaconda_fortress`, `haxaconda_unchained`.
- `time_control_kind`, `outcome`: `TimeControlKind`/`OutcomeKind` member names.
- `result`: `"ongoing"`, `"white_won"`, `"black_won"`, `"draw"`. `winner`: `"ongoing"`, `"draw"` or a player.
- `starting_position`: `"default"` or `{"sip": "<SIP>"}`.
- `opening`: the opening's stable id, since neither names nor codes are unique (A2 and U2 are both "Central Aggressor Opening"; `P1` is shared by four openings).

The schema is versioned from the start, since the vocabulary moves (`elo_kind` became `elo_provisional`, `starting_position` will be superseded by `arrangement`, the bot roster and the opening book will change). Stored filters are migrated on the server along with its DB migrations, so the server always returns the current version. URL fragments cannot be migrated, so the client upgrades an older formula step by step on decoding; a version it does not know is undecodable.

Search and export requests carry the same tree in the current version, except that every `DateTime` operand becomes `{"at": "<UTC ISO 8601 instant>", "inclusive": <bool>}`, resolved as described in the `DateTime` selector section; `inclusive` turns a bound non-strict:

- `lt`: a date becomes its local midnight, exclusive; a datetime is exclusive.
- `gt`: a date becomes the next day's local midnight, inclusive; a datetime is exclusive.
- `between`: the lower bound is inclusive, a date becoming its local midnight; the upper bound is a datetime, inclusive, or a date, becoming the next day's local midnight, exclusive.

The server rejects a request whose formula doesn't follow the schema with an error.

## Adding a condition: the flow

Describes what happens when a user clicks "Add condition"/"Specify condition" button.

Important: upon completing each step, the formula should update to show the partially filled condition at its place.

Mid-flow, an outside click or Esc press should trigger cancellation, leading to this condition being removed.

Every step but the first one has a "←" button in its dropdown header. It returns to the previous step with the previous choice still selected, and the partially filled condition in the formula shrinks back accordingly. The second step of the `Bot` selector has it too, leading to the first one. Pressing Backspace in a step whose text inputs (if any) are all empty does the same.

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

## Editing a condition

Clicking a property condition pill reruns the flow for it, starting with the step that follows the property choice (2a for parametrized properties, 3aa-3ac otherwise): the property itself cannot be changed, so the user deletes the condition and adds a new one instead. Each step comes pre-filled with the condition's current choice. The pill updates along the way, as during adding; committing the last step replaces the condition, while cancellation restores it as it was before the edit.

Clicking an AND or OR keyword opens a dropdown offering the other one, which keeps the group's subconditions. A switch is allowed if the result still alternates: the new kind must differ from the parent's and from every child's. NOT is never switched, nothing is switched to NOT, and the root AND cannot be switched. A keyword that cannot be switched shows no chevron and is not clickable; in practice, only a group directly under NOT can be switched.

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

First step's options are "any", plus bot families: "Anaconda", "Haxaconda Standard", "Haxaconda Trailblazer", "Haxaconda Vrezh", "Haxaconda Fortress", "Haxaconda Unchained". If "any" is selected, the selector short-circuits with a "Bot" value. If "Anaconda" is selected, the selector short-circuits with an "Anaconda" value.

Second step's options are "any", plus difficulties: for Haxaconda Standard, nine in total, from "1" to "9"; for other families, eight (up until "8"). If "any" is selected, the selector short-circuits with a value equal to the selected family. If a difficulty is selected, the value returned is a fully qualified bot, for example, "Haxaconda Vrezh 6".

### DateTime

A calendar dropdown (a full-screen sheet on Narrow). Design: https://claude.ai/artifact/GgKkJwkF9RVXBQCa7PJvdW

- "Calendar" and "Event days" tabs share one fixed-height slot.
- Calendar: month and year steppers, weeks start on Monday, always 6 rows; days of the neighbouring months are blank. The selected day is outlined, today is marked with a dot.
- Event days: event names with their dates. Picking one selects its date and switches to the calendar, so a time can still be added.
- A "Time" checkbox with hours, minutes and seconds fields, greyed in place while unchecked. Each field clamps on losing focus (0-23, 0-59).
- A hint line saying what the operand resolves to under the chosen operator: "Before 13.06.2024, 00:00", "From 14.06.2024, 00:00", "Through the end of 13.06.2024".
- The footer shows the value as `DD.MM.YYYY` or `DD.MM.YYYY HH:MM:SS` and the Confirm button, disabled until a day is picked.

A `DateTime` operand is either a date or a date with a time, both without a timezone. They read the same to every viewer and mean that viewer's wall-clock time: a shared "13.06" filter means 13.06 for whoever opens it, so viewers in different timezones may get slightly different results. Stored filters keep operands in this form.

The client resolves operands into UTC instants in its local timezone only when building a search or export request, following the rules of the `DateTime` operators: a date becomes its local midnight or the next day's one. Search requests carry UTC instants only. Since a date under `>` becomes a non-strict bound and a datetime under `<`/`>` stays strict, the request distinguishes strict and non-strict comparisons.

A time that falls into a DST change resolves as JS `Date` does: one skipped by a spring-forward shifts forward by the gap, one repeated by a fall-back takes its earlier occurrence.

Event days are dates, hardcoded on the client-side in a JSON resource file.

### Duration

May have been just a number input field (for seconds or ms), but, for the sake of better UX, uses a separate selector widget, allowing users to set hours, minutes, seconds independently. In addition, certain properties may restrict the assignable units and their admissible range.

The widget is a row of number fields, one per assignable unit, largest unit first, each followed by its unit label ("1 h 30 m 0 s"). Units the property doesn't allow are not shown. A field clamps its value on losing focus: the fields below the largest one to their unit's natural range (0-999 ms, 0-59 s, 0-59 m, 0-23 h, 0-29 days), and the total to the property's admissible range.

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

`UserOrColor` is a `SingleSelection` with the following choices: "white", "black", +`User`.

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
- `time_left` (`PlayerOrColor`) - `Duration` (operands: h, m, s assignable; allows UNKNOWN, which corresponds to legacy games for which this field is not filled; for ongoing games, the ticking side's remainder is computed as of the 'now' timestamp, calculated on server during the processing of the search request)
- `move_cnt` - `Int`
- `elo` (`UserOrColor`) - `Int`

Sole equality condition properties:
- `player` (`OptionalColor`) - `MultiSelection` (+`User`, +`Guest`, +`Bot`)
- `time_control_kind` - `MultiTimeControlKind`
- `rated` - `Bool`
- `outcome` - `MultiOutcomeKind`
- `starting_position` - `MultiSelection` ("default", +`SIP`) - will later be superseded by much more generic `arrangement`
- `opening` - `MultiSelection` (of a list of several dozens of fixed values; in actuality, is implemented as 'one of the SIPs associated with this opening has occurred in that game, with the cancelled plies excluded')
- `elo_provisional` (`UserOrColor`) - `Bool`
- `winner` - `MultiSelection` ("None yet (Ongoing game)", "Noone (Draw)", +`User`, +`Guest`, +`Bot`)
- `result` - `MultiSelection` ("Still ongoing", "White won", "Black won", "Draw")

Provisional:
- `arrangement` (will have a very special selector and unique conditions)

### Server-side evaluation

The properties not stored on the `game` row are computed in the search query from existing tables and indexes, with no extra columns. The server builds each expression once and reuses it for filtering, sorting, the result columns and the XLSX export, so that they never disagree. `:now` is read once per request.

- `ended_at`: `LEFT JOIN gameoutcome` by its primary key `game_id`; ended games only have a row. The same join serves `result`, `winner`, `outcome` and `duration` (`COALESCE(game_ended_at, :now) - started_at`).
- `move_cnt`: `COALESCE((SELECT MAX(live_ply_index) + 1 FROM gameplyevent WHERE game_id = game.id), 0)`, answered by one dive into the `uq_live_ply (game_id, live_ply_index)` index per game. `live_ply_index` is a virtual generated column, so the query must name it rather than `ply_index` with `is_cancelled = 0` for MySQL to use the index; to be confirmed with `EXPLAIN`. Should it fall short, a `ply_cnt` column on `game`, set alongside `latest_sip` on ply and rollback, replaces the subquery.
- `time_left`: the game's latest `gametimeupdate` (`SELECT MAX(id) ... WHERE game_id = game.id`, one dive into the foreign key index), joined by its primary key. A game's end writes a final `GAME_ENDED` update with no ticking side, so the same rule covers ended and ongoing games: `white_ms - IF(ticking_side = 'white' AND updated_at IS NOT NULL, TIMESTAMPDIFF(MICROSECOND, updated_at, :now) DIV 1000, 0)`, the same for black, as `GameTimeUpdate.get_actual_time_remainders` does. A player parameter picks the side by `white_player_ref`/`black_player_ref`. Legacy games without time updates yield null, which is UNKNOWN.

## Implicit restrictions

A pill whose condition implies any of them shows a small info icon to the left of its cross. The icon's tooltip names the restrictions, for example "Also excludes correspondence games".

These apply only to the games subject to this condition. So, for example, a complex condition `initial_time > 20s OR time_control_kind IN ('CORRESPONDENCE',)` WILL include correspondence games, because implicit exclusion applies only to the first OR operand.

- Specifying any condition on `initial_time`, `bonus_time` or `time_left` automatically excludes all correspondence games
- Specifying any condition on `elo` or `elo_provisional`  automatically excludes all unrated games
- Specifying any condition on `elo`, `elo_provisional` or `time_left` bound to a specific player (user/guest/bot) automatically restricts the game set to exclusively the games where this player participated
- Specifying any condition on `ended_at` (even UNKNOWN) automatically excludes all ongoing games

These apply even if the condition is put inside the NOT block.

## Operator conditions for each property type

They may (and usually do) require operands (values) to be provided, their expected types are listed in brackets.

### DateTime

- `<` (`DateTime`) - if compared against a date without a time, assumes `00:00:00` time
- `>` (`DateTime`) - if compared against a date without a time, means "on the next day `00:00:00` or later"
- BETWEEN (`DateTime`;`DateTime`) - both bounds are inclusive (`>=` lower bound, `<=` upper bound). A date without a time means `00:00:00` of that day as the lower bound, and "before the next day `00:00:00`" as the upper bound, so both boundary days are included in full
- UNKNOWN - but only if this specific property allows it

### Duration, Int (exact type expressed as T)

- `<` (`T`)
- `>` (`T`)
- `<=` (`T`)
- `>=` (`T`)
- `=` (`T`) - only available for Int, not duration
- BETWEEN (`T`;`T`)
- UNKNOWN - but only if this specific property allows it

## Custom condition dropdowns

NONE YET

## Recursive conditions

- OR (`list[condition]`)
- AND (`list[condition]`)
- NOT (`condition`)

Important: in X block, recursive condition X appears disabled and, hence, cannot be selected. For example, in NOT block, among recursive conditions, one may only choose AND/OR. In AND block - only OR/NOT. Et cetera.

## Formula limits

The formula is capped, with the caps being constants shared by the client and the server:

- Nesting depth: 8 recursive layers (AND/OR/NOT), the root AND included.
- Leaf conditions: 50.
- Total nodes (leaves and recursive conditions): 100.
- Values per `MultiSelection` leaf: 100 (all `opening` values must fit).
- `opening` and `starting_position` leaves (later `arrangement`), being the costly ones: 10 in total.
- Serialized formula: 8 KB, checked before parsing.

Both sides enforce them. The formula box disables the "Add condition"/"Specify condition" buttons, the recursive conditions and the `MultiSelection` options that would exceed a cap, explaining why in a tooltip. The server rejects an exceeding search or export with an error, shown as an error notification.

A formula exceeding a cap (handcrafted, or saved before a cap was lowered) counts as unreadable (see "Formula in the URL").

# Result presentation

A paginated table, whose contents (not pagination controls, those sit outside) are a horizontal scrollview (vertically occupies all the needed space).

Above the table, right-aligned, sits an "Export as XLSX" button with an Excel icon. It opens an export options overlay. Right now, only one option is available: a checkbox for including move columns.

Submitting the overlay sends a request to the game server making it query the whole result set from the database, convert it to xlsx and respond with a file so that a file download on the client-side will start. If move columns are set to be included, several columns are appended to the right of the usual ones: starting from "Move 1" up to "Move X", where X is the maximum move count in the queried game set; every column holds a notation string of the respective ply in the game (obviously, ply i becomes move i+1, because plies use 0-based indexing). For a game with move count equal to M < X, all columns starting from the "Move M+1" one and further to the right up until the last one should remain blank.

The response is synchronous: the server streams the file as it writes it. The size is not a concern even with move columns: few tens of thousands of games with ~60 plies typical is roughly 2M cells. Submitting closes the overlay; the "Export as XLSX" button then shows a spinner and stays disabled until the download starts or the request fails, the latter resulting in an error notification.

Datetimes and durations are native Excel values, not `DD:HH:MM:SS` strings, so that they sort and sum in Excel. Excel datetimes have no timezone, so the request carries the locale and the viewer's IANA timezone (`Intl.DateTimeFormat().resolvedOptions().timeZone`), and the server writes the viewer's local time. The request also carries the game URL template for the `Link` column (the client's own `?p=live/{game_id}` URL, built from its origin), so the server holds no frontend address. Moves are written in the notation by the server-side serializer (`board/serializers/notation.py`), kept equivalent to the client's (see "Other fixes required").

Important: all text occurrences in cell values should be selectable.

Column list should be customizable: a user must be able to toggle the inclusion of each individual column. The column roster also propagates to exported XLSX spreadsheet.

Results should be sortable by a column value. This applies to the result set as a whole, not to a single page. Hence, it emits a new search request and re-fills the result table on response. If multi-level sorting may be achieved without hurting or overcomplicating the UX, it should be implemented. Default sorting is by `ID` column in descending order. In exported XLSX, the columns are presented in the same order as in result table.

All available columns, in order (sorting, even arbitrary one, implies grouping results together by the sorted column, it's just that the order of such groups is arbitrary):

- `ID` - game ID
- `Link` - game URL built from ID; should appear and behave as a normal HTML link; hidden by default
- `White` - white player nickname; sorting sorts by login for users, guest id (numerically) for guests, bot slug for bots, all users are followed by all guests followed by all bots
- `Black` - black player nickname; sorting sorts by login for users, guest id (numerically) for guests, bot slug for bots, all users are followed by all guests followed by all bots
- `White ELO` - white player ELO formatted as usual (e.g. with ? for provisional) if rated; if unrated, dash; hidden by default
- `Black ELO` - black player ELO formatted as usual (e.g. with ? for provisional) if rated; if unrated, dash; hidden by default
- `Started at` - datetime in a usual frontend format used elsewhere (e. g. datetime in a game info card)
- `Ended at` - datetime in a usual frontend format used elsewhere (e. g. datetime in a game info card); dash for ongoing games; hidden by default
- `Duration` - duration in a "DD:HH:MM:SS" format, with leading zero components stripped; from 5 days on, whole days instead ("7 days"); for ongoing games, elapsed time as of the search request
- `Time control` - time control kind prepended with its icon
- `Start time` - time control's start time in a "DD:HH:MM:SS" format, with leading zero components stripped; dash for correspondence games
- `Bonus time` - time control's bonus time in a "DD:HH:MM:SS" format, with leading zero components stripped; dash for correspondence games
- `Rated` - "Yes"/"No"; sorting is arbitrary, but deterministic
- `Starting position` - "Default" if default, otherwise, SIP with "Preview" button sitting to the right and acting like similar buttons in ongoing game and challenge menubar widgets; hidden by default
- `Result` - "White won"/"Black won"/"Draw"/"Still ongoing"; sorting is arbitrary, but deterministic
- `Outcome` - outcome kind presented the same as on the game cards in player profile and main pages; dash if the game is still ongoing; sort is arbitrary as long as all drawish outcomes follow all decisive ones, but must be deterministic (declaration order in the server-side enum will do just fine)
- `Opening` - opening name; sorting sorts by code; it may not match the opening filter (for example, if the actual opening is the subvariation of an opening used in the filter), but that's intended; hidden by default
- `Move count` - move count as an integer; hidden by default
- `Time left (White)` - remaining time for white player in a "DD:HH:MM:SS" format, with leading zero components stripped; dash for correspondence games; does not update live for ongoing games; equals time reserve at the moment the game ended for past games; hidden by default
- `Time left (Black)` - remaining time for black player in a "DD:HH:MM:SS" format, with leading zero components stripped; dash for correspondence games; does not update live for ongoing games; equals time reserve at the moment the game ended for past games; hidden by default

There is no pre-search state. When a page is first opened, the game list is loaded into the result table (all games for empty filter; games matching the filter if a filter is opened by its link). It then remains there until the user presses the "Search" button.

The result table, though, has special states. One is for empty result and another is for loading state. Both look identically: instead of a table, a centered label with italics font in dimmed colour is shown. The text says "No games match these filters" or "Loading the games..." respectively. Of course, these are localized strings.

The table indicates that the results are stale by a small notice label above it. They are stale when the formula box diverges from the last search: its finalized formula, serialized, differs from the last searched one, so a partially filled condition does not count. When the results are sorted, when the page is switched or when a XLSX export is requested, the last submitted formula is used.

# Design references across the existing components

1. The time control kind filters in game lists in home and player profile pages are prime examples of how `MultiTimeControlKind` should look like.

2. Pagination in abovementioned game lists is the same that should be used for result presentation.

3. Game action buttons ("Flip board", "Import position", "Analyze" etc.) are how "Open Filter" and "Save Filter" buttons above the formula box should look like.

4. HaxeFolio anchors (used, for example, in ongoing games menubar widget to show the position preview) are how appended option prompts should open (at the very least; probably more components and systems described in this plan doc may benefit from this feature).

# Open questions

1. Result presentation: including/excluding columns, sorting

Design missing.

2. Mobile-readiness

All the components discussed should be convenient to use on mobile. Special care is needed to satisfy this condition. Anchors are, for instance, one of the hardest elements to get done correctly.

# Other fixes required

1. Openings

Opening book should be synchronized between the client and the server. Maybe by the equivalence test.

If they are not equivalent and the server's version will be updated, the prod database should be updated with the corrected `opening_sip` values.

2. Notation

The server-side notation serializer (`board/serializers/notation.py`) should be kept equivalent to the client's one by the same kind of equivalence test, since the XLSX export writes moves with it.
