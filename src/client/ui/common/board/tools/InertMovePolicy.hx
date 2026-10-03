package client.ui.common.board.tools;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;

/**
    No piece can be moved: spectating, or browsing an older position of a game.
**/
class InertMovePolicy implements PieceMovePolicy
{
    public function new() {}

    public function pickMode(position:Position):Null<PieceMoveMode>
    {
        return null;
    }

    public function canPickUp(position:Position, mode:PieceMoveMode, hex:HexCoords):Bool
    {
        return false;
    }

    public function destinations(position:Position, mode:PieceMoveMode, from:HexCoords):Null<Array<HexCoords>>
    {
        return [];
    }

    public function completion(position:Position, mode:PieceMoveMode, from:HexCoords, to:HexCoords):CompletionKind
    {
        return None;
    }

    public function showsMarkers(mode:PieceMoveMode):Bool
    {
        return false;
    }

    public function keepsChoiceAcrossMove(position:Position):Bool
    {
        return false;
    }
}
