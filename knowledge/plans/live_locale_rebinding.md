# Live locale rebinding in tables

`Label.text`'s `"{{key}}"`
auto-resolution is a compile-time XML macro feature (`haxe.ui.macros.ComponentMacros.assignField`),
not generic runtime behavior — confirmed by reading `TextBehaviour.validateData`, which does a
verbatim `getTextDisplay().text = '${_value}'`. So `OpenChallengeRow.bracket` /
`CurrentGameRow.bracket` and the two custom renderers' `.tooltip` strings are resolved **once**,
at row-construction/render time, via `LocaleManager.instance.lookupString(...)`. Already-rendered
rows will not retranslate on a language switch without a table reload.

**How to apply:** not urgent since no language switcher UI is wired up yet either (see item 7).
If/when it matters, either have the tables re-`load()` on a `Preferences.language` change, or
design a general reusable "live-rebinding table cell" pattern before the next page that needs a
data-driven table (there will be several: challenge lists, game lists, study lists all follow the
same shape).
