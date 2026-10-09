<img width="1277" alt="image" src="https://user-images.githubusercontent.com/16256911/235146759-b9f3c4a4-80c7-4d7b-8238-c4d45d0f2293.png">

This project is an HTML5 client for Intellector, an exciting board game for 2 players.

<br />

Live version - https://intellector.info/game/?p=home

Join us on Discord - https://discord.gg/5ycEqRS8Es

Server repo - https://github.com/Gulvan0/Intellector-Server

## Technologies

Both client and server are written in Haxe 4.

Client-side targets HTML5 and makes heavy use of JS Web APIs.

Major frameworks are [HaxeUI](https://github.com/haxeui/haxeui-core) (UI) and [hxWebSockets](https://github.com/ianharrigan/hxWebSockets) (Multiplayer and Networking).

## Contributing

Code style rules are listed in `code_style.md`.

Non-obvious terms used in code:

- `Hex` - a single field on a board that may or may not be occupied by a piece
- `SLU` - Side Length Units, used for values measured relative to the length of hex's side. The latter varies as the board is responsive and may shrink and stretch arbitrarily as long as the aspect ratio is maintained.
