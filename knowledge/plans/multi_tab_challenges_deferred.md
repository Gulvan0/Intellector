# Challenges across tabs - deferred

Items consciously left out of [[multi_tab_challenges_plan]].

## 1. Log in/out in another tab

**Why deferred:** out of scope; not checked whether the other tabs pick up the new identity and
resubscribe correctly.

**How to apply:** test it with two tabs; the challenge state already resets on an identity change.

## 2. Stale WS API docs

**Why deferred:** the server's AsyncAPI spec generation is disabled (`regenerate_asyncapi_docs`), so
`asyncapi_spec.json` lacks the four new events.

**How to apply:** regenerate once the v2 generator exists.

## 3. Blink on an incoming challenge

**Why deferred:** the old app also blinked the tab title on a new incoming challenge; not requested.

**How to apply:** reuse `GameRedirect`'s blinker setup with a "New challenge!" title.
