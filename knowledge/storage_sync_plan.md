# Cross-tab storage sync plan

Source: resolves item #2 ("No cross-tab `storage`-event sync") in `[[login_deferred]]`. Designed
via a dedicated planning pass (one Plan-agent design/validation round, plus direct verification of
`StorageBackend.hx`, `client.auth.Session`, `Main.hx`'s `bootstrapSession` chain, and
`easypubsub.PubSubEngine` against the actual current code — all already built and verified working
earlier in the same session as `[[login_plan]]`), plus two scope questions confirmed with the user.

Two open tabs each resolve `client.auth.Session` state (`currentLogin`/`currentNickname`) from
shared `localStorage` only once, at their own boot time — a login/logout in one already-open tab
has no effect on another already-open tab until it's reloaded. `login_deferred.md`'s own note
already sketched the fix direction: either `StorageBackend` grows a generic
`window.addEventListener("storage", ...)` hook, or an app-level listener re-runs `Session`'s
resolution when the relevant keys change. This plan finalizes exactly how.

## Two scope questions, resolved with the user before finalizing

- **WebSocket state:** confirmed no changes needed here. Reading `Libraries/easypubsub/src/
  easypubsub/PubSubEngine.hx` shows it already stores a live `tokenRetriever` function, not a token
  snapshot — both `sendEvent`/`sendSubOrUnsubEvent` call the `token` getter (which invokes the
  retriever) fresh on every outgoing message, matching the server's per-message WS auth (confirmed
  during `[[login_plan]]`'s own research, `IntellectorServerV2/src/net/incoming.py:94-101`). So a
  tab's *next* WS message after a cross-tab identity change already carries the new identity
  automatically — no reconnect logic needed.
- **`Preference<T>` cross-tab sync:** confirmed **in scope**, bundled into this same plan rather
  than deferred separately — since the underlying `StorageBackend` hook has to be generic anyway (a
  `Session`-only hook would be Intellector-specific, violating this library's "stay universal"
  charter), wiring `Preference<T>` to it too is nearly free and gives every existing preference
  (including the language preference) live cross-tab sync for no extra design cost.

## Design

### 1. `Libraries/haxefolio/src/haxefolio/preferences/StorageBackend.hx` — generic native hook

Add `using StringTools;`, wire a real `window.addEventListener("storage", ...)` listener directly
in the constructor (matches `HaxeFolioApp.init`'s own `addEventListener("popstate", ...)`
precedent; `StorageBackend` always has DOM access by the time it's constructed, so no lazy-init
concern here), and expose a generic, app-agnostic hook:

```haxe
package haxefolio.preferences;

import js.Browser;
import js.html.StorageEvent;

using StringTools;

class StorageBackend
{
    private final appSlug:String;
    private var changeListeners:Array<(String, Null<String>)->Void> = [];

    public function new(appSlug:String)
    {
        this.appSlug = appSlug;
        Browser.window.addEventListener("storage", onNativeStorageEvent);
    }

    public function has(id:String):Bool { return read(id) != null; }
    public function read(id:String):Null<String> { return Browser.window.localStorage.getItem(key(id)); }
    public function write(id:String, value:String):Void { Browser.window.localStorage.setItem(key(id), value); }
    public function remove(id:String):Void { Browser.window.localStorage.removeItem(key(id)); }

    /**
        Registers `callback` to run whenever a key belonging to this app/hostname namespace changes
        in `localStorage` from ANOTHER same-origin tab/window - per the DOM `storage` event spec,
        this never fires for changes made by the current tab itself (browsers only dispatch it to
        *other* browsing contexts), so no same-tab feedback loop is possible. `callback` receives
        the unprefixed `id` (as passed to `read`/`write`) and the new raw string value (`null` if
        the key was removed). Multiple callbacks may be registered; all run, in registration order,
        once per matching native event.
    **/
    public function onExternalChange(callback:(id:String, newValue:Null<String>)->Void):Void
    {
        changeListeners.push(callback);
    }

    private function onNativeStorageEvent(event:StorageEvent):Void
    {
        if (event.storageArea != Browser.window.localStorage) return;
        if (event.key == null) return; // fired by localStorage.clear(); out of scope
        if (!event.key.startsWith(keyPrefix())) return;

        var id:String = event.key.substr(keyPrefix().length);

        for (listener in changeListeners)
            listener(id, event.newValue);
    }

    private function key(id:String):String { return keyPrefix() + id; }
    private function keyPrefix():String { return '${Browser.window.location.hostname}.$appSlug.'; }
}
```

`key()` now builds on a shared `keyPrefix()` helper so the write-side and strip-side namespacing
logic can't drift apart. Note for the implementer: the `js.html.StorageEvent` extern types
`key`/`newValue` as non-null `String`, but the DOM spec allows both to be `null` (`clear()`/
`removeItem()` respectively) — Haxe/JS doesn't enforce this at runtime so the `== null` checks
above work correctly despite the extern's (inaccurate) type.

### 2. `Intellector Frontend v3.0/src/client/auth/Session.hx` — filtered, lazily-wired hook

