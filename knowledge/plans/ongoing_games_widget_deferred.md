# Ongoing games widget - deferred

Items consciously left out of [[ongoing_games_widget_plan]].

## 1. Low-time cue on the clock

**Why deferred:** not designed (handoff's open items).

**How to apply:** design it first, then style the running clock below the threshold.

## 2. Client/server clock skew

**Why deferred:** remaining time is computed against the browser's clock; a skewed clock shows
the running clock off by the skew.

**How to apply:** estimate the server time offset (e.g. from a server timestamp on connect) and
apply it wherever a `GameTimeUpdate` is extrapolated - the live game page needs the same.

## 3. The games icon in the design system README

**Why deferred:** handoff's open item; it's an exception to "icons are strokes".

**How to apply:** add the filled games icon to the Intellector UI design system's icon entry.
