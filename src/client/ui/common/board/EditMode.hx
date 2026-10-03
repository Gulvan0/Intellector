package client.ui.common.board;

import intellectorboard.primitives.piece.PieceData;

/**
    What the primary button does on a board in a position editor.
**/
enum EditMode
{
    // Moves pieces, by the board's move policy (`EditorMovePolicy` for free moves).
    Moving;
    Placing(piece:PieceData);
    Clearing;
}
