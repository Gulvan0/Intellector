# Deferred entries from the login/session system plan

## 1. Manual Log In / Log Out UI and orchestration

**Why deferred:** confirmed scope for this pass is service-layer only — `client.auth.Session`
covers the init-time chain, but a callable `logIn()`/`logOut()` has no real caller yet (no Log In
overlay exists), and building one anyway would be unused scaffolding. The menu's `log_in_out` item
stays a no-op `Execute(() -> {})`, same status as Create Game/Versus Bot/Watch Player.

**How to apply:** when the Log In overlay gets built (a `HaxeFolioApp.showOverlay()`, per
CLAUDE.md's dialog-to-overlay migration rule), it should call `SIGN_IN`/`REGISTER` directly via
`Rest.client().execute(RestOperationRegistry...)` — mirroring how `client.ui` components already
call REST directly for their own needs (e.g. `OpenChallengesTable`) — and then feed the result into
`Session.recordIdentity(token, response.identity)` on success. This is the same pattern
`Main.hx`'s `bootstrapSession` already uses; don't route it through a new `Session.logIn()` method
(that would reintroduce the `net.rest` dependency inside `Session` this plan specifically avoided).
Logout similarly: clear storage via `Session.forgetToken()`/`forgetCredentials()` (plus a new
`Session.forgetIdentity()`-equivalent if the in-memory `currentLogin`/`currentNickname` fields need
resetting to a guest state — not present yet since nothing calls it this pass), then trigger a
fresh `AUTH_AS_GUEST` fetch so the app isn't left token-less afterward (there's no server-side
logout endpoint — logging out is purely a client-side decision to stop presenting the old token).

Also open at that point: whether `log_in_out` becomes a real three-way toggle (Log In / My
Profile / Log Out, like the old iteration) or a genuine single shapeshifting item — not decided
here.

## 2. No cross-tab `storage`-event sync

**Why deferred:** out of scope for the init-chain this pass covers; `StorageBackend`
(`haxefolio/src/haxefolio/preferences/StorageBackend.hx`) has no `storage`-event listener at all,
confirmed by reading the whole class.

**How to apply:** two tabs each independently resolve `Session` state from shared `localStorage`
at their own boot time, but won't react live to a login/logout happening in another already-open
tab. If this needs fixing later, it'd mean either `StorageBackend` itself growing a
`window.addEventListener("storage", ...)` hook (a generic, library-appropriate addition, not
Intellector-specific) or an app-level listener that re-runs `Session`'s resolution on the relevant
storage keys changing.

## 3. No retry/backoff or 401-vs-transient-error distinction in `bootstrapSession`

**Why deferred (an accepted simplification, not an oversight):** every failure branch in the
three-step init chain (`whoami` → `signin` → guest) is treated identically, whether it's a genuine
401 or a transient network/server error. Worst case on a blip is a redundant guest-token fetch —
harmless, self-corrects on the next reload/reconnect.

**How to apply:** if this turns out to matter in practice (e.g. users on flaky connections getting
silently downgraded to guest during a brief outage), a future pass could branch on HTTP status —
only treat 401 as "definitely invalid, move to the next fallback," and retry with backoff on
5xx/network errors instead.
