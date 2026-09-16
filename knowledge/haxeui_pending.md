# PRs

https://github.com/haxeui/haxeui-core/pull/701
https://github.com/haxeui/haxeui-core/pull/703

# Issues

https://github.com/haxeui/haxeui-core/issues/702
https://github.com/haxeui/haxeui-core/issues/704

- A CSS rule with a **compound/chained pseudo-class selector** (two pseudo-classes on one
  selector, e.g. `.button:down:disabled`) corrupts an earlier, unrelated `:down`-only rule in the
  same stylesheet - not just failing to match itself. Found while building `haxefolio.form`'s
  `ChoiceButton` (a toggle `Button`): a `.haxefolio-choice-button:disabled` rule combined with
  `.haxefolio-choice-button:down:disabled` (added so a selected-but-disabled button unambiguously
  fell back to the disabled look) made the separate, preceding `.haxefolio-choice-button:down`
  rule stop applying entirely for every selected-and-enabled button too, even though those buttons
  never match `:disabled`. Removing the compound selector - relying on plain CSS source-order
  precedence instead, since `:disabled` already comes after `:down` in the file - fixed it with no
  other change. Not yet reported upstream or fixed in the fork; the workaround (avoid chained
  pseudo-classes, order same-specificity rules so the one that should win comes last) is enough for
  now. Minimal repro: [haxeui_compound_pseudo_selector_repro.xml](haxeui_compound_pseudo_selector_repro.xml).

# Fixed in the fork, PR'd upstream

- `FocusManager.enabled` not respected in the focus setter (click-driven
  `:active` styling bypasses it) - see
  [haxeui_focusmanager_enabled_repro.md](haxeui_focusmanager_enabled_repro.md).
  Fixed in the fork (`Gulvan0/haxeui-core`), commit `145c418b`, merged into
  the fork's `master` via PR
  https://github.com/Gulvan0/haxeui-core/pull/2. Submitted upstream as
  https://github.com/haxeui/haxeui-core/pull/709.
