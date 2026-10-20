# PubSub system: improvements

Server (`IntellectorServerV2`), easypubsub and the client's use of them. Suggested order: 1, 4, 5,
then 7.

## Performance

### 1. <done>

### 2. A slow client stalls a broadcast

**Problem:** `SubscriberStorage.broadcast` awaits `asyncio.gather` over all sends, so one stalled
connection delays the broadcast for everyone, with no limit on how far behind it can fall.

**How to apply:** a bounded outgoing queue per connection, drained by its own task; a connection whose
queue overflows is closed (it re-subscribes and gets fresh snapshots on reconnect).

### 3. Subscriber store leaks and scans

**Problem:** `subscribers` is a `defaultdict`, so `get_subscribers`/`count_subscribers` create an
entry for every channel they look up, and `unsubscribe` leaves empty entries behind. Disconnecting
(`get_subscriptions`, `fully_remove`) scans every channel.

**How to apply:** drop empty channel entries on unsubscribe, read with `.get` instead of indexing, and
keep a reverse index from connection to its channels.

## Correctness

### 4. Changes lost between snapshot and subscription

**Problem:** `subscribe` computes the refresh first and registers the subscriber afterwards; a change
broadcast in between reaches neither the snapshot nor the new subscriber.

**How to apply:** register first, then take the snapshot. Events that arrive before the snapshot are
then possible, so number them per channel and include the number in the snapshot; the client drops
events the snapshot already covers.

**My take:** Sounds like it increases complexity. Do we really need that?

### 5. Failed subscriptions are invisible

**Problem:** WS errors carry no channel, so easypubsub discards them; a page only learns a
subscription failed through its own timeout.

**How to apply:** include the channel in error messages raised while (un)subscribing, and route them in
easypubsub to that channel's subscriptions (an `onError` handler on `Subscription`).

## Convenience

### 6. Token on every message

**Problem:** each message carries the token and the server re-resolves it and re-attributes the
socket. The norm is authenticating once per connection, which also keeps tokens out of message logs.

**How to apply:** authenticate on connect (or with a first `auth` message); on identity change the
client reconnects, re-subscribing everything with one `sub_many`.

### 7. No subscription group

**Problem:** subscribing to a set of channels with shared handlers and detaching them together is done
by hand (`PlayerStatusFeed`).

**How to apply:** a generic group in easypubsub: created from `subMany`, handlers attached once for all
members, `detach` via `unsubMany`. `PlayerStatusFeed` becomes a thin wrapper over it.

### 8. Away → online lags up to 30 s

**Problem:** user activity reaches the server only with the 30 s ping.

**How to apply:** the client sends one message as soon as the user becomes active after the idle
threshold, rather than waiting for the next ping.

**My take:** Can we just send a ping? Will it be fine?

## Bugs

### 9. "Last seen" is stale for a recently disconnected player

**Problem:** with no open connection, `GET /player/{login}` derives the last activity from REST
request logs and ignores the WS activity, so a player active over WS minutes ago shows "Last seen
2 hours ago" on a fresh load (the live status event carries the right time).

**How to apply:** persist the player's last WS activity to the DB when their last connection closes,
and take the latest of it and the log-derived time in the fallback.
