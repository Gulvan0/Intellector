# Player search overlay: deferred

Plan: `[[player_search_plan]]`.

## 5. Relation doesn't update live

**Why deferred:** no channel publishes follows; the relation is read once per answer. Statuses are
live over the per-player status channels.

**How to apply:** a per-user follows channel, if a stale relation in an open overlay ever matters.
