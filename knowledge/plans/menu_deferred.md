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

## 3. < Removed >
