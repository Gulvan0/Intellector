package client.ui.common.board.tools;

import client.ui.common.board.MoveRules;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;

/**
    Legal moves by whichever side is to move.
**/
class AnalysisMovePolicy implements PieceMovePolicy
{
    private final rules:MoveRules;

    public function new(rules:MoveRules)
    {
        this.rules = rules;
    }

    public function pickMode(position:Position):Null<PieceMoveMode>
    {
        return Move;
    }

    public function canPickUp(position:Position, mode:PieceMoveMode, hex:HexCoords):Bool
    {
        var piece:Null<PieceData> = position.getPiece(hex);
        return piece != null && piece.color == position.turnColor;
    }

    public function destinations(position:Position, mode:PieceMoveMode, from:HexCoords):Null<Array<HexCoords>>
    {
        return rules.getLegalDestinations(from, position.pieces);
    }

    public function completion(position:Position, mode:PieceMoveMode, from:HexCoords, to:HexCoords):CompletionKind
    {
        return MoveCompletion.ofMove(rules, position, from, to);
    }

    public function showsMarkers(mode:PieceMoveMode):Bool
    {
        return true;
    }

    public function keepsChoiceAcrossMove(position:Position):Bool
    {
        return false;
    }
}
