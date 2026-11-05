package engine.hxconda.search.weakening;

import engine.hxconda.board.Move;

/**
    Picks a weakened search's move among the root moves' recorded scores.
**/
class WeakenedMoveChoice
{
    /** Numerator of the pick weights; it cancels out in the draw **/
    private static inline final WEIGHT_SCALE:Float = 100;

    /**
        Index in `scores` of the move to play. The candidates are the best `weakening.candidateCount` exactly scored moves
        losing between `weakening.minLoss` and `weakening.maxLoss` against the best exact score.
        Without candidates, it is the move losing most while still losing less than `minLoss`, judged by lower bounds
        where the score isn't exact. Otherwise, each candidate's value gets its `bonus`, and one is drawn at random with
        the weight `(WEIGHT_SCALE / (best adjusted value - adjusted value + 1))^weightExponent`.
        `scores` must have an exact score.
    **/
    public static function choose(scores:RootMoveScores, weakening:Weakening, bonus:Move->Float):Int
    {
        var best:Int = scores.bestIndex();
        var bestValue:Float = scores.values[best];
        var top:Float = bestValue - weakening.minLoss;
        var maxLoss:Null<Float> = weakening.maxLoss;
        var floor:Float = maxLoss == null ? Math.NEGATIVE_INFINITY : bestValue - maxLoss;

        var candidates:Array<Int> = scores.bestExactWithin(floor, top, weakening.candidateCount);
        if (candidates.length == 0)
            return mostLosingAboveWindow(scores, best, top);

        var adjustedValues:Array<Float> = [for (i in candidates) scores.values[i] + bonus(scores.moves[i])];
        var bestAdjustedValue:Float = Math.NEGATIVE_INFINITY;
        for (value in adjustedValues)
            bestAdjustedValue = Math.max(bestAdjustedValue, value);

        var weights:Array<Float> = [for (value in adjustedValues) Math.pow(WEIGHT_SCALE / (bestAdjustedValue - value + 1), weakening.weightExponent)];
        var totalWeight:Float = 0;
        for (weight in weights)
            totalWeight += weight;

        var threshold:Float = Math.random() * totalWeight;
        for (k in 0...candidates.length)
        {
            threshold -= weights[k];
            if (threshold < 0)
                return candidates[k];
        }
        return candidates[candidates.length - 1];
    }

    /** The move with the lowest exact value or lower bound above `top`; `best` if there is no other **/
    private static function mostLosingAboveWindow(scores:RootMoveScores, best:Int, top:Float):Int
    {
        var chosen:Int = best;
        for (i in 0...scores.moves.length)
        {
            var value:Float = scores.values[i];
            if (scores.bounds[i] != Upper && value > top && value < scores.values[chosen])
                chosen = i;
        }
        return chosen;
    }
}
