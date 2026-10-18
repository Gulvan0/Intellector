# Player profile page: deferred

Plan: `[[profile_plan]]`.

## 1. Watch games does nothing

**Why deferred:** explicit decision; the watched-player menu-bar widget isn't designed yet.

**How to apply:** store the one watched login (exclusive state), drive the button's pressed state and
its "Instead of <nickname>" hint from it, and implement whatever the widget's design says watching does.

## 2. Status doesn't update live

**Why deferred:** no channel publishes player status changes; the page reads it once per load.

**How to apply:** a per-player status channel (or piggybacking on `PlayerOngoingGames` for the
playing/online flip) would let the header and the connections rows update in place.

## 3. Connections are unpaged

**Why deferred:** lists on the site are small; one request gives all three tab counts.

**How to apply:** if a player's lists grow into the thousands, add `offset`/`limit` per list to
`GET /player/{login}/connections` (keeping the shape) plus counts, and page the panel as it scrolls.

## 4. Past games page shift

**Why deferred:** OFFSET paging was chosen; a game finishing while the user browses can shift a row
to the next page.

**How to apply:** keyset paging anchored on `(started_at, id)` of the first page's load, with the
page number translated server-side.
