package client.ui.common.board;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;

/**
    Rules queries `MoveInteractionController` needs, injected at construction rather than
    imported - the controller itself has no compile-time dependency on `intellectorboard`'s rules
    engine (see knowledge/plans/board_plan.md). `MoveRulesAdapter.DEFAULT` is the real
    implementation, delegating to `intellectorboard`.
**/
typedef MoveRules =
{
    /**
        Every hex `from`'s piece could legally move to in `position`, ignoring whose turn it is.
    **/
    getLegalDestinations:(from:HexCoords, position:Position) -> Array<HexCoords>,

    /**
        Whether moving `from` to `to` in `position` is a Progressor reaching the final rank,
        needing a promotion choice before the move can be completed.
    **/
    isPromotionPossible:(from:HexCoords, to:HexCoords, position:Position) -> Bool,

    /**
        Whether moving `from` to `to` in `position` is a capture eligible to "chameleon" (morph
        into the captured piece's kind instead of keeping its own), needing a yes/no choice
        before the move can be completed.
    **/
    isChameleonPossible:(from:HexCoords, to:HexCoords, position:Position) -> Bool
}
