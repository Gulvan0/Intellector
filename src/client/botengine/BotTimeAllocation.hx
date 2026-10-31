package client.botengine;

/** How long a bot playing a timed game thinks over a move **/
class BotTimeAllocation
{
    /** Pieces on the board at the start of a default game **/
    private static inline final STARTING_PIECE_COUNT:Int = 28;

    /**
        A share of the clock reserve beyond one increment, larger the fewer pieces are left, plus the increment;
        cut down over the first moves. `moveNumber`: the plies played before this move, plus one.
    **/
    public static function secondsToMove(secondsLeft:Float, incrementSeconds:Float, moveNumber:Int, pieceCount:Int):Float
    {
        var freeReserve:Float = secondsLeft - incrementSeconds;

        var normalizedMaterial:Float = (pieceCount - 2) / (STARTING_PIECE_COUNT - 2);
        var materialDeflator:Float = 100 * normalizedMaterial + 7;

        var totalTimeToUse:Float = freeReserve / materialDeflator + incrementSeconds;
        var fasterStartMultiplier:Float = 1 - 1 / (moveNumber + 0.2);

        return totalTimeToUse * fasterStartMultiplier;
    }
}
