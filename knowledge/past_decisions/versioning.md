# Versioning, cache invalidation and compatibility: plan

Replaces the old scheme (hand-bumped `client_build`/`min_client_build`/`min_server_build`, `/check_compatibility`, ever-changing `.js` file names, manual "stop() via admin panel" deploy step).

This plan covers the code-level logic in both repos. How builds reach the hosting and the VPS (the deploy script, process management) is in `[[infra_plan]]`.

## Goals

- After a deploy, everything converges on its own.
- Breaking API changes are frequent (several releases a day are possible). The server never supports more than one API version.
- A client can be deployed without waiting for the running server to restart.
- No numbers to bump by hand on every release; no notices about updates.

## Two independent notions

- **Build ID**: identifies a client build. Answers "is my running code the latest one?". Fully automatic.
- **`API_VERSION`**: an integer constant in source, in both repos. Bumped in a commit only on a breaking API change. Client and server must match exactly.

## 1. Build ID and `version.json`

- A compile-time macro computes the build ID: `git rev-parse --short HEAD`, a `-dirty` suffix for uncommitted changes, plus a timestamp. Exposed as a constant.
- At the end of compilation (`Context.onAfterGenerate`) the same macro writes `bin/version.json`: `{"build": "<build id>", "api": <API_VERSION>}`.
- Debug builds use `build = "dev"`, and the client-side update checks are disabled.
- No source file is ever edited by a build or deploy step. `haxe build.hxml` stays the only build command.

## 2. Static layout: one folder per API version

Paths are relative to the app's folder on the static hosting (not necessarily the site root).

```
/index.html        loader; static, rarely changes
/sw.js             service worker; static, version-agnostic
/manifest.json
/.htaccess
/v/41/bin/app.js ...   client for API 41 (the running server)
/v/42/bin/app.js ...   client for API 42, uploaded ahead of its server
```

A client folder mirrors the repo layout (`bin/app.js`, `bin/hxconda.js`, `bin/version.json`, `manifest.json`, `assets/`); the loader makes it the document's `<base>`, so every relative URL of the app resolves inside it. The shell also holds `assets/favicons/pwa-*.png`, which `manifest.json` and `sw.js` reference.

- A client lives in `/v/<api>/`. A same-API rebuild replaces its folder; a new API gets a new folder.
- A folder must never be served half-written, and only the newest few `/v/*` folders need to exist (both handled by the deploy script).
- A folder whose server never started (superseded by a later deploy during a drain) is simply never loaded.

## 3. Loader (`index.html`)

- Reads the last known server API version from `localStorage` and loads `/v/<that>/app.js` straight away, without waiting for the server.
- With nothing stored, it first asks the server: `GET /version` → `{"api": <API_VERSION>}`. This endpoint replaces `/check_compatibility`.
- On localhost it loads `bin/app.js` directly (dev).
- `localStorage` access is wrapped so a failing read falls back to `GET /version`.

## 4. API version check on every WS connection

- The client sends its compiled-in `API_VERSION` as the `api` query parameter of the WS URL.
- On mismatch, the server accepts the connection and closes it with code `4409` and its own API version as the close reason (a browser can't read an HTTP-level rejection). The client stores that version for the loader and reloads immediately, without any guards.
- WS reconnects after every server restart, so a server update moves every open tab to the right folder without extra machinery. While the server is down mid-restart, the existing reconnect backoff applies.
- REST requests do not carry the version; the WS check is the single gate.

## 5. New build within the same API: forced reload

- **Detection:** fetch `/v/<api>/bin/version.json` (no-cache) on WS reconnect, on `visibilitychange` to visible, and every 5 minutes. A build differing from the compiled-in one marks an update as pending.
- **Tab hidden:** reload immediately.
- **Tab visible:** reload on the next in-app navigation (performed as a full page load), or after 60 s with no input, whichever comes first.
- **Protected states** postpone both until they end:
    - playing a live game (as a participant; spectating isn't protected);
    - a study with unsaved edits;
    - an open overlay with input in it.
- No notices, no prompts.
- Unsaved work lost on a forced API-mismatch reload is accepted; no draft persistence.

## 6. HTTP caching (`.htaccess`)

- `Cache-Control: no-cache` for everything: loader, `sw.js`, `manifest.json`, `/v/**` (including `version.json`, `app.js`, images, vendor, favicons). Unchanged files cost a 304.
- No hashed or rotating file names.
- Layouts, styles and locales are compiled into `app.js` and need nothing extra.

## 7. Service worker

- Stays network-first (a reachable server always wins); the cache answers only when the network fails, keeping offline-capable pages usable.
- Becomes version-agnostic: each API version lives under its own `/v/<api>/` paths, so versions never mix in the cache. `sw.js` needs no generated values.
- The precache list targets the loader and the shell files; per-version files are cached as they are fetched.

## 8. Forgotten API bump guard

- The server repo commits `api.lock`: `API_VERSION` plus a hash of the OpenAPI and AsyncAPI schemas.
- A check recomputes the hash. If it changed while `API_VERSION` didn't, the check fails and asks to either bump the version or confirm the change is backward-compatible (which rewrites the hash in `api.lock`). The deploy script runs it before uploading anything.

## 9. Drain and convergence

What happens after a deploy, from the code's point of view:

- `/shutdown` (admin token) starts the drain: the server finishes ongoing games and refuses new ones (existing `shutdown_activated` behaviour), then exits cleanly.
- The new release starts (the process manager restarts it); DB migrations have run by the time it serves.
- Clients reconnect, hit the API mismatch, reload, and the loader serves `/v/<new>/`.
- A newer release arriving during a drain simply becomes the one that starts.

Accepted trade-off: no new games can start while a drain is in progress, however long it lasts.

## Server-side changes

- Replace `MainConfig.min_client_build`/`server_build` and `/check_compatibility` with an `API_VERSION` constant and `GET /version`.
- Version check in the WS endpoint with a dedicated close code carrying the server's API version.
- The drain exit becomes a clean process exit instead of the `KeyboardInterrupt` hack.
- `api.lock`, its hash computation and the check command.

## Client-side changes

- Build ID macro writing `bin/version.json`.
- Loader in `index.html`; `sw.js` adjusted for the `/v/` layout.
- WS connect sends `API_VERSION`; mismatch close code handling (store version, reload).
- Update watcher with the forced-reload rules and protected-state checks.
- Remove `CompatibilityCheckPayload`, `CompatibilityResponse`, `CompatibilityResolution` and `CHECK_COMPATIBILITY`.
- Remove `Config.actualPathPrefix`/`prevPathPrefix`, already unused in v3. They are leftovers of v1's scheme, which `/v/<api>/` generalizes: the new client went to `game/` and the previous one moved to `exgame/`; on greeting, a client in `game/` that met the still-draining old server (`OutdatedServer`) redirected itself to `exgame/`, and a client in `exgame/` that met the new server (`OutdatedClient`) redirected back to `game/`. It supported just two builds at once, compared hand-bumped build times, and showed dialogs instead of converging silently.
- `.htaccess`.
