package client.ui.common.board.tools;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;

/** A position editor's free move: any piece to any other hex, rules ignored, nothing to choose **/
class EditorMovePolicy implements PieceMovePolicy
{
    public function new() {}

    public function pickMode(position:Position):Null<PieceMoveMode>
    {
        return FreeMove;
    }

    public function canPickUp(position:Position, mode:PieceMoveMode, hex:HexCoords):Bool
    {
        return position.getPiece(hex) != null;
    }

    public function destinations(position:Position, mode:PieceMoveMode, from:HexCoords):Null<Array<HexCoords>>
    {
        return null;
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
