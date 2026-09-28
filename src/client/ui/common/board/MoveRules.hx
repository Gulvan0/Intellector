package client.ui.common.board;

import intellectorboard.position.PieceArrangement;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;

/**
    Rules queries `MoveInteractionController` needs, injected at construction rather than
    imported - the controller itself has no compile-time dependency on `intellectorboard`'s rules
    engine (see knowledge/plans/board_plan.md). `MoveRulesAdapter.DEFAULT` is the real
    implementation, delegating to `intellectorboard`.

    Takes `PieceArrangement` rather than `Position` throughout, and `PieceData` rather than a
    departure `HexCoords` to look a piece up again - none of these three queries care about whose
    turn it is (the controller's own `config.allowedToMove` already gates that), and the
    controller always already has the moving/captured `PieceData` in hand by the time it calls
    any of these, so there's nothing left to null-check at the call site.
**/
typedef MoveRules =
{
    /**
        Every hex `from`'s piece could legally move to in `pieces`.
    **/
    getLegalDestinations:(from:HexCoords, pieces:PieceArrangement) -> Array<HexCoords>,

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
    isChameleonPossible:(movingPiece:PieceData, from:HexCoords, capturedPiece:Null<PieceData>, pieces:PieceArrangement) -> Bool
}
