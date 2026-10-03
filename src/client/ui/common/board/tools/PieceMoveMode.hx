package client.ui.common.board.tools;

/**
    What moving a piece on the board means at the moment.
**/
enum PieceMoveMode
{
    // A move in the position: reported through `playMove`.
    Move;
    // A premove, queued for later: reported as `PremoveIntent.Queue`.
    Premove;
    // A free move in a position editor, ignoring the rules: reported as `EditIntent.MovePiece`.
    FreeMove;
}
