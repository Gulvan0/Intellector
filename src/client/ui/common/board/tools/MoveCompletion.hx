package client.ui.common.board.tools;

import client.ui.common.board.MoveRules;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;

/**
    The completion rules shared by policies.
**/
class MoveCompletion
{
    /**
        What a legal move from `from` to `to` in `position` still needs chosen.
    **/
    public static function ofMove(rules:MoveRules, position:Position, from:HexCoords, to:HexCoords):CompletionKind
    {
        var movingPiece:PieceData = position.getPiece(from);
        var capturedPiece:Null<PieceData> = position.getPiece(to);

        if (rules.isPromotionPossible(movingPiece, to))
            return Promotion;
        if (rules.isChameleonPossible(movingPiece, from, capturedPiece, position.pieces))
            return Chameleon(capturedPiece.type);
        return None;
    }
}
