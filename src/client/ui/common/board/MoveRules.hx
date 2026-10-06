package client.ui.common.board;

import intellectorboard.position.PieceArrangement;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;

/**
    The rules queries move policies and `Premoves` need, injected so the board doesn't depend on
    the rules engine; `MoveRulesAdapter.DEFAULT` is the real implementation.
**/
typedef MoveRules =
{
    /** Every hex `from`'s piece could legally move to in `pieces` **/
    getLegalDestinations:(from:HexCoords, pieces:PieceArrangement) -> Array<HexCoords>,

    /** Every hex `from`'s piece could reach as a premove: movement geometry alone, blockers ignored **/
    getPremoveDestinations:(from:HexCoords, pieces:PieceArrangement) -> Array<HexCoords>,

    /** Whether `movingPiece` reaching `destination` promotes **/
    isPromotionPossible:(movingPiece:PieceData, destination:HexCoords) -> Bool,

    /**
        Whether `movingPiece`, moving from `from`, may morph into `capturedPiece`'s kind (`null`
        for a non-capture, which never may).
    **/
    isChameleonPossible:(movingPiece:PieceData, from:HexCoords, capturedPiece:Null<PieceData>, pieces:PieceArrangement) -> Bool,

    /** Whether the piece on `coords` is within its own Intellector's aura **/
    isAuraActive:(coords:HexCoords, pieces:PieceArrangement) -> Bool
}
