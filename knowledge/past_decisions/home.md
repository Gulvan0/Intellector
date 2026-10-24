# Home page

Source design: the "Intellector home page" canvas (https://claude.ai/artifact/6A7SDjaWNanV3mMmWK7puG):
`Main.dc.html` (wide), `Narrow.dc.html` (390 px), `Games.dc.html` (both games sections),
`GameCard.dc.html`, `Board.dc.html` (a stand-in for the real board renderer). The filter bar and the
pager are the profile's (`[[profile]]`).

## Decisions taken with the user (2026-10-22)

1. **List channels.** A refresh is the complete state of what its channel keeps current. The two
   unbounded list channels differ:
   - `PublicChallengeList` is a *head window*: its refresh holds the newest 50 public challenges,
     plus `total` and `has_more`. The Open challenges panel uses it as its first batch, loads further
     offsets over `GET /challenge/public` near the bottom, and applies created / cancelled /
     fulfilled / cancelled-by-server events live (new ones on top).
   - `CurrentGameList` (no parameters) holds *all* ongoing games: its refresh is every ongoing
     game summary, `NewActiveGame` adds one and `CurrentGameEnded` (id only, aborts included)
     removes one. The Ongoing panel filters, counts and pages them locally; an event applies at
     once on page 1, and on a later page only lights the "Updated · Refresh" pill, so the page
     doesn't shift under the reader.
   - `RecentGameList` is parametrized by the filter (time control kinds, rated): its refresh is the
     12 latest finished non-aborted games matching it, and `NewRecentGame` (sent only to the
     channels the game matches, aborts never) puts the game first and drops the 13th. Changing
     the filter re-subscribes. The panel has no pager, footer, pill or option counts. The filter
     must be written canonically (kinds sorted, unique; none for any kind) on both sides, since the
     channel's identity is its JSON.
2. **Event ordering**: subscribe first, then fetch; inserts and removals are idempotent by id. No
   sequence numbers.
3. **Ongoing boards** show the position they were loaded with; they don't follow plies.
4. **Recent games**: finished, aborted games excluded (a new `exclude_aborted` search flag), newest
   first by end time (the server orders finished searches by `game_ended_at`, the profile included).
5. **Correspondence cards** read kind icon + "Corr." («Пер.») + Rated/Casual, on the profile too.
   Ongoing correspondence cards show "White to move" and "Last move 3 hours ago"; finished ones show
   the result like any other. The search results carry `last_ply_at` for that.
6. **Own open challenge**: its row's button reads Cancel and cancels it.
7. **Guests and rated challenges**: Accept opens the login overlay; the server also rejects a guest
   accepting a rated challenge.
8. **Sixth quick-start preset is 60+0** (Classic by the kind rules; 30+30 would be Rapid).
9. **Filters stay in the POST body** of `/game/search`; `limit`/`offset` are query parameters.
10. **Outcome reasons** use the site's terms, as on the profile (Fatum, Breakthrough, "Black lost on
    time"); the profile's reason keys move to a common prefix.
11. **Empty states**: "No open challenges", "No games are being played" (ongoing, default filters),
    "No finished games yet" (recent, default filters), "No games match these filters" (filtered).
    Loading and errors use `LoadStatus` with Retry and the 10 s timeout, per panel.

## Decisions taken without asking (defaults, open to change)

- Ongoing order: newest started first (the server's id order).
- Boards are seen from White.
- Clicking "Updated · Refresh" re-renders the current page from the up-to-date list.
- The pager commits on Enter or blur, Esc restores (the handoff's rule; the profile's pager gains
  the blur commit).
- The Custom position popover is the site's `PositionPreviewPopover` (board plus side to move), as in
  the challenges widget.
- Accepting: the row's Accept is disabled while the request is out; success opens the game; a
  challenge already gone is removed with the "challenge unavailable" notice.
