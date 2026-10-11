package client.datatypes.game;

import intellectorboard.primitives.piece.PieceColor;

class GameEnding
{
    public final outcome:Outcome;
    /** Unix time, in milliseconds **/
    public final endedAtMs:Float;
    /** Both clocks when the game ended, null for a correspondence game **/
    public final finalClock:Null<GameClock>;
    private final whiteEloDelta:Null<Int>;
    private final blackEloDelta:Null<Int>;

    public function new(outcome:Outcome, endedAtMs:Float, finalClock:Null<GameClock>, whiteEloDelta:Null<Int>, blackEloDelta:Null<Int>)
    {
        this.outcome = outcome;
        this.endedAtMs = endedAtMs;
        this.finalClock = finalClock;
        this.whiteEloDelta = whiteEloDelta;
        this.blackEloDelta = blackEloDelta;
    }

    /** `color`'s rating change, null unless the game was rated **/
    public function eloDelta(color:PieceColor):Null<Int>
    {
        return color == White ? whiteEloDelta : blackEloDelta;
    }
}
