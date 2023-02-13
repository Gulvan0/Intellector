package engine;

import net.shared.utils.MathUtils;

class BotTimeData 
{
    public final secsLeft:Float;
    public final incrementSecs:Float;
    public final moveNum:Int;
    public final botMovesFirst:Bool;

    public function getSecsToMove():Float
    {
        var shiftedMove:Int = botMovesFirst? moveNum - 1 : moveNum - 2;
        var reserveUsage:Float = MathUtils.clamp(0.1 + 0.01 * shiftedMove, 0.1, 0.9);
        return incrementSecs + reserveUsage * secsLeft;
    }

    public function new(secsLeft:Float, incrementSecs:Float, moveNum:Int, botMovesFirst:Bool) 
    {
        this.secsLeft = secsLeft;   
        this.incrementSecs = incrementSecs;   
        this.moveNum = moveNum;   
        this.botMovesFirst = botMovesFirst;   
    }
}