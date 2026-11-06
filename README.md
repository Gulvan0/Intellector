<img width="1277" alt="image" src="https://github.com/user-attachments/assets/74f8cf58-1227-48bb-929e-fed3e123717d">

This project is an HTML5 client for Intellector, an exciting board game for 2 players.

<br />

Live version - https://intellector.info/game/?p=home

Join us on Discord - https://discord.gg/5ycEqRS8Es

Server repo - https://github.com/Gulvan0/IntellectorServer

# Technologies

This project is written in `Haxe` targeting `HTML5` using the `HaxeFolio` framework and making heavy use of JS Web APIs.

## Used libraries

**In-house libs:**

- [morestd](https://github.com/gulvan0/morestd) - reusable utilities. Most other libraries in this list depend on this one.
- [haxefolio](https://github.com/gulvan0/haxefolio) - main UI framework / website engine; it is built over the `HaxeUI` library (`haxeui-core` plus its `haxeui-html5` backend).
- [intellectorboard](https://github.com/gulvan0/intellectorboard) - game rules and abstractions (board fields, pieces, positions, plys etc.)
- [jsonmodel](https://github.com/gulvan0/jsonmodel) - macro-powered automation around `json2object` library. Generated serializers and deserializers for DTOs
- [easyrest](https://github.com/gulvan0/easyrest) - wrapper around `http` lib allowing to define endpoints in a strictly typed manner and getting rid of associated boilerplate. Depends on `jsonmodel` for endpoint payload parsing and dumping.
- [easypubsub](https://github.com/gulvan0/easypubsub) - wrapper around `hxWebSockets` lib allowing to define PubSub channels and messages published to them in a strictly typed manner and getting rid of associated boilerplate. Depends on `jsonmodel` for parsing and dumping message payloads and channels.

**Third-party libs**, used mostly for powering the in-house frameworks above:

- [HaxeUI](https://github.com/haxeui/haxeui-core) (UI) - NOTE: used from the `intellector` branch of the `Gulvan0/haxeui-core` fork, holding fixes still awaiting approval
- [http](https://github.com/core-haxe/http) (REST)
- [hxWebSockets](https://github.com/ianharrigan/hxWebSockets) (WS)
- [json2object](https://github.com/elnabo/json2object) (serialization)

# Contributing

Code style rules are listed in `code_style.md`.

Non-obvious terms used in code:

- `Hex` - a single field on a board that may or may not be occupied by a piece
- `SLU` - Side Length Units, used for values measured relative to the length of hex's side. The latter varies as the board is responsive and may shrink and stretch arbitrarily as long as the aspect ratio is maintained.

## Project structure

### Source code folder (`src`)

- `client` - code specific to the client
    - `client.build` - the build ID macro, which also writes `bin/version.json`
    - `client.botengine` - wrappers around engines for playing against the computer
    - `client.datatypes` - types commonly used in a client-only code, divided into subpackages by domain (`challenge`, `game`, `timecontrol`, `board`, ...). Holds classes centered around instances: data, plus instance-bearing state like `ChallengeInbox`
    - `client.logic` - classes centered around static members (rules, parsing, ordering) operating on `client.datatypes`, mirroring its domain subpackages
    - `client.storage` - local storage keys, typed readers/writers of persisted client state
    - `client.migration` - one-time carry-overs from the previous iteration: its cookies into localStorage, its URL forms into the current ones
    - `client.update` - the API version mismatch reload and the watcher that reloads into a newer build
    - `client.errors` - reporting the errors that would otherwise only reach the console
    - `client.tabs` - browser tab coordination: blinking, cross-tab hand-offs via focus and storage events
    - `client.openings` - opening database
    - `client.ui` - everything UI-related
        - `client.ui.<page>` - every component related to the specific page, plus the page class itself. May be organized into the subpackage structure in arbitrary way; should be - if the number of package members grows large.
        - `client.ui.common` - components shared by more than one page
    - `client.utils` - utilities that, unlike libraries, bear no use outside of this app
- `net` - everything related to networking
    - `net.models` - DTOs, divided into subpackages by domain. Domain packages may have `mappers` subpackage containing converters between types in `client.datatypes`/`lib.intellectorboard` and DTOs in that domain
    - `net.rest` - REST endpoint definitions and REST client
    - `net.ws` - Websocket channel and event type definitions and PubSub client
- `engine` - game engines. Each one is self-contained (no `client`/`net` dependencies, no HaxeUI) and runs in a web worker compiled as its own JS target
    - `engine.hxconda` - Hxconda, the Haxe port of the previous iteration's Anaconda bot engine. The client starts searches through `HxcondaEngine`, which spawns the `bin/hxconda.js` worker (main class `HxcondaWorker`) and exchanges `engine.hxconda.protocol` messages with it. Inside the search everything is plain integers and flat arrays: `intellectorboard` types are too slow there, so conversion to them belongs to the client side
        - `board` - position state, piece and move encodings, movement tables, move generation
        - `evaluation` - static evaluation terms, per bot style; `StyleBonuses` - the styles' move preferences at the root
        - `search` - the alpha-beta search and its tables; `search.budget` - what stops a search (node count, time or depth) and how it reports progress; `search.weakening` - how a bot below full strength picks a worse move among the scored root moves
        - `protocol` - worker messages and their encoding/decoding

### Assets folder (`assets`)

- `favicons` - website icons
- `images` - all image assets
- `layouts` - all XML layouts for the HaxeUI components
- `locale` - HaxeUI/HaxeFolio locale `.properties` files
- `resources` - static configuration files, most often JSON ones
- `styles` - all CSS HaxeUI/HaxeFolio styling (except for when it's so short it's embedded into the XML layout)
- `vendor` - third-party JS loaded by `index.html`, one folder per library with its license (`gifenc` for GIF exports)

`images` and `layouts` should be divided into subfolders by pages making use of these images and components.

### Scripts folder (`scripts`)

Developer tooling, not part of the build:

- `sync_haxeui_core.sh` rebuilds the haxeui-core fork's `intellector` branch.
- `hxconda/` - Node tooling for the Hxconda engine, run on `bin/hxconda.js`; `hxconda/reference/position.js` is the frozen original Anaconda:
    - `compare.js` checks that Hxconda posts exactly the same messages as the reference under the same seeded randomness and mocked clock. A change meant to keep the engine's behavior (a pure speedup or refactoring) must pass it.
    - `compare.js --baseline` compares against `hxconda/baseline/hxconda.js`, the last accepted build, instead.
    - `bench.js` measures the speed of node-limited searches against the reference; `bench.js --record "<label>"` appends the result to `hxconda/benchmark_results.md`.
    - `match.js` plays the build against the baseline from the openings in `hxconda/openings.json` until an SPRT decides whether it is stronger; `--record "<label>"` appends the result to `hxconda/match_results.md`.
    - `isolation.js` (Windows) pins timing runs (`bench.js`, `match.js --time`) to dedicated performance cores at high priority, and moves node-limited runs off `bench.js`'s cores at below-normal priority.

### Knowledge base (`knowledge`)

`knowledge` holds design docs, plans and records of past decisions.

It is useful to keep `knowledge/todo.md` locally as a to-do list; this file is excluded from checkout by `.gitignore`.

## Quick Start

Note: Server repo has its own Quick Start in [its own README](https://github.com/Gulvan0/IntellectorServer/blob/main/README.md). If you wish to work on the game server, make sure to follow it as well.

### 1. Install the tools

- `Haxe 4.3.x`
- `Node 22` (only needed for the Hxconda engine scripts in `scripts/hxconda/`)

### 2. Clone this repo

https://github.com/Gulvan0/Intellector

### 3. Install Haxe libraries

```
# in-house libs
haxelib git morestd          https://github.com/Gulvan0/morestd
haxelib git haxefolio        https://github.com/Gulvan0/haxefolio
haxelib git intellectorboard https://github.com/Gulvan0/intellectorboard
haxelib git jsonmodel        https://github.com/Gulvan0/jsonmodel
haxelib git easyrest         https://github.com/Gulvan0/easyrest
haxelib git easypubsub       https://github.com/Gulvan0/easypubsub

# HaxeUI: core from the fork's integration branch, html5 straight from upstream
haxelib git haxeui-core  https://github.com/Gulvan0/haxeui-core intellector
haxelib git haxeui-html5 https://github.com/haxeui/haxeui-html5

# networking: http depends on promises, logging and queues-core, so install those first
haxelib git promises     https://github.com/core-haxe/promises
haxelib git logging      https://github.com/core-haxe/logging
haxelib git queues-core  https://github.com/core-haxe/queues-core
haxelib git http         https://github.com/core-haxe/http
haxelib git hxWebSockets https://github.com/ianharrigan/hxWebSockets

# serialization, plus utest for the unit tests
haxelib install json2object 3.11.0
haxelib install hxjsonast
haxelib install utest
```

### 4. Build and serve the frontend

`haxe build.hxml --debug` builds the frontend using the test stage setup (requires a test game server running on the localhost). If you only want to work on the frontend, you can omit the `--debug` flag to connect to the game server living in production.

Serve the frontend via `python scripts/serve.py --bind 127.0.0.1` or the VS Code Live Server extension.

`haxe test.hxml` runs the unit tests.
