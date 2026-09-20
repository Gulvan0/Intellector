This file stores HaxeUI's unmerged PR's and unaddressed issues. Every item mentioned there affects the Intellector website negatively.

Changes proposed in the PR's are temporarily applied in the local fork of the HaxeUI. Issues are either circumvented by a workaround or, once again, by changes in the local branch.

As the PR's will get merged and issues resolved, the local branch should be rebased onto more recent versions of a master. The diff between local and master branches should get smaller while the workarounds should get reverted.

# PRs

https://github.com/haxeui/haxeui-core/pull/701
https://github.com/haxeui/haxeui-core/pull/703
https://github.com/haxeui/haxeui-core/pull/713

# Issues

https://github.com/haxeui/haxeui-core/issues/702
Workaround: fixed in the local haxeui-core fork (commit `ebc756a2`, branch `fix/vbox-hbox-trailing-margin`, fork PR #706): the layout cursor now adds child margins. haxefolio's form components rely on it (`verticalSpacing = 0` + header `margin-bottom`).

https://github.com/haxeui/haxeui-core/issues/704
Workaround: haxefolio's `MenuFacade.updateMenuLabelText` also sets `text` on `MenuBar`'s private proxy Button, found via `Reflect` on `menuBar._compositeBuilder._menus/_buttons`. Breaks if `MenuBar` internals change.
