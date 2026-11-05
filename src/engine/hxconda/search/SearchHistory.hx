package engine.hxconda.search;

import engine.hxconda.board.Move;
import haxe.io.Float64Array;

/**
    Per-move statistics gathered during a search, indexed by the packed move.
**/
class SearchHistory
{
    private static inline final MOVE_INDEX_COUNT:Int = 1 << 16;

    private final cutoffWeights:Float64Array = new Float64Array(MOVE_INDEX_COUNT);
    private final quietVisitCounts:Float64Array = new Float64Array(MOVE_INDEX_COUNT);
    private final quietBestCounts:Float64Array = new Float64Array(MOVE_INDEX_COUNT);

    /** Accumulated weight of the beta cutoffs caused by `move` **/
    public inline function cutoffWeight(move:Move):Float
    {
        return cutoffWeights[move];
    }

    public inline function recordCutoff(move:Move, depth:Int):Void
    {
        cutoffWeights[move] += depth * depth;
    }

    /** How many times `move` was searched as a quiet move: neither a capture nor a check **/
    public inline function quietVisitCount(move:Move):Float
    {
        return quietVisitCounts[move];
    }

    public inline function recordQuietVisit(move:Move):Void
    {
        quietVisitCounts[move]++;
    }

    /** Share of the quiet visits of `move` where it turned out to be the best move **/
    public inline function quietBestRate(move:Move):Float
    {
        return quietBestCounts[move] / quietVisitCounts[move];
    }

    public inline function recordQuietBest(move:Move):Void
    {
        quietBestCounts[move]++;
    }

    /** Divides every statistic by `divisor`, so that older searches weigh less than newer ones **/
    public function decay(divisor:Float):Void
    {
        for (i in 0...MOVE_INDEX_COUNT)
        {
            cutoffWeights[i] /= divisor;
            quietVisitCounts[i] /= divisor;
            quietBestCounts[i] /= divisor;
        }
    }

    public function new() {}
}
