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
