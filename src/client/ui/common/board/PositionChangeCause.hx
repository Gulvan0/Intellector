package client.ui.common.board;

/**
    Why the position a board shows changed.
**/
enum PositionChangeCause
{
    // A move was played: the opponent's, or the user's own (fired premoves included).
    Move;
    // The position was swapped for an unrelated one: history navigation, a rollback, a reset.
    Replacement;
    // A premove was queued, or the queue was cancelled.
    PremovesChanged;
}
