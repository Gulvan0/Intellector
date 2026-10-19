# Player profile page

Source design: the "Intellector player profile" canvas (https://claude.ai/artifact/1EHctJnnNVgzVAQFFMbVnp)
and its handoff note (https://claude.ai/artifact/6AWtCZ1H7nCj8zGHiUNt6t). Status dots come from the
"Player search overlay" canvas (https://claude.ai/artifact/LVsUe7N159Cpg6NGDXKs3g), not the profile
canvas. Deferred: `[[profile_deferred]]`.

## Decisions

1. **Four statuses**: playing, online, away, offline. 10 px dots: playing `#c2412d`, online
   `#3f7d4e`, away `#c4930a` (filled), offline a 1.5 px `#a79b8a` ring. Labels: Playing now / Online /
   Away / Offline (Играет / В сети / Нет на месте / Не в сети). Status updates live over the
   per-player `PlayerStatus(watched_ref=login)` channels, which the server checks every 5 s; a list of
   players subscribes in one `sub_many`. An offline player's status is followed by "Last seen 5 hours
   ago" (Был в сети …), from `last_active_unixsecs`; the status line wraps when it doesn't fit.
2. **Playing** (server): the player's WS activity is ONLINE (not AWAY) and they play an ongoing game
   that isn't correspondence.
3. **Title** = the localized `main_role` (Administrator / Anaconda developer). No role: no line.
4. **Watch games** is a no-op: the button and its default hint are shown, clicking does nothing, it
   is never pressed. The menu-bar widget isn't built.
5. **Relation**: one follow model. Friends = mutual follows (since = the later of the two follow
   dates). Following = one-way out, Followers = one-way in; the three lists are disjoint. Buttons:
   Add friend (none, follows you) = follow; Unfollow (you follow) and Unfriend (friends) = unfollow.
6. **Guests** see Add friend; clicking it opens the login overlay. After logging in, the relation
   loads. The own profile shows no buttons and no relation line.
7. **Connections** entries: status dot, nickname, main rating with its kind icon; a player with no
   rating shows only status and nickname. Sorted by status (playing, online, away, offline), then
   nickname; a live status change only updates the dot, the order catches up on the next render
   (tab switch, reload). Clicking navigates to `player/<login>`.
8. **Nicknames** are shown everywhere the design says "login"; logins are used in routes and requests.
9. **Ongoing games** come from the `PlayerOngoingGames(watched_ref=login)` channel (refresh plus
   started/updated/ended events), filtered client-side. Opens on Correspondence when there is no live
   game.
10. **Past games**: OFFSET paging, page size 10; one request per filter or page change, counts
    requested only on filter changes.
11. **Studies**: page size 14 (wide) / 7 (narrow), all-of tag filter, the tag row of a card scrolls by
    dragging (mouse) or natively (touch), with an edge fade and no "+n" counter.
12. **Layout tiers** (`ProfileLayoutTier` width scale): wide ≥ 960 (aside on the right, 340 px),
    medium 720–959 (aside above the content, Connections / Game stats collapsed into bars), narrow
    < 720 (Unfriend / Watch share the full width, short labels). The past games table and the ongoing
    card grid follow their own width via `ResizeObserver` (six columns ≥ 760, four 540–759, mobile
    row < 540; two cards per row ≥ 680, or ≥ 780 on the Correspondence tab, whose cards' head line
    reads "Correspondence · Rated" and needs the wider cards).
13. **Kind names** stay in English in Russian too (except «По переписке»), site-wide: the shared
    `intellector.common.time_control_kind.*` keys changed.
14. **Past game results** read Won / Lost / Draw from the player's side, or Aborted for an aborted
    game; the line under it uses the site's outcome terms (Fatum, Breakthrough, "Black resigned").
15. **Ratings** show a `?` while provisional, as elsewhere on the site.
16. **Loading**: every card loads independently (loading → content, or error with Retry; a 10 s
    timeout counts as an error). An unknown login shows a not-found screen instead of the cards.
17. **Rating chart**: one point per local day (the rating that day ended at), placed by date, so the
    date labels match the line. Peak counts every game. Fewer than two days: no chart.
