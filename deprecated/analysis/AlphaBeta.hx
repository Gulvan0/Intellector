package analysis;

import haxe.Int64;
import haxe.Timer;
import struct.Ply;
import analysis.Score;
import struct.PieceColor.opposite;
import struct.Situation;

typedef EvaluationResult = 
{
    var score:Score;
    var optimalPly:Ply;
    var remainingDepth:Int;
}

enum MeasuredProcess
{
    IsMate;
    Heuristic;
    OccupiedHexes;
    PosVal;
    AvailablePlys;
    Sorting;
}

class AlphaBeta 
{
    private static var evaluationCache:ZobristMap<EvaluationResult> = new ZobristMap<EvaluationResult>();
    public static var calls:Map<MeasuredProcess, Int> = [];
    public static var totalTime:Map<MeasuredProcess, Float> = [];
    public static var prunedCount:Int = 0;
    public static var evaluatedCount:Int = 0;

    public static function initMeasuredIndicators() 
    {
        AlphaBeta.evaluationCache = new ZobristMap<EvaluationResult>();
        prunedCount = 0;
        evaluatedCount = 0;
        for (k in MeasuredProcess.createAll())
        {
            totalTime[k] = 0;
            calls[k] = 0;
        }
    }

    public static function findMate(situation:Situation, remainingDepth:Int, maximize:Bool, ?alpha:Score):EvaluationResult
    {
        var cached = evaluationCache.zget(situation.zobristHash);
        if (cached != null)
            return cached;

        if (situation.isMate())
        {
            var result = {score: new Score(Mate(0, opposite(situation.turnColor))), optimalPly: null, remainingDepth: 9999};
            evaluationCache.zset(situation.zobristHash, result);
            return result;
        }

        if (remainingDepth == 0)
            return {score: Normal(0), optimalPly: null, remainingDepth: 0};

        var beta:Null<Score> = null;
        var optimalPly:Ply = new Ply();
        var neededChildDepth:Int = remainingDepth - 1;
        var branches = situation.availablePlys();

        for (ply in branches)
        {
            var res:EvaluationResult = findMate(situation.makeMove(ply), neededChildDepth, !maximize, beta);

            if (beta == null || (maximize && (res.score > beta) || !maximize && beta > res.score))
            {
                beta = res.score;
                optimalPly = ply;
                if (alpha != null && (maximize && (alpha <= beta) || !maximize && (alpha >= beta)))
                    break;
            }

            switch cast(res.score, ScoreType) 
            {
                case Mate(turns, winner):
                    if (winner == situation.turnColor)
                    {
                        if (neededChildDepth > turns - 2)
                            neededChildDepth = turns - 2;
                        if (neededChildDepth < 0)
                            break;
                    }
                default:
            }
        }

        var result = {score: beta.incrementedMate(), optimalPly: optimalPly, remainingDepth: remainingDepth};
        //if (beta.getName() == "Mate")
           // evaluationCache.zset(situation.zobristHash, result);
        return result;
    }

    public static function evaluate(situation:Situation, depth:Int):EvaluationResult
    {
        var maximize:Bool = situation.turnColor == White;
        return evaluateRecursive(situation, depth, maximize);
    }

    private static function evaluateHeuristic(situation:Situation):Score
    {
        var value:Float = 0;
        var ts;

        #if measure_time
        ts = Timer.stamp();
        #end
        var occupied = situation.collectOccupiedFast();
        #if measure_time
        totalTime[OccupiedHexes] += Timer.stamp() - ts;
        calls[OccupiedHexes]++;
        #end
        for (hex in occupied) 
        {
            #if measure_time
            ts = Timer.stamp();
            #end
            value += PieceValues.posValueFast(hex.type, hex.color, hex.i, hex.j);
            #if measure_time
            totalTime[PosVal] += Timer.stamp() - ts;
            calls[PosVal]++;
            #end
        }
        return new Score(Normal(value));
    }

