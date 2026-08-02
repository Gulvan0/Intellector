This project is named `Intellector Frontend v3.0` and it is a sandbox for the future iteration of the Intellector board game website (frontend). It will be used to rebuild this project from scratch, improving on the previous iteration.

ANY AMBIGUITY OR DESIGN DOC GAP SURFACING DURING THE IMPLEMENTATION SHOULD NOT BE RESOLVED SILENTLY. Instead, explicitly ask the question.

If told to take a dubious or possibly suboptimal approach (whether from the UI/UX or technical standpoint), also ask a question, providing details on why you're uncertain about this and what are the better practices or better ways to solve the problem.

`haxe build.hxml --debug` builds the project.

# Tech stack

This project will be written in `Haxe` targeting `HTML5` using the `HaxeFolio` framework.

Used libraries:
- `morestd` - reusable utilities. Most other libraries in this list depend on this one.
- `haxefolio` - main UI framework / website engine; it is built over the `HaxeUI` library (`haxeui-core` plus its `haxeui-html5` backend).
- `intellectorboard` - game rules and abstractions (board fields, pieces, positions, plys etc.)
- `jsonmodel` - macro-powered automation around `json2object` library. Generated serializers and deserializers for DTOs
- `easyrest` - wrapper around `http` lib allowing to define endpoints in a strictly typed manner and getting rid of associated boilerplate. Depends on `jsonmodel` for endpoint payload parsing and dumping.
- `easypubsub` - wrapper around `hxWebSockets` lib allowing to define PubSub channels and messages published to them in a strictly typed manner and getting rid of associated boilerplate. Depends on `jsonmodel` for parsing and dumping message payloads and channels.

The source files of `haxefolio`, `morestd`, `intellectorboard`, `jsonmodel`, `easyrest`, `easypubsub` (located in `C:/Users/mitmi/Documents/GitHub/Libraries/<library name>`) may be freely edited, but the libraries should remain independent and universal, not tailored to `Intellector Frontend v3.0` specifically.

`HaxeUI`, `http`, `hxWebSockets`, `json2object` are third-party libraries. They may have bugs, but such bugs should be identified with care and special approval is needed for implementing the fixes. Each bug found needs to be demonstrated with a minimal reproducible example. For `HaxeUI`, this example should be a single XML file that defines a component eliciting the problem.

# Project structure

Source code folder (`src`):

- `client` - code specific to the client
    - `client.botengine` - wrappers around engines for playing against the computer
    - `client.datatypes` - types commonly used in a client-only code
    - `client.openings` - opening database
    - `client.ui` - everything UI-related
        - `client.ui.<page>` - every component related to the specific page, plus the page class itself. May be organized into the subpackage structure in arbitrary way; should be - if the number of package members grows large.
        - `client.ui.common` - components shared by more than one page
    - `client.utils` - utilities that, unlike libraries, bear no use outside of this app
- `net` - everything related to networking
    - `net.models` - DTOs, divided into subpackages by domain. Domain packages may have `mappers` subpackage containing converters between types in `client.datatypes`/`lib.intellectorboard` and DTOs in that domain
    - `net.rest` - REST endpoint definitions and REST client
    - `net.ws` - Websocket channel and event type definitions and PubSub client

Assets folder (`assets`):

- `favicons` - website icons
- `images` - all image assets
- `layouts` - all XML layouts for the HaxeUI components
- `locale` - HaxeUI/HaxeFolio locale `.properties` files
- `resources` - static configuration files, most often JSON ones
- `styles` - all CSS HaxeUI/HaxeFolio styling (except for when it's so short it's embedded into the XML layout)

`images` and `layouts` should be divided into subfolders by pages making use of these images and components.

# Transition

Overall, the transition will be performed page-after-page. The page will usually be thoroughly tested before the next one will be taken into work.

The previous iteration is located in `C:/Users/mitmi/Documents/GitHub/Intellector`. It is currently in the inconsistent state; additionally, building the project fails. Some modules may already be missing from the repo due to either being moved there or deprecated.

The original version can be used as a declarative reference (answering how the result is expected to look like, minus the ill-designed aspects), but the concrete approaches and decisions chosen may and should be subject to being questioned.

## Original version VS v3.0

What used to be "screens" became HaxeFolio pages. Being navigated to a screen used to look like this: send the request, wait until the response, then build a screen using the response data.

Now being navigated to a page should instead be: go to a page - those components that need data from the server will display the "loading" state, send requests as part of the initialization, then, when a response arrives, updates the components depending on it. If the response doesn't arrive in time, the components that were in a "loading" state should display the error and give the option to retry. Same should happen when the request results in an error.

Generally, if the components are interested in different, non-intersecting things, a separate request per each such component is emitted and the responses get processed as they arrive. For example, on the home page there is an open challenges table and a current games table, the requests getting open challenges and current games are separate and each of their callbacks updates only one, respective, table.

The old `Scene.setIngameStatus` disabled almost every menu bar control (all four `NormalMenu`s, the site name, log in/out/profile buttons) while the player was in a live game, re-enabling on `GameEnded`/reconnect. This should NOT be replicated in v3.0. The user will now be able to leave an active game whenever they like it.

All networking-related stuff must be replaced with the usage of rest operation objects defined in @src/net/rest/RestOperationRegistry.hx (use @src/net/rest/Rest: `Rest.client().execute(...)`) and `PubSub.sub()` method (followed by `on*Event*` method calls: one per each handler that needs to be attached).

Some of the old approaches related to retrieving the data and interacting with the server have been reworked. If unsure, consult the server repo located at `C:/Users/mitmi/Documents/GitHub/IntellectorServerV2` (though the contents of @src/net/ws package should usually be more than enough).

Reject the old responsive design approaches, including `ResponsiveToolbox/ResponsivenessRule`. Font size should be constant. Widths/heights should be either exact or percentage-based.

Dialogs should be replaced with the overlays by making use of HaxeFolio's `HaxeFolioApp.showOverlay()`.

The old frontend dealt solely with the logins. Now the server API always returns login-nickname bundles. In every visual context, a nickname should be used. The login, on the other hand, should be used to unambiguously refer to the player programmatically, for example, in REST and WS networking.

If the source code of the previous iteration does not match the style guide, reformat it freely. If it violates some principles stated in this file, ask how to fix it in V3.0.

Brief original project structure overview:

- `assets` (inside `src` folder) - utilities for working with assets
- `dict` - localization. It's a deprecated approach and in `Intellector Frontend v3.0`, the locale strings/templates should be rewritten using the HaxeUI/HaxeFolio localization capabilities
- `engine` - wrappers around engines for playing against the computer. It should be reimagined, purged, rewritten and put inside the `client.botengine` package
- `gfx` - UI (screens and components). Somewhat splitted into the subpackages by screens, but not 100% consistently.
    - `gfx.common` - components shared by multiple screens
    - `gfx.basic_components` - components shared by multiple screens, also containing a lot of ill-designed responsivity utilities (do NOT mimic those approaches in the new iteration)
    - `gfx.popups` - dialog windows and notifications. Most should be replaced with the bottom SideBars on mobile.
    - `gfx.screens` - just the screen classes. The associated components live in the respective subpackages
    - `gfx.preloader` - preloader animation wrapper
    - `gfx.menubar` - what needs to become HaxeFolio MenuBar widgets
    - `gfx.utils` - utilities

# Code style conventions

See `code_style.md`.
