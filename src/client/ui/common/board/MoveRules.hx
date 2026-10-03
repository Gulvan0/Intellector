package client.ui.common.board;

import intellectorboard.position.PieceArrangement;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;

/**
    Rules queries the board's move policies and `Premoves` need, injected rather than imported -
    they have no compile-time dependency on `intellectorboard`'s rules engine (see
    knowledge/plans/board_plan.md); `MoveRulesAdapter.DEFAULT` is the real implementation. Takes
    `PieceArrangement`/`PieceData` directly rather than `Position`/a departure `HexCoords` - none
    of these care whose turn it is, and the callers already have the pieces in hand.
**/
typedef MoveRules =
{
    /**
        Every hex `from`'s piece could legally move to in `pieces`.
    **/
    getLegalDestinations:(from:HexCoords, pieces:PieceArrangement) -> Array<HexCoords>,

    /**
        Every hex `from`'s piece could reach as a premove: its movement geometry alone, ignoring
        whatever stands in the way (the position it will actually move in isn't known yet).
    **/
    getPremoveDestinations:(from:HexCoords, pieces:PieceArrangement) -> Array<HexCoords>,

    /**
        Whether `movingPiece` reaching `destination` is a Progressor promotion, needing a
        promotion choice before the move can be completed.
    **/
    isPromotionPossible:(movingPiece:PieceData, destination:HexCoords) -> Bool,

    /**
        Whether `movingPiece` capturing `capturedPiece` at `from` is eligible to "chameleon"
        (morph into the captured piece's kind instead of keeping its own), needing a yes/no
        choice before the move can be completed. `capturedPiece` is `null` for a non-capturing
        move, which is never chameleon-eligible.
    **/
    isChameleonPossible:(movingPiece:PieceData, from:HexCoords, capturedPiece:Null<PieceData>, pieces:PieceArrangement) -> Bool,

    /**
        Whether the piece on `coords` is within its own Intellector's aura (the precondition for
        it to morph when capturing).
    **/
    isAuraActive:(coords:HexCoords, pieces:PieceArrangement) -> Bool
}
