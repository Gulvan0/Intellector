package client.datatypes.game;

import intellectorboard.primitives.piece.PieceColor;

/** Both players' remaining time as of `updatedAtMs`, with the clock of `tickingSide` running since **/
class GameClock
{
    public final whiteMs:Int;
    public final blackMs:Int;
    public final tickingSide:Null<PieceColor>;
    /** Unix time, in milliseconds; null when not recorded, which only happens with neither clock running **/
    public final updatedAtMs:Null<Float>;

    public function new(whiteMs:Int, blackMs:Int, tickingSide:Null<PieceColor>, updatedAtMs:Null<Float>)
    {
        this.whiteMs = whiteMs;
        this.blackMs = blackMs;
        this.tickingSide = tickingSide;
        this.updatedAtMs = updatedAtMs;
    }

    /** The same remaining times, with neither clock running **/
    public function stopped():GameClock
    {
        return new GameClock(whiteMs, blackMs, null, updatedAtMs);
    }

    /**
        The clocks right after `mover` plays at `nowMs`: the mover gets `incrementMs` if their clock
        was running, and the opponent's starts if `startsOpponentClock`.
    **/
    public function afterPly(mover:PieceColor, nowMs:Float, incrementMs:Int, startsOpponentClock:Bool):GameClock
    {
        var moverMs:Float = remainingMs(mover, nowMs);
        if (tickingSide == mover)
            moverMs += incrementMs;

        var newWhiteMs:Int = mover == White ? Math.round(moverMs) : Math.round(remainingMs(White, nowMs));
        var newBlackMs:Int = mover == Black ? Math.round(moverMs) : Math.round(remainingMs(Black, nowMs));
        var newTickingSide:Null<PieceColor> = startsOpponentClock ? mover.opposite() : null;
        return new GameClock(newWhiteMs, newBlackMs, newTickingSide, nowMs);
    }

    /** `color`'s remaining time at Unix time `nowMs`, never below 0 **/
    public function remainingMs(color:PieceColor, nowMs:Float):Float
    {
        var storedMs:Float = color == White ? whiteMs : blackMs;
        if (color == tickingSide && updatedAtMs != null)
            storedMs -= nowMs - updatedAtMs;
        return Math.max(0, storedMs);
    }
}
