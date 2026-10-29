package engine.hxconda.search;

import engine.hxconda.board.Move;
import engine.hxconda.evaluation.Evaluation;
import js.lib.Int32Array;

/**
    Search results keyed by position hash. A position keeps several entries of different depths and bound kinds.
**/
class TranspositionTable
{
    private static inline final WINDOW_MARGIN:Float = 1;
    private static inline final INITIAL_CAPACITY:Int = 4096;

    public var cutoffScore(default, null):Float = 0;
    public var cutoffMove(default, null):Move = Move.NONE;
    public var narrowedAlpha(default, null):Float = 0;
    public var narrowedBeta(default, null):Float = 0;

    /*
        Open addressing with linear probing on the exact hash, growing as needed. Positions are never removed.
        A null bucket marks an empty slot.
    */
    private var hashes:Int32Array = new Int32Array(INITIAL_CAPACITY);
    private var buckets:Array<Null<Array<TranspositionEntry>>> = [for (_ in 0...INITIAL_CAPACITY) null];
    private var positionCount:Int = 0;

    public inline function entriesAt(hash:Int):Null<Array<TranspositionEntry>>
    {
        return buckets[slotOf(hash)];
    }

    /** Maximum depth stored for `hash`, 0 if there's none **/
    public function deepestDepth(hash:Int):Int
    {
        var depth:Int = 0;
        var positionEntries:Null<Array<TranspositionEntry>> = entriesAt(hash);
        if (positionEntries != null)
            for (entry in positionEntries)
                if (entry.depth > depth)
                    depth = entry.depth;
        return depth;
    }

    /** Looks for entries searched at least as deep as `depth` **/
    public function probe(hash:Int, alpha:Float, beta:Float, depth:Int):ProbeOutcome
    {
        var positionEntries:Null<Array<TranspositionEntry>> = entriesAt(hash);
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

        var positionEntries:Array<TranspositionEntry> = entriesOrNew(hash);

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

    /** The slot holding `hash`, or the empty slot where it would go **/
    private inline function slotOf(hash:Int):Int
    {
        var mask:Int = buckets.length - 1;
        var slot:Int = hash & mask;
        while (buckets[slot] != null && hashes[slot] != hash)
            slot = (slot + 1) & mask;
        return slot;
    }

    private function entriesOrNew(hash:Int):Array<TranspositionEntry>
    {
        var slot:Int = slotOf(hash);
        var positionEntries:Null<Array<TranspositionEntry>> = buckets[slot];
        if (positionEntries != null)
            return positionEntries;

        var newEntries:Array<TranspositionEntry> = [];
        hashes[slot] = hash;
        buckets[slot] = newEntries;
        positionCount++;
        if (positionCount * 2 > buckets.length)
            grow();
        return newEntries;
    }

    private function grow():Void
    {
        var oldHashes:Int32Array = hashes;
        var oldBuckets:Array<Null<Array<TranspositionEntry>>> = buckets;
        hashes = new Int32Array(oldBuckets.length * 2);
        buckets = [for (_ in 0...oldBuckets.length * 2) null];

        for (i in 0...oldBuckets.length)
        {
            if (oldBuckets[i] != null)
            {
                var slot:Int = slotOf(oldHashes[i]);
                hashes[slot] = oldHashes[i];
                buckets[slot] = oldBuckets[i];
            }
        }
    }

    private inline function cutoff(score:Float, move:Move):ProbeOutcome
    {
        cutoffScore = score;
        cutoffMove = move;
        return Cutoff;
    }

    public function new() {}
}
