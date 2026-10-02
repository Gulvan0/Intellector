package client.ui.common.board;

/**
    A semantic hex highlight; `BoardSurface.setHexTint` owns the actual colors (see the palette
    in knowledge/plans/board_plan.md), so no controller carries any.
**/
enum HexTint
{
    // A hex that's a departure candidate (hovered) or the departure itself (selected).
    Departure;
    // A legal destination under the cursor.
    DestinationHover;
    // The hex a pending promotion/chameleon prompt is anchored to.
    PromptAnchor;
    // A queued premove's departure or destination.
    Premove;
}
