# Deferred entries from the menu bar / sidebar configuration pass

Source: `C:/Users/mitmi/Documents/GitHub/Intellector/src/gfx/Scene.hx` and its popups
(`gfx/popups/{LogIn,ChallengeParamsDialog,Settings}.hx`), plus `gfx/menubar/*` (the challenge
notification widget). See `[[menu_plan]]` for what was actually built this pass.

Already resolved and built this pass: all four left-side `NormalMenu`s (Play/Spectate/Learn/
Social) with their items, external links (VK/Discord/Iteration), navigation to the existing home/
analysis/profile stub pages, the reshaped Account menu (fixed header, My Profile/Preferences/
Log In stub), icons for every menu-bar item, and a project-local `.haxefolio-menubar .icon` CSS
override (first CSS/theme resource in this project).

Everything below is still open.

## 1. < Removed >

## 2. Create Game / Versus Bot / Watch Player / Player Profile stubs

**Why deferred:** each used to open a `Dialogs.*` popup — `ChallengeParamsDialog` (Create
Game, Versus Bot with anaconda params) or a plain `Dialogs.prompt` login-input (Watch Player,
Player Profile) — and no dialog/overlay equivalent exists yet for any of them.

**How to apply:**
- Create Game / Versus Bot: build as `HaxeFolioApp.showOverlay()` overlays per
  `[[home_page_deferred]]` item 2 (already tracks the Create Game button's own stub on Home —
  this menu item and that button should end up calling the same real entry point once built).
- Watch Player / Player Profile: need a simple login-input prompt overlay — smaller in scope than
  the challenge-params dialog, but no generic "prompt for a string" overlay utility exists in
  `haxefolio` yet (only `showOverlay` with a full custom content factory). Worth checking whether
  a small reusable prompt-overlay helper belongs in `haxefolio` itself (used by more than one
  future page) before building a one-off.
- All four handler stubs are named (`onCreateGamePressed`, `onVersusBotPressed`,
  `onWatchPlayerPressed`, `onPlayerProfilePressed` in `Main.hx`) specifically so they're easy to
  find and fill in later — bodies currently empty.

## 3. Challenge notification widget (`challengesMenu`)

**Why deferred:** the old `gfx.menubar.ChallengeList`/`ChallengeMenuIcon` (incoming/outgoing
challenge list, live-updated via WS, blinking on incoming challenge) is its own subsystem that
depends on login (whose challenges are "mine") and a dedicated WS channel — not just menu
configuration.

**How to apply:** once login exists, this would be a `Widget(componentFactory, true)`
menu-bar-only entry (per `haxefolio.menu.MenuBarItem.Widget` — note `SideBarBuilder` never mirrors
`Widget` items into the sidebar, so the mobile sidebar would need its own equivalent if this
needs to be reachable on mobile too, unlike every `NormalMenu` here which mirrors automatically).
Sits between the last left-side `NormalMenu` and the Account menu on the right, per the old
layout (`scene_template.xml`: `<challenge-list id="challengesMenu" />` right before
`<menu id="accountMenu">`).

## 4. In-game menu disabling

**Why deferred:** the old `Scene.setIngameStatus` disabled almost every menu bar
control (all four `NormalMenu`s, the site name, log in/out/profile buttons) while the player was
in a live game, re-enabling on `GameEnded`/reconnect. No live-game-state tracking exists anywhere
in this project yet (that's the entire point of `[[home_page_deferred]]`'s still-unbuilt
`LiveGamePage`).

**How to apply:** revisit once `LiveGamePage` and a real WS-driven "am I currently in a game"
signal exist. `haxefolio` has no built-in "disable menu bar" facility — would need either a new
`MenuFacade` method or direct `.disabled` toggling via `findComponent` on `MenuFacade.menuBar`/
`sideBar`, mirroring the old code's `siteName.disabled = ingame` etc. approach but through
whatever public surface `MenuFacade` ends up exposing.

## 5. < Removed >

## 6. `log_out.svg` icon not ported

**Why deferred:** the `log_in_out` Account item never reaches its "logged in" visual state this
pass (see item 1), so there's nothing to show the icon on.

**How to apply:** copy `Intellector/assets/symbols/upper_menu/account/log_out.svg` to
`assets/images/menubar/account/log_out.svg` alongside `log_in.svg` when building the real
shapeshifting behavior.
