# Share overlay

Source design: the "Share menu" canvas (https://claude.ai/artifact/TvrhphJZoaR4pjZfjeXDU1), the
`Main.dc.html` reference component and its four mounts; handoff note
https://claude.ai/artifact/DXZabSzRkFUdAmvsc2Lw6H. Deferred: `[[share_overlay_deferred]]`.

One overlay, opened by the Share action of the live game page and of the analysis page. Its groups
are tabs built from descriptors: Share position (both pages), Share game (live only). With one
group the tab strip is left out.

## Decisions taken with the user (2026-10-20)

1. **HaxeFolio presentation.** `HaxeFolioApp.present` as is: the expanded dialog (with the
   framework's scrim) and, collapsed, the sheet covering the whole screen (no 20 px peek).
2. **Tabs are `Region.Tabs(Choose, ...)`**, drawn as HaxeFolio's segmented control, not the
   design's separate outlined chips.
3. **Exports render client-side.** The preview and the file come from one renderer: the board's own
   `BoardSurface` SVG, pieces inlined as data URIs, rasterized onto a canvas. PNG through
   `canvas.toBlob`.
4. **GIF encoding: gifenc 1.0.3** (MIT), vendored under `assets/vendor/gifenc/`, loaded by a module
   shim in `index.html` that puts it on `window.gifenc`. Haxe externs in `client.utils`.
5. **No Transparent toggle for GIF** (1-bit transparency gives aliased edges): its Background row
   holds only the colour field.
6. **GIF frames:** the starting position, then one frame per ply, each with that ply highlighted in
   the board's `LastMove` tint; every frame lasts the interval, the last one 3x. Oriented as the
   board is when the overlay opens.
7. **GIF busy state:** while encoding, the button is disabled and reads "Generating… N%"; frames
   are encoded one per tick, so the page stays responsive. The panel's settings lock meanwhile.
8. **PNG last-move highlight is a checkbox** in Other ("Highlight last move"), disabled in place
   when the shown position has no last move. The image panel gets taller and the frame heights
   are recomputed.
9. **PIN outcome line:** a PGN-like token, then the reason in English in brackets: `1-0 (Fatum)`,
   `1/2-1/2 (Repetition)`. Abort is `-`, an ongoing game `*`.
10. **`CheatingAbort` becomes a decisive outcome** (the migrator gives those games a winner); the
    mapper stops folding it into `Abandon`.
11. **Snapshot at open.** SIP, PIN and both exports reflect the moment the overlay opened.

## Decisions taken without asking (defaults, open to change)

- Shared position: the one shown on the board (the navigated ply on the live page, the selected
  node on the analysis page), with its last ply. Not available while the analysis editor is open
  (the actions card is hidden then).
- Game link: the absolute URL of `live/<id>`, built by a new `HaxeFolioApp.pageUrl`.
- Default sizes follow the board's aspect with labels: image 800 wide, GIF 480 wide; background
  `surface` (`#faf7f2`), interval 400 ms, link on, labels on, highlight on.
- Labels on = `BoardCoordinatesMode.ALL`. The file letters (drawn on the background) use
  `inkMuted` on light backgrounds and `#e9e3d9` on dark ones, or on a transparent one, `inkMuted`.
- The board is fitted (contain) into width x height with a margin of 3% of the shorter side.
- File names: `intellector-position.png`, `intellector-game-<id>.gif`.
- No keyboard navigation or initial focus (keyboard focus was dropped app-wide).
- The settings column is 304 wide, not 290: at 290 a size field's header can't hold "Height" beside
  "must be 64–4096".
- Exported labels use the bold `sans-serif` the board on the page inherits, not Onest, so a picture
  looks like the board.

## Library changes (universal, not app-specific)

- haxefolio `HaxeFolioApp.pageUrl(path, ?fragment)`: the absolute URL `navigateTo` would show.
- haxefolio `form.TextInputField.setSuffix(text, laneWidth)`: the mirror of `setPrefix`, for units.
- haxefolio `form.CopyField`: a FieldHeader, a read-only value (single line, or a fixed-height
  multiline box) selected whole on focus, and a fixed-width Copy button that reads Copied for
  1.6 s; falls back to `execCommand("copy")` when the Clipboard API refuses.
- haxefolio `form.ColorField`: a FieldHeader over one input-like box holding a native colour swatch
  and the hex text; disabling it dims the swatch and shows a placeholder instead of the hex, the
  stored colour kept.
- haxefolio `browser.FileDownload.save(blob, fileName)`.

## App

- `client.datatypes.share`: `ExportKind` (Image/Animation), `ExportSettings` (the texts as typed,
  the ratio, colours, flags), `ShareSnapshot` (position, orientation, last ply; for a game the
  info, plies and ending).
- `client.logic.share.ExportSettingsRules`: parsing and ranges (size 64-4096, interval 50-5000,
  `#RRGGBB`), proportional propagation, the last valid size for the preview, validity.
- `client.formatters.PinFormatters`: the PIN (via `intellectorboard`'s `GamePinFormatter`) and its
  outcome token.
- `client.ui.common.board.export.BoardRaster`: renders a board picture of any size onto a canvas,
  asynchronously, latest-request-wins; `BoardAnimation`: the GIF, one frame per tick.
- `client.ui.common.overlays.share`: `ShareOverlay` (present, groups), `ShareGroup` descriptors,
  `SharePositionPage`, `ShareGamePage`, `ExportPanel` (both kinds), `SizeRow` (two fields and the
  proportions link), `ExportPreview` (canvas, checkerboard under a transparent export, 1 px outline).
- Both pages' `onShare` open it.

## Heights

Declared, never measured, in `StyleVars`: the frame is header + tab strip + body padding + the
tallest page (Share game), the analysis frame without the strip and with Share position. Body:
18 top/bottom, 22 sides, sections 18 apart, label 16 + 5 above each control.

## Verification

Build; then in the browser at 1:1 per component: both tabs, both pages, wide and narrow, every
state (invalid size/hex/interval, link on/off, transparent, labels and highlight off, Copied, GIF
in progress), Russian. Compare against the design. Download a PNG and a GIF and open them. DOM audit
for unstyled labels and clipped text.
