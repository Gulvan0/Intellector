package client.ui.common.board;

/** Why the position a board shows changed **/
enum PositionChangeCause
{
    /** A move was played, by either side (fired premoves included) **/
    Move;
    /** Swapped for an unrelated position: history navigation, a rollback, a reset **/
    Replacement;
    /** A premove was queued, or the queue was cancelled **/
    PremovesChanged;
}
