package client.datatypes;

import intellectorboard.primitives.piece.PieceColor;

/** Both players' remaining time as of `updatedAtMs`, with the clock of `tickingSide` running since **/
class GameClock
{
    public final whiteMs:Int;
    public final blackMs:Int;
    public final tickingSide:Null<PieceColor>;
    /** Unix time, in milliseconds **/
    public final updatedAtMs:Float;

    public function new(whiteMs:Int, blackMs:Int, tickingSide:Null<PieceColor>, updatedAtMs:Float)
    {
        this.whiteMs = whiteMs;
        this.blackMs = blackMs;
        this.tickingSide = tickingSide;
        this.updatedAtMs = updatedAtMs;
    }

    /** `color`'s remaining time at Unix time `nowMs`, never below 0 **/
    public function remainingMs(color:PieceColor, nowMs:Float):Float
    {
        var storedMs:Float = color == White ? whiteMs : blackMs;
        if (color == tickingSide)
            storedMs -= nowMs - updatedAtMs;
        return Math.max(0, storedMs);
    }
}
