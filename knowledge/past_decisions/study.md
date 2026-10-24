# Study mode of the analysis page

Source design: the "Studies" row of the "Intellector analysis page" canvas
(https://claude.ai/artifact/HJeq5PMdPCiaaTTW2DTBEw): `Study`, `StudyPhone`, `StudyInfoPhone`,
`StudyVisitor`, `StudyCreate`, `StudyCreatePhone`, `StudyMedium`, `StudyEdit` artboards, all
driven by `Main.dc.html`. Builds on `[[analysis]]` (past decisions).

## Decisions

1. **Key node persistence**: the server gets a nullable `key_path` (same run-length path format as
   node paths). Null = no marked node: the card preview is the end of the main line (first
   children from the root down), drawn with the dashed "by default" badge. `key_sip` is still sent
   (the position of the effective key node), for the cards. `key_path` is only meaningful with the
   nodes, so a PATCH that carries `nodes` always replaces `key_path` too (null clears it); a PATCH
   without `nodes` leaves it.
2. **Loading `/study/<id>`**: the layout renders at once with a single-root tree, locked like in the
   editor. The study slot (wide card, medium Study tab, compact study bar) shows a `LoadStatus`,
   then the failure with Retry. Not found (404), private (403) and deleted (`deleted: true`) show a
   message in the slot instead, and the page unlocks as a plain analysis board.
3. **URL after Create / Delete study**: a new generic `HaxeFolioApp.replacePath(path)`
   (`history.replaceState`, no re-init) swaps to `study/<newId>` / `analysis` in place.
4. **Guests**: "Save as study" / "Save as new study" stay visible; pressing one opens the login
   overlay, and the create overlay opens once the identity becomes a player.
5. **Tags** in the study card and sheet: buttons with the "Studies by X tagged Y" tooltip, doing
   nothing (`[[study_deferred]]` 1).
6. **Unsaved changes**: the browser's `beforeunload` prompt while the owner has unsaved changes.
   In-app navigation is not guarded.
7. **Request failures** (Save changes, Create, details Save, Delete study): inline where pressed -
   the card's / sheet's save hint, or the overlay footer, in the danger colour; the button becomes
   usable again; the overlay stays open with its input.
8. **Tab title**: the study title with the id while loading, the study's name once loaded (renames
   update it).
