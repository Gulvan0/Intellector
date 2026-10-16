# Analysis page: deferred

## 1. Studies

**Why deferred:** out of scope for this pass. `study/{id}` opens the same empty analysis board.

**How to apply:** `GET_STUDY` with the page's loading / error / retry states; build the tree with
`StudyPlyTreeMapper.fromDto` from `starting_sip` and `nodes`. Saving (`CREATE_STUDY`,
`UPDATE_STUDY`) uses `StudyPlyTreeMapper.toDto`; it needs its own UI (not designed).

## 2. Starting from a position or a game

**Why deferred:** out of scope for this pass; `[[live_game_deferred]]` 1 waits on it.

**How to apply:** an analysis route taking a SIP (or a game id and ply), seeding `PlyTreeCursor`
with that position (and the game's plies as the main line, the given ply selected).

## 3. Keeping the analysis across reloads

**Why deferred:** out of scope for this pass. A reload starts over.

**How to apply:** store the starting SIP and the study-encoded nodes (`PlyTreePath`) in local
storage on each structural change; restore them in `AnalysisPage.init`.

## 4. Share, Play from here, Import do nothing

**Why deferred:** the Share overlay (Position only) and the Import overlay are not designed; Play
from here needs the prefilled challenge overlay (`[[deferred]]` 2).

**How to apply:** wire `AnalysisActionsCard`'s handlers and `EditorCard`'s import handler once the
overlays exist.

## 5. Keyboard while expanded

**Why deferred:** keyboard handling was ditched project-wide; the handoff lists Esc (collapse) and
←/→ (navigate the selected line) as open.

**How to apply:** if wanted, a page-level keydown listener active while the page is open.

## 6. Board thumbnail in the expanded Variations card

**Why deferred:** optional per the handoff; the board is hidden while expanded.

**How to apply:** a small `BoardSurface` in the expanded card's header, following the selection.
