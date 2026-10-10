This file stores HaxeUI's unmerged PRs and unaddressed issues. Every item mentioned here affects the Intellector website negatively.

# Fork workflow (haxeui-core)

Repositories: upstream `haxeui/haxeui-core`, fork `Gulvan0/haxeui-core`. The local checkout is haxelib's dev dir (`haxelib libpath haxeui-core`) with remotes `origin` = fork and `upstream` = upstream.

Branches:

- **`upstream-pr/<slug>` (one per fix):** cut from `upstream/master`, containing only that fix; the head of exactly one upstream PR. It gets nothing but rebases of the fix itself (needed only if it stops merging cleanly). Exception: #703 still lives on `fix/stale-locale-binding-registration`.
- **`intellector` (published integration branch):** `upstream/master` + one squashed commit per *open* upstream PR from the fork, rebuilt from scratch by `scripts/sync_haxeui_core.sh` and force-pushed. `git log upstream/master..intellector` lists exactly the pending fixes. The local checkout always sits on it.
- **`master`:** mirrors `upstream/master`. Never a PR head, never carries fixes.

Rules:

- The local checkout never holds uncommitted changes (the script refuses to run otherwise). A fix reaches it only through its PR branch and a rebuild.
- **A new issue is found:** follow the `haxeui-fix` skill (`.claude/skills/haxeui-fix/`): verified single-XML repro, approval, a one-commit `upstream-pr/<slug>` branch, the upstream PR, an entry below, and `scripts/sync_haxeui_core.sh`.
- **A PR gets merged, or a new upstream feature is wanted:** run `scripts/sync_haxeui_core.sh`. Merged PRs drop out by themselves, open ones are re-applied onto the new upstream head. Then remove the PR from the list below and revert any app workaround that depended on it.
- **A PR stops applying:** the script stops and names it. Rebase that PR branch onto `upstream/master`, force-push it, and rerun.
- **A new developer:** `haxelib git haxeui-core https://github.com/Gulvan0/haxeui-core intellector`. To update after a rebuild (the branch is force-pushed, so `haxelib update` would merge old and new history): `git -C "$(haxelib libpath haxeui-core)" fetch origin`, then `git -C "$(haxelib libpath haxeui-core)" reset --hard origin/intellector`.

haxeui-html5 has no fork and is used straight from upstream.

# PRs

https://github.com/haxeui/haxeui-core/pull/703 - stale locale binding after reassignment (branch `fix/stale-locale-binding-registration`)
https://github.com/haxeui/haxeui-core/pull/713 - compound pseudo-class selectors (`upstream-pr/compound-pseudo-class-selector`); haxefolio's `:down:disabled` rules rely on it
https://github.com/haxeui/haxeui-core/pull/715 - `MenuBar.closeCurrentMenu()` (`upstream-pr/menubar-close-current-menu`); haxefolio's `MenuBarBuilder` calls it
https://github.com/haxeui/haxeui-core/pull/746 - `Menu.openPopup()`/`closePopup()` (`upstream-pr/menu-open-close-popup`; supersedes #701, which was opened from the fork's `master`); haxefolio's `NormalMenu` overrides `openPopup`
https://github.com/haxeui/haxeui-core/pull/747 - a fixed-height `Label`'s text display ignores vertical padding and overflows the label by `padding-top` (`upstream-pr/label-fixed-height-padding`); without it, `.intellector-challenge-list-empty` scrolls the challenges dropdown

# Issues

https://github.com/haxeui/haxeui-core/issues/704
Workaround: haxefolio's `MenuFacade.updateMenuLabelText` also sets `text` on `MenuBar`'s private proxy Button, found via `Reflect` on `menuBar._compositeBuilder._menus/_buttons`. Breaks if `MenuBar` internals change.

# Not yet filed upstream

- haxeui-html5's `ComponentImpl.handleSize` only applies a size when both
`width` and `height` are non-null (`if (width == null || height == null || width <= 0 || height
<= 0) return;`). A component sized purely via `percentWidth`, with no paired `percentHeight` or
explicit `height`, never gets even its width applied - it collapses to the browser's replaced-
element default size instead. Workaround: `haxefolio.graphics.SvgSurface` overrides `handleSize`
to derive `height` from the resolved `width` (via its fixed aspect ratio) whenever `height` comes
in null, before delegating to `super.handleSize`.
