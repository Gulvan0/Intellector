---
name: haxeui-fix
description: Fix a bug in haxeui-core end to end - verified single-XML repro, user approval, a one-commit upstream PR from its own fork branch, the watchlist entry in knowledge/haxeui_pending.md, and the fix reaching the local lib only through scripts/sync_haxeui_core.sh. Use whenever a HaxeUI bug is suspected, a haxeui-core fix is proposed, or an upstream HaxeUI PR needs to be opened.
---

# HaxeUI bug fix

The branch model and the rebuild script are described in `knowledge/haxeui_pending.md` ("Fork
workflow"); read it first. This skill is the procedure on top of it. Every step ends with a check;
don't move on until it passes.

Paths used below:

- `LIB` - the haxeui-core checkout: `$(haxelib libpath haxeui-core)`. Remotes: `origin` (fork), `upstream`.
- `SKILL` - this skill's directory (`.claude/skills/haxeui-fix`).
- `SCRATCH` - the session's scratchpad directory. Repro builds go to `$SCRATCH/haxeui-repro/<name>`.

Scope: haxeui-core only. A bug in haxeui-html5 (no fork) or elsewhere: stop after step 2 and ask
the user how to proceed.

## 0. Preconditions

- `git -C "$LIB" status -sb` shows a clean checkout on `intellector`, level with `origin/intellector`.
  If not, stop and report it - never stash or reset it on your own.
- `gh auth status` works.

## 1. Pin down the root cause

Read the haxeui-core source (and the backend's, if rendering is involved) until you can quote the
offending lines and explain the mechanism. Compare with the code next to it - asymmetries (width
vs height, left vs top, leading vs trailing) are a frequent cause. Check `upstream/master`, not
only the local checkout: the bug may already be fixed upstream, which calls for a sync instead
(see "Already fixed upstream" below).

**Check:** you can name the file, function and lines, and say why they're wrong.

## 2. Repro

Write one XML file, as small as possible, that shows the bug with the default theme and no app code.

- If the bug isn't visible on screen, make the XML measure it: a `<button>` whose `onclick`
  scriptlet writes the relevant values into a `<label>` (e.g.
  `onclick="result.text = 'height ' + target.height"`; methods like `getTextDisplay()` are callable).
  Give the result label enough width that its text isn't cut off.
- Don't rely on sizes that the default theme or HaxeUI's defaults change: boxes have 5px spacing,
  a `scrollview`'s contents have padding, many components have borders. Set them explicitly or
  avoid depending on them.
- The symptom you saw in the app may come from something outside HaxeUI (e.g. haxefolio's
  `ScrollArea` uses native CSS overflow, HaxeUI's `ScrollView` doesn't). The repro must show
  HaxeUI's own misbehaviour, not the app's symptom.

Build it against upstream and look at it:

```bash
bash "$SKILL/build_repro.sh" repro.xml "$SCRATCH/haxeui-repro/<name>" upstream/master
python -m http.server 5600 --bind 127.0.0.1 --directory "$SCRATCH/haxeui-repro"   # background
```

Open `http://127.0.0.1:5600/<name>/` in the browser (refresh past the cache after each rebuild:
`fetch('repro.js', {cache: 'reload'})`, then reload). Take a screenshot before interacting and
click real coordinates: DOM lookups scripted right after navigation race HaxeUI's startup and
find nothing.

**Check:** the bug shows in the built repro on `upstream/master`. Write down the exact observed
output (numbers, text, what's visible) - it goes into the PR verbatim.

## 3. Approval

CLAUDE.md requires approval for fixing third-party code. Present to the user: the root cause
(quoted lines), the repro XML and its observed output, the proposed diff, and the app-side
workaround that would be needed otherwise. Ask; wait for a yes.

## 4. Fix branch

```bash
git -C "$LIB" fetch -q upstream
git -C "$LIB" switch -c upstream-pr/<slug> upstream/master
```

Make the smallest change that fixes the root cause, matching the surrounding code. Keep the file's
line endings (haxeui-core files are mostly CRLF; check with `file`). Then:

```bash
git -C "$LIB" add <changed files>
git -C "$LIB" commit -F <message file>   # summary line + why; end with the session's Co-Authored-By line
```

**Check, all three:**

- `git -C "$LIB" rev-list --count upstream/master..HEAD` is `1`;
- `git -C "$LIB" diff --stat upstream/master HEAD` lists only the intended files and line counts;
- `git -C "$LIB" status --porcelain` is empty (nothing left unstaged).

Don't push yet.

## 5. Verify

1. Repro, before and after - on exactly what the maintainer will compare:

   ```bash
   bash "$SKILL/build_repro.sh" repro.xml "$SCRATCH/haxeui-repro/<name>-before" upstream/master
   bash "$SKILL/build_repro.sh" repro.xml "$SCRATCH/haxeui-repro/<name>-after" upstream-pr/<slug>
   ```

   **Check:** "before" shows the bug, "after" doesn't, and the observed outputs are written down.
   If the repro needed changing, rebuild and recheck both.

2. The app, on the full pending set plus the fix:

   ```bash
   git -C "$LIB" switch intellector
   git -C "$LIB" merge --squash upstream-pr/<slug>
   git -C "$LIB" commit -m "TEST ONLY: <slug> (not yet a PR)"
   ```

   Remove the app-side workaround if there is one, `haxe build.hxml --debug`, and check in the
   browser that the original symptom is gone and nothing around it regressed.

   **Check:** symptom gone, no console errors, unit tests (`haxe test.hxml`) pass. Note
   `git -C "$LIB" rev-parse HEAD^{tree}` - the tested tree.

## 6. Publish

1. `git -C "$LIB" push -u origin upstream-pr/<slug>`
2. Write the PR body from `$SKILL/pr_template.md`, using the repro exactly as built and the outputs
   exactly as observed. Claim nothing you didn't see.
3. `gh pr create -R haxeui/haxeui-core --base master --head Gulvan0:upstream-pr/<slug> --title "<summary line>" --body-file <body file>`

**Check:** `gh pr view <N> -R haxeui/haxeui-core --json commits,files` shows one commit and only
the intended files.

## 7. Watchlist

Add a line to the "PRs" section of `knowledge/haxeui_pending.md`:

```
https://github.com/haxeui/haxeui-core/pull/<N> - <what it fixes, in a few words> (`upstream-pr/<slug>`); <what in the app or haxefolio depends on it>
```

If an entry under "Issues" or "Not yet filed upstream" described the same bug, update or remove it.

## 8. Sync

```bash
bash scripts/sync_haxeui_core.sh
```

It replaces the TEST ONLY commit with the one sourced from the new PR.

**Check:** `git -C "$LIB" rev-parse origin/intellector^{tree}` equals the tested tree from step 5.
If not, find out why before going further. Then rebuild the app once more.

## 9. Report

Tell the user: the PR link, the root cause in a sentence, the before/after outputs, what was
verified in the app, which workaround was removed, and the watchlist change. Leave the commits in
the Intellector repo to the user unless asked.

## Already fixed upstream

If `upstream/master` already has the fix (step 1): run `scripts/sync_haxeui_core.sh` to pick it
up, verify in the app, remove the workaround, and close any open issue of ours about it only after
confirming the upstream code actually changes the lines the issue names.

## When a PR of ours gets merged

Run `scripts/sync_haxeui_core.sh` (the PR drops out by itself), remove its line from
`knowledge/haxeui_pending.md`, and rebuild and check the app.