    private static function evaluateRecursive(situation:Situation, remainingDepth:Int, maximize:Bool, ?alpha:Score, ?pply, ?prevSit):EvaluationResult
    {
        var cached = evaluationCache.zget(situation.zobristHash);
        if (cached != null && cached.remainingDepth >= remainingDepth)
        {
            #if measure_time
            prunedCount++;
            #end
            return cached;
        }
        #if measure_time
        evaluatedCount++;
        var ts;
        ts = Timer.stamp();
        #end
        if (situation.isMate())
        {
            var result = {score: new Score(Mate(0, opposite(situation.turnColor))), optimalPly: null, remainingDepth: 9999};
            evaluationCache.zset(situation.zobristHash, result);
            return result;
        }
        #if measure_time
        totalTime[IsMate] += Timer.stamp() - ts;
        calls[IsMate]++;
        #end

        if (remainingDepth == 0)
        {
            #if measure_time
            ts = Timer.stamp();
            #end
            var score = evaluateHeuristic(situation);
            #if measure_time
            totalTime[Heuristic] += Timer.stamp() - ts;
            calls[Heuristic]++;
            #end
            var result = {score: score, optimalPly: null, remainingDepth: 0};
            evaluationCache.zset(situation.zobristHash, result);
            return result;
        }

        var beta:Null<Score> = null;
        var optimalPly:Ply;
        var neededChildDepth:Int = remainingDepth - 1;
        #if measure_time
        ts = Timer.stamp();
        #end
        var branches = situation.availablePlys();
        #if measure_time
        totalTime[AvailablePlys] += Timer.stamp() - ts;
        calls[AvailablePlys]++;
        #end

        if (remainingDepth == 1)
        {
            var ply = branches[0];
            var bestResult:EvaluationResult = {score: evaluateRecursive(situation.makeMove(ply), 0, null).score, optimalPly: ply, remainingDepth: 1};
            for (i in 1...branches.length)
            {
                ply = branches[i];
                var score = evaluateRecursive(situation.makeMove(ply), 0, null).score;
                if (maximize)
                {
                    if (bestResult.score < score)
                        bestResult = {score: score, optimalPly: ply, remainingDepth: 1};
                }
                else
                    if (bestResult.score > score)
                        bestResult = {score: score, optimalPly: ply, remainingDepth: 1};
            }
            var result = {score: bestResult.score.incrementedMate(), optimalPly: bestResult.optimalPly, remainingDepth: 1};
            evaluationCache.zset(situation.zobristHash, result);
            return result;
        }

        var shallowResults = [for (ply in branches) ply => evaluateRecursive(situation.makeMove(ply), Math.floor(neededChildDepth / 2), !maximize)];
        #if measure_time
        ts = Timer.stamp();
        #end
        if (maximize)
            branches.sort((ply1, ply2) -> (shallowResults.get(ply2).score > shallowResults.get(ply1).score? 1 : -1));
        else
            branches.sort((ply1, ply2) -> (shallowResults.get(ply1).score > shallowResults.get(ply2).score? 1 : -1));
        #if measure_time
        totalTime[Sorting] += Timer.stamp() - ts;
        calls[Sorting]++;
        #end

        for (ply in branches)
        {
            #if verbose_analysis
            var res:EvaluationResult = evaluateRecursive(situation.makeMove(ply), neededChildDepth, !maximize, beta, ply, situation);
            #else
            var res:EvaluationResult = evaluateRecursive(situation.makeMove(ply), neededChildDepth, !maximize, beta);
            #end

            if (beta == null || (maximize && (res.score > beta) || !maximize && beta > res.score))
            {
                beta = res.score;
                optimalPly = ply;
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
        trace(s + beta.incrementedMate() + " | " + optimalPly.toNotation(situation));
        #end
        
        var result = {score: beta.incrementedMate(), optimalPly: optimalPly, remainingDepth: remainingDepth};
        evaluationCache.zset(situation.zobristHash, result);
        return result;
    }
}