Add a listener array, a lazy one-time subscription to the new `StorageBackend` hook (lazy because
`HaxeFolioApp.valueStorage` is `null` until `HaxeFolioApp.init` runs, and `Session.onExternalChange`
must be safely callable any time after that — same invariant every other `Session` method already
has), and the public hook, filtered to just this module's own 4 keys:

```haxe
private static final SESSION_KEY_IDS:Array<String> = [TOKEN_KEY, REMEMBER_ME_KEY, CREDENTIALS_LOGIN_KEY, CREDENTIALS_PASSWORD_KEY];

private static var subscribedToStorageBackend:Bool = false;
private static var externalChangeListeners:Array<Void->Void> = [];

/**
    Registers `callback` to run whenever any of this module's own `localStorage` keys changes from
    ANOTHER same-origin tab/window (e.g. a login/logout there). Deliberately does not report which
    key or what value changed - a caller should just re-resolve whatever state it cares about via
    Session's other (live-reading) accessors, the same way `bootstrapSession` already does.
**/
public static function onExternalChange(callback:Void->Void):Void
{
    if (!subscribedToStorageBackend)
    {
        subscribedToStorageBackend = true;

        HaxeFolioApp.valueStorage.onExternalChange((id, _) -> {
            if (SESSION_KEY_IDS.indexOf(id) != -1)
                notifyExternalChange();
        });
    }

    externalChangeListeners.push(callback);
}

private static function notifyExternalChange():Void
{
    for (listener in externalChangeListeners)
        listener();
}
```

