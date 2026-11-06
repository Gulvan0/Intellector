This project is a frontend for the Intellector board game website. See @README.md for the overview.

ANY AMBIGUITY OR DESIGN DOC GAP SURFACING DURING THE IMPLEMENTATION SHOULD NOT BE RESOLVED SILENTLY. Instead, explicitly ask the question.

If told to take a dubious or possibly suboptimal approach (whether from the UI/UX or technical standpoint), also ask a question, providing details on why you're uncertain about this and what are the better practices or better ways to solve the problem.

`haxe build.hxml --debug` builds the project: first the engine web worker (`hxconda.hxml`, into `bin/hxconda.js`, never in debug mode), then the app (`bin/app.js`). `haxe hxconda.hxml` builds the worker alone. To test in a browser, first try `127.0.0.1:5500` instead of running your own webserver - most of the times the live server serving `index.html` has already been open.

See @code_style.md for code style conventions.

# Library edits

The source files of `haxefolio`, `morestd`, `intellectorboard`, `jsonmodel`, `easyrest`, `easypubsub` may be freely edited, but the libraries should remain independent and universal, not tailored to the frontend code specifically.

`HaxeUI`, `http`, `hxWebSockets`, `json2object` are third-party libraries. They may have bugs, but such bugs should be identified with care and special approval is needed for implementing the fixes. Each bug found needs to be demonstrated with a minimal reproducible example. For `HaxeUI`, this example should be a single XML file that defines a component eliciting the problem.

`haxeui-core` is used from the `intellector` branch of the `Gulvan0/haxeui-core` fork: upstream master plus the open fix PRs. Its local checkout must never hold uncommitted changes; fixes go through per-PR branches and `scripts/sync_haxeui_core.sh`. See @knowledge/haxeui_pending.md for the workflow.

# Knowledge base

@knowledge/ holds design docs.

Do not incorporate @knowledge/todo.md into your reasoning and do not edit it; this is a human-only checklist. Other docs are at your full disposal; you may read and edit them as you will.

@knowledge/backlog.md should only have tiny descriptions, not elaborate by any margin. They do not describe the implementation, they just clarify what the header means.
