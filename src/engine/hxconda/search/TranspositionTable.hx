package engine.hxconda.search;

import engine.hxconda.board.Move;
import engine.hxconda.evaluation.Evaluation;
import js.lib.Map;

/**
    Search results keyed by position hash. A position keeps several entries of different depths and bound kinds.
**/
class TranspositionTable
{
    private static inline final WINDOW_MARGIN:Float = 1;

    public var cutoffScore(default, null):Float = 0;
    public var cutoffMove(default, null):Move = Move.NONE;
    public var narrowedAlpha(default, null):Float = 0;
    public var narrowedBeta(default, null):Float = 0;

    private final entries:Map<Int, Array<TranspositionEntry>> = new Map();

    public inline function entriesAt(hash:Int):Null<Array<TranspositionEntry>>
    {
        return entries.get(hash);
    }

    /** Maximum depth stored for `hash`, 0 if there's none **/
    public function deepestDepth(hash:Int):Int
    {
        var depth:Int = 0;
        var positionEntries:Null<Array<TranspositionEntry>> = entries.get(hash);
        if (positionEntries != null)
            for (entry in positionEntries)
                if (entry.depth > depth)
                    depth = entry.depth;
        return depth;
    }

    /** Looks for entries searched at least as deep as `depth` **/
    public function probe(hash:Int, alpha:Float, beta:Float, depth:Int):ProbeOutcome
    {
        var positionEntries:Null<Array<TranspositionEntry>> = entries.get(hash);
        if (positionEntries == null)
            return Miss;

        var lowerBound:Float = Math.NEGATIVE_INFINITY;
        var upperBound:Float = Math.POSITIVE_INFINITY;

        for (entry in positionEntries)
        {
            if (entry.depth < depth)
                continue;

            if (entry.score > entry.alpha && entry.score < entry.beta)
                return cutoff(entry.score, entry.move);
            if (entry.score >= entry.beta && lowerBound < entry.beta)
                lowerBound = entry.beta;
            if (entry.score <= entry.alpha && upperBound > entry.alpha)
                upperBound = entry.alpha;
        }

        if (alpha >= upperBound)
            return cutoff(alpha, Move.NONE);
        if (beta <= lowerBound)
            return cutoff(beta, Move.NONE);

        if (lowerBound <= upperBound)
        {
            alpha = Math.max(alpha, lowerBound - WINDOW_MARGIN);
            beta = Math.min(beta, upperBound + WINDOW_MARGIN);
        }

        narrowedAlpha = alpha;
        narrowedBeta = beta;
        return WindowNarrowed;
    }

    /** Stores `score` found within the window (`alpha`, `beta`), replacing the entries it supersedes **/
    public function store(hash:Int, alpha:Float, beta:Float, move:Move, score:Float, depth:Int):Void
    {
        var trustedAlpha:Float = Math.NaN;
        var trustedBeta:Float = Math.NaN;

        if (score <= alpha)
        {
            trustedAlpha = score;
            trustedBeta = Math.POSITIVE_INFINITY;
        }
        else if (score >= beta)
        {
            trustedAlpha = Math.NEGATIVE_INFINITY;
            trustedBeta = score;
        }
        else if (score > alpha && score < beta)
        {
            trustedAlpha = Math.NEGATIVE_INFINITY;
            trustedBeta = Math.POSITIVE_INFINITY;
        }

        var isBound:Bool = trustedAlpha > Evaluation.BLACK_WIN_SCORE || trustedBeta < Evaluation.WHITE_WIN_SCORE;
        if (isBound && Math.abs(score) > Evaluation.DECISIVE_THRESHOLD)
            return;

        var positionEntries:Null<Array<TranspositionEntry>> = entries.get(hash);
        if (positionEntries == null)
        {
            positionEntries = [];
            entries.set(hash, positionEntries);
        }

        var i:Int = positionEntries.length - 1;
        while (i >= 0)
        {
            var entry:TranspositionEntry = positionEntries[i];
            if (entry.depth <= depth && entry.alpha >= trustedAlpha && entry.beta <= trustedBeta)
                positionEntries.splice(i, 1);
            i--;
        }

        positionEntries.push(new TranspositionEntry(move, depth, score, trustedAlpha, trustedBeta));
    }

    private inline function cutoff(score:Float, move:Move):ProbeOutcome
    {
        cutoffScore = score;
        cutoffMove = move;
        return Cutoff;
    }

    public function new() {}
}
