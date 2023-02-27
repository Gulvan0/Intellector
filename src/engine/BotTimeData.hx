package engine;

import net.shared.board.Situation;
import net.shared.utils.MathUtils;

class BotTimeData 
{
    public final secsLeft:Float;
    public final incrementSecs:Float;
    public final moveNum:Int;
    public final botMovesFirst:Bool;

    public function getSecsToMove(situation:Situation):Float
    {
        /* old version
        var shiftedMove:Int = botMovesFirst? moveNum - 1 : moveNum - 2;
        var reserveUsage:Float = MathUtils.clamp(0.1 + 0.01 * shiftedMove, 0.1, 0.9);
        return incrementSecs + reserveUsage * secsLeft;
        */
        var freeTimeReserve:Float = secsLeft - incrementSecs;

        var totalMaterial:Int = situation.countPieces();
        var normalizedMaterial:Float = (totalMaterial - 2) / 26;
        var materialDeflator:Float = 100 * normalizedMaterial + 7;

        var nonRenewableTimeToUse:Float = freeTimeReserve / materialDeflator;
        var totalTimeToUse:Float = nonRenewableTimeToUse + incrementSecs;
        var fasterStartMultiplier:Float = 1 - 1 / (moveNum + 0.2);

        return totalTimeToUse * fasterStartMultiplier;
    }

    public function new(secsLeft:Float, incrementSecs:Float, moveNum:Int, botMovesFirst:Bool) 
    {
        this.secsLeft = secsLeft;   
        this.incrementSecs = incrementSecs;   
        this.moveNum = moveNum;   
        this.botMovesFirst = botMovesFirst;   
    }
}