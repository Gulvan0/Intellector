# Ongoing games widget - plan

Source: the "Ongoing games widget: handoff (revision 3)" artifact and the "Ongoing Games Widget"
design canvas. Reference pattern: the challenges widget ([[challenges_widget]]); only the
differences are listed here.

## 1. Data

- One WS subscription: `PlayerOngoingGames(own ref)` (server channel `player_ongoing_games`,
  formerly `started_player_games`).
    - `PlayerOngoingGamesRefresh`: every ongoing game, with `ply_cnt`, `last_ply_at` and
      `latest_time_update` on top of the summary.
    - `OngoingGameStarted`: a plain `GameSummaryPublic`; the client fills in the starting values
      (0 plies, no last move, full clocks with nothing ticking).
    - `OngoingGameUpdated`: a ply, a rollback or added time; carries the resulting
      `ply_cnt`/`latest_sip`/`last_ply_at`/`latest_time_update`.
    - `OngoingGameEnded`: the game's id; the entry leaves.
- Resubscribes on identity change (guests included), like the challenges.

## 2. Widget

- `DropdownWidget` left of the challenges widget, 372 px wide.
- Sections Timed, Correspondence, both always shown, ordering per the handoff. Sorting happens on
  every render: the order can't change while clocks tick (every running clock is yours or every
  one is the opponent's within a group).
- Clocks tick once a second while the dropdown is open; they stop at 00:00 and the entry stays
  until `OngoingGameEnded`. Remaining time is computed from the server's `updated_at`.
- Move number shown = `ply_cnt + 1`: every ply counts as a move.
- "Last move" for correspondence: `last_ply_at`, or the start time if no move yet; relative units
  just now / min / h / d.
- Open game navigates to `live/<id>` and closes the dropdown. Disabled as "Current game" while
  `LiveGamePage` shows that game.
- Preview: the challenges widget's `PositionPreviewPopover`, titled "Game with <nickname>",
  oriented for the user's colour; refreshed in place when the game updates, closed when it leaves.
- Icon and badge per the handoff's state table; badge = timed games on your move.
