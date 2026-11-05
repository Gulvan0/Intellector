package engine.hxconda.search.weakening;

import engine.hxconda.board.Move;

/**
    What one iteration found out about the root moves' scores, for the side to move (positive favours it).
    Moves without a record were never reached.
**/
class RootMoveScores
{
    /** Beyond any non-decisive value difference **/
    private static inline final UPPER_BOUND_ORDERING_OFFSET:Float = 1000000;
    private static inline final UNRECORDED_ORDERING_OFFSET:Float = 10000000;

    public final depth:Int;
    public final moves:Array<Move> = [];
    public final bounds:Array<ScoreBound> = [];
    public final values:Array<Float> = [];
    /** Expected continuation of each move with an exact score, starting with it; null for the others **/
    public final lines:Array<Null<Array<Move>>> = [];

    /** `base` with the records of `partial`, a later abandoned iteration, taking precedence **/
    public static function merge(base:RootMoveScores, partial:RootMoveScores):RootMoveScores
    {
        var merged:RootMoveScores = new RootMoveScores(partial.depth);
        for (i in 0...base.moves.length)
            merged.set(base.moves[i], base.bounds[i], base.values[i], base.lines[i]);
        for (i in 0...partial.moves.length)
            merged.set(partial.moves[i], partial.bounds[i], partial.values[i], partial.lines[i]);
        return merged;
    }

    /** Replaces the record of `move`, if any **/
    public function set(move:Move, bound:ScoreBound, value:Float, line:Null<Array<Move>>):Void
    {
        var i:Int = moves.indexOf(move);
        if (i == -1)
        {
            moves.push(move);
            bounds.push(bound);
            values.push(value);
            lines.push(line);
        }
        else
        {
            bounds[i] = bound;
            values[i] = value;
            lines[i] = line;
        }
    }

    public function isExact(move:Move):Bool
    {
        var i:Int = moves.indexOf(move);
        return i != -1 && bounds[i] == Exact;
    }

    /** Index of the move with the highest exact value, the earliest of equal ones; -1 if none is exact **/
    public function bestIndex():Int
    {
        var best:Int = -1;
        for (i in 0...moves.length)
            if (bounds[i] == Exact && (best == -1 || values[i] > values[best]))
                best = i;
        return best;
    }

    /** Higher for the moves likelier to score well: by value, those known only to score at most it last, unrecorded ones after them **/
    public function orderingKey(move:Move):Float
    {
        var i:Int = moves.indexOf(move);
        if (i == -1)
            return -UNRECORDED_ORDERING_OFFSET;
        return bounds[i] == Upper ? values[i] - UPPER_BOUND_ORDERING_OFFSET : values[i];
    }

    public function exactCount():Int
    {
        return bounds.filter(bound -> bound == Exact).length;
    }

    /**
        The value a move within `weakening`'s window against `bestValue` has to exceed to be among its candidates:
        the window's floor while there are fewer exact ones than `candidateCount`, the lowest of them otherwise
    **/
    public function candidateThreshold(bestValue:Float, weakening:Weakening):Float
    {
        var maxLoss:Null<Float> = weakening.maxLoss;
        var floor:Float = maxLoss == null ? Math.NEGATIVE_INFINITY : bestValue - maxLoss - 0.5; // the floor itself is in the window
        var candidates:Array<Int> = bestExactWithin(floor, bestValue - weakening.minLoss, weakening.candidateCount);
        return candidates.length < weakening.candidateCount ? floor : Math.max(floor, values[candidates[candidates.length - 1]]);
    }

    /**
        Whether the record of `move` already tells its place against `bestValue`: an exact score,
        a lower bound losing less than `weakening.minLoss`, or an upper bound not beating `candidateThreshold`
    **/
    public function isPlacedAgainst(move:Move, bestValue:Float, weakening:Weakening):Bool
    {
        var i:Int = moves.indexOf(move);
        if (i == -1)
            return false;

        return switch bounds[i] {
            case Exact: true;
            case Lower: values[i] > bestValue - weakening.minLoss;
            case Upper: values[i] <= candidateThreshold(bestValue, weakening);
        }
    }

    /** Indices of the exact values from `lower` to `upper`, the highest first, at most `count` **/
    public function bestExactWithin(lower:Float, upper:Float, count:Int):Array<Int>
    {
        var indices:Array<Int> = [for (i in 0...moves.length) if (bounds[i] == Exact && values[i] >= lower && values[i] <= upper) i];
        indices.sort((a, b) -> values[a] > values[b] ? -1 : values[a] < values[b] ? 1 : a - b);
        return indices.slice(0, count);
    }

    public function new(depth:Int)
    {
        this.depth = depth;
    }
}
