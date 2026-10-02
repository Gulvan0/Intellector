package client.ui.common.board;

import intellectorboard.primitives.piece.PieceColor;

/**
    What `MoveInteractionController` currently allows, set by the page. The differences between
    "it's my turn", "spectating" and "history-browsing" collapse to these values rather than
    separate controller subclasses (see knowledge/plans/board_plan.md).
**/
typedef MoveInteractionConfig =
{
    /**
        The color the user plays - the only pieces they may pick up - or `null` if nobody may: e.g.
        spectating, or the shown position isn't the live one. Whether it's that color's turn is
        read off the position, not set here, so this stays the same across the opponent's turn.
        Changing it drops any queued premoves.
    **/
    allowedToMove:Null<PieceColor>,

    /**
        Whether `allowedToMove` may queue premoves while it isn't their turn. Turning it off drops
        any queued premoves.
    **/
    premovesEnabled:Bool
}