Keep this fully separate from the existing `onSessionChanged`/`changeListeners`/`notifyChanged()`
pair — they signal different things (`onSessionChanged`: *this* tab just recorded a new identity;
`onExternalChange`: *another* tab wrote storage, this tab hasn't re-resolved yet). Collapsing them
would cause double- or out-of-order refreshes, since a triggered re-resolution will itself end in a
`recordIdentity`/`recordGuest` call that fires `onSessionChanged` downstream anyway.

### 3. `Intellector Frontend v3.0/src/Main.hx` — reuse `bootstrapSession`, add reentrancy guard

**Wiring**, alongside the existing two registrations:

```haxe
bootstrapSession(refreshAccountMenu);
Session.onSessionChanged(refreshAccountMenu);
Session.onExternalChange(() -> bootstrapSession(refreshAccountMenu));
```

No new orchestration logic needed — `bootstrapSession` already does a **live read** of
`Session.currentToken()`/`Session.rememberedCredentials()` at call time, so re-invoking it from an
external-change trigger naturally converges on whatever the other tab most recently wrote,
regardless of which specific key changed.

**`bootstrapSession` gains a same-tab reentrancy guard** (protects both the initial page-load call
and every external-change-triggered call uniformly, since it's the same function either way):

```haxe
private static var bootstrapInFlight:Bool = false;
private static var bootstrapRerunPending:Bool = false;

/*
    Silent-reauth chain run at startup AND re-run whenever another tab changes Session's storage
    keys (Session.onExternalChange) - always live-reading storage at whichever moment it actually
    executes, so a triggered run naturally picks up the other tab's latest state without branching
    on which key changed.

    bootstrapInFlight/bootstrapRerunPending guard against overlapping runs: a rerun requested while
    one is already in flight is deferred until the in-flight run's ENTIRE chain finishes, then
    re-run exactly once more (a live read at that point already reflects every write from every
    trigger that arrived meanwhile - no per-trigger queueing needed). Not a debounce/setTimeout:
    cross-tab storage events are only delivered after the writing tab's synchronous script has
    fully finished, so by the time this tab's handler runs, all of that write's related keys have
    already landed.
*/
private static function bootstrapSession(onReady:Void->Void):Void
{
    if (bootstrapInFlight)
    {
        bootstrapRerunPending = true;
        return;
    }

    bootstrapInFlight = true;

    var wrappedOnReady:Void->Void = () -> {
        bootstrapInFlight = false;
        onReady();

        if (bootstrapRerunPending)
        {
            bootstrapRerunPending = false;
            bootstrapSession(onReady);
        }
    };

    var token:Null<String> = Session.currentToken();
    if (token != null)
    {
        Rest.client().execute(RestOperationRegistry.WHOAMI, response -> {
            if (response.guest_id != null)
                Session.recordGuest(token, response.guest_id);
            else
                Session.recordIdentity(token, response);
            wrappedOnReady();
        }, error -> {
            Session.forgetToken();
            signInWithRememberedCredentialsOrGuest(wrappedOnReady);
        });
        return;
    }

    signInWithRememberedCredentialsOrGuest(wrappedOnReady);
}
```

**Critical, easy to get wrong:** every occurrence that currently reads bare `onReady` inside
`bootstrapSession`'s own body — including both tail calls to
`signInWithRememberedCredentialsOrGuest(...)` (the `token != null` early-return branch AND the
final fallthrough line) — must become `wrappedOnReady`. `signInWithRememberedCredentialsOrGuest`
and `authAsGuest` themselves need **no changes** — they keep taking a generic `onReady:Void->Void`
and calling it at their own leaf callbacks; passing them `wrappedOnReady` makes the guard correctly
span the *whole* 3-level chain (WHOAMI → sign-in → guest), not just `bootstrapSession`'s own
immediate branch. If only the WHOAMI-success branch used `wrappedOnReady`, `bootstrapInFlight` would
never reset on the sign-in/guest fallback paths.

**Convergence / no infinite loop:** writing an unchanged value to a `localStorage` key does not
fire a `storage` event in other tabs (browsers diff old/new value before dispatching), so a
WHOAMI-success re-record (which writes back the exact same `token` it just read) is silent to other
tabs in the common case. Only the fallback branches that mint a genuinely new token (SIGN_IN/
REGISTER/AUTH_AS_GUEST) write a changed value and could trigger one more hop elsewhere — and those
are only reached when WHOAMI already failed/was absent, so a healthy shared token never causes
repeated re-minting. Worst realistic case (e.g. a server restart racing a tab's boot) is a couple of
self-correcting hops — consistent with the already-accepted "no retry/backoff distinction"
simplification for this exact chain (`[[login_deferred]]` item #3).

**No new `Session.forgetIdentity()`/in-memory-reset method needed for this item** — re-running the
full chain always ends in a `recordIdentity`/`recordGuest` call that fully overwrites
`currentLogin`/`currentNickname` to the correct final state regardless of prior value. That's a
separate concern for `[[login_deferred]]` item #1's future Log In/Log Out UI work, not this one.

### 4. `Libraries/haxefolio/src/haxefolio/preferences/Preference.hx` — cross-tab preference sync

Since `StorageBackend.onExternalChange` is now a generic per-key hook, wire each `Preference<T>` to
it in `bindBackend` (the one place a `Preference` already learns about its backend), filtered to its
own `id`:

```haxe
public function bindBackend(backend:StorageBackend):Void
{
    this.backend = backend;

    var storedValue:Null<String> = backend.read(id);
    this.value = storedValue != null ? deserialize(storedValue) : defaultValue;

    backend.onExternalChange((changedId, newValue) -> {
        if (changedId == id)
            applyExternalChange(newValue);
    });
}

/*
    Reacts to this preference's own key changing in another same-origin tab: updates the in-memory
    value and fires the same `onChange` hooks `set()` would (e.g. so an open preference window's
    slider/button in this tab visually updates), but - unlike `set()` - does not write back to
    `backend`, since the value already came from there.
*/
private function applyExternalChange(newValue:Null<String>):Void
{
    value = newValue != null ? deserialize(newValue) : defaultValue;

    for (hook in hooks)
        hook(value);
}
```

This is a per-`Preference`-instance subscription (each preference is already inherently scoped to
one storage key, so no extra plumbing in `PreferenceRegistry` is needed — unlike `Session`, which
had to filter centrally because it owns multiple keys under one module). A nice side effect: the
language preference already wires its `onChange` hook to `LocaleManager` and active pages'
title/blink text (per its own doc comment in `PreferenceRegistry.locale`), so changing the language
in one tab will now live-retranslate any other open tab too, for free.

## Files to change

- `Libraries/haxefolio/src/haxefolio/preferences/StorageBackend.hx` — constructor-time native
  listener + generic `onExternalChange`.
- `Libraries/haxefolio/src/haxefolio/preferences/Preference.hx` — subscribe in `bindBackend`, new
  private `applyExternalChange`.
- `Intellector Frontend v3.0/src/client/auth/Session.hx` — filtered `onExternalChange`.
- `Intellector Frontend v3.0/src/Main.hx` — wiring line + `bootstrapSession` reentrancy guard.
- `Intellector Frontend v3.0/knowledge/login_deferred.md` — update item #2 to note it's now
  planned (cross-link to this file).

## Verification

1. `haxe build.hxml --debug` (frontend) — zero errors.
2. Serve the frontend, open the same page in two tabs (both starting as guests). In tab A, manually
   seed `localStorage` with valid `session_credentials_login`/`session_credentials_password`/
   `session_remember_me=true` and reload (silent sign-in, per `[[login_plan]]`'s own verification
   steps) — confirm tab B's Account menu header updates to the real nickname and "My Profile"
   appears, without reloading tab B.
3. In tab A, corrupt `session_token` via devtools to simulate a logout-like invalidation, reload tab
   A (falls through to a fresh guest token) — confirm tab B also updates to reflect the new guest
   identity live.
4. With devtools open on tab B, confirm no runaway loop of WHOAMI/sign-in/guest requests fires after
   the above — just the expected one or two settle-then-quiet calls.
5. Preference sync: open the preference window in both tabs; change the language in tab A; confirm
   tab B's UI (menu bar, page titles) retranslates live without reloading, and tab B's preference
   window (if open) reflects the new selection.
6. Confirm a change made *within* a single tab (e.g. normal login flow, or changing a preference in
   that same tab) does **not** trigger that same tab's own `onExternalChange`/preference-sync path —
   only `onSessionChanged`/`Preference.onChange`'s normal `set()` path should fire, since the native
   `storage` event never targets the originating tab.
