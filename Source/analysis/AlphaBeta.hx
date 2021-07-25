package analysis;

import struct.Ply;
import analysis.Score;
import struct.PieceColor.opposite;
import struct.Situation;

typedef EvaluationResult = 
{
    var score:Score;
    var plySequence:Array<Ply>;
}

class AlphaBeta 
{

    private static function evaluateHeuristic(situation:Situation):Score
    {
        var value:Float = 0;
        for (coords => hex in situation.collectOccupiedHexes()) 
            if (hex.color == White)
                value += PieceValues.posValue(hex.type, coords.i, coords.j);
            else
                value -= PieceValues.posValue(hex.type, coords.i, coords.j);
        return new Score(Normal(value));
    }

    public static function evaluate(situation:Situation, remainingDepth:Int, maximize:Bool, ?alpha:Score, ?pply, ?prevSit):EvaluationResult
    {
        if (situation.isMate())
            return {score: new Score(Mate(0, opposite(situation.turnColor))), plySequence: []};

        if (remainingDepth == 0)
            return {score: evaluateHeuristic(situation), plySequence: []};

        var beta:Null<Score> = null;
        var optimalSequence:Array<Ply> = [];
        var neededChildDepth:Int = remainingDepth - 1;

        for (ply in situation.availablePlys())
        {
            #if verbose_analysis
            var res:EvaluationResult = evaluate(situation.makeMove(ply), neededChildDepth, !maximize, beta, ply, situation);
            #else
            var res:EvaluationResult = evaluate(situation.makeMove(ply), neededChildDepth, !maximize, beta);
            #end

            if (beta == null || (maximize && (res.score > beta) || !maximize && beta > res.score))
            {
                beta = res.score;
                optimalSequence = [ply].concat(res.plySequence);
                if (alpha != null && (maximize && (alpha <= beta) || !maximize && (alpha >= beta)))
                    break;
            }

            switch cast(res.score, ScoreType) 
            {
                case Mate(turns, winner):
                    if (winner == situation.turnColor)
                    {
                        neededChildDepth = turns - 2;
                        if (neededChildDepth < 0)
                            break;
                    }
                default:
            }
        }

        #if verbose_analysis
        var s = "";
        for (i in 0...(6-remainingDepth))
            s += ".";
        if (pply != null)
            s += pply.toNotation(prevSit) + " | ";
        trace(s + beta.incrementedMate() + " | " + optimalSequence[0].toNotation(situation));
        #end
        
        return {score: beta.incrementedMate(), plySequence: optimalSequence};
    }
}