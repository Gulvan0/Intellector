package client.ui.common.board.tools;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;

/**
    What `PieceMoveTool` allows: which pieces can be picked up, where they can go and what has to
    be chosen to complete a move. `position` is always the position the board shows.
**/
interface PieceMovePolicy
{
    /**
        What moving a piece means right now, or `null` if no piece can be moved at all.
    **/
    public function pickMode(position:Position):Null<PieceMoveMode>;

    public function canPickUp(position:Position, mode:PieceMoveMode, hex:HexCoords):Bool;

    /**
        Where the piece on `from` can go; `null` for anywhere.
    **/
    public function destinations(position:Position, mode:PieceMoveMode, from:HexCoords):Null<Array<HexCoords>>;

    public function completion(position:Position, mode:PieceMoveMode, from:HexCoords, to:HexCoords):CompletionKind;

    /**
        Whether the destinations are marked on the board while a piece is picked up.
    **/
    public function showsMarkers(mode:PieceMoveMode):Bool;

    /**
        Whether a premove's pending choice (an open prompt) stays open when a move changes the
        shown position to `position`, rather than being dropped.
    **/
    public function keepsChoiceAcrossMove(position:Position):Bool;
}
