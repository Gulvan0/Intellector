package client.ui.common.board;

import intellectorboard.primitives.piece.PieceColor;

/**
    What `MoveInteractionController` currently allows, set by the page. The differences between
    "it's my turn", "spectating" and "history-browsing" collapse to this one value rather than
    separate controller subclasses (see knowledge/plans/board_plan.md).
**/
typedef MoveInteractionConfig =
{
    /**
        The color allowed to pick up a piece and move it right now, or `null` if nobody may -
        e.g. spectating, or the shown position isn't the live one.
    **/
    allowedToMove:Null<PieceColor>
}
