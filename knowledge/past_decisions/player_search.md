# Player search overlay

Source design: the "Player search overlay" canvas (https://claude.ai/artifact/LVsUe7N159Cpg6NGDXKs3g),
artboards "Wide: dialog" and "Narrow: sheet". Deferred: `[[player_search_deferred]]`.

One overlay, several call sites. A call site gives the title, whether the user's own account is
listed, and what happens to the picked player. Picking a row closes the overlay first, then hands the
player over. The first call site is the Social → Player Profile menu item: "Find player", opens
`player/<login>`.

## Decisions taken with the user (2026-10-19)

1. **Loading keeps the rows.** While a request is in flight the previous rows, count and empty
   state stay as they are (no flicker). A failure or a 10 s timeout replaces the results area with
   the site's `LoadStatus` failure and its Retry.
2. **No network-level cancellation.** Typing is debounced (250 ms); each request goes through a
   `TimedLoad`, so starting a new one makes the previous answer ignored. `http`/`easyrest` stay
   untouched.
3. **The search field is a haxefolio component**: `haxefolio.structure.SearchBar` and the
   `Region.Search` the framework already reserved (`searchBarHeight` token). The count line, result
   cards and legend footer stay in the app.
4. **Own account per call site**: `excludeOwn`, sent as `exclude_self`. Find player lists it.
