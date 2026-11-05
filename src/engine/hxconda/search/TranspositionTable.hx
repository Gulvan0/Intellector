package engine.hxconda.search;

import engine.hxconda.board.Move;
import engine.hxconda.evaluation.Evaluation;
import js.lib.Float64Array;
import js.lib.Int32Array;
import js.lib.Uint16Array;
import js.lib.Uint8Array;

/**
    Search results keyed by the position hash together with its verification key (see `Board.verificationKey`).
    Memory is bounded: see `MAXIMUM_BUCKET_COUNT`.
**/
class TranspositionTable
{
    private static inline final WINDOW_MARGIN:Float = 1;
    private static inline final INITIAL_BUCKET_COUNT:Int = 2048;
    private static inline final SLOTS_PER_BUCKET:Int = 4;
    private static inline final DEEPEST_WINS_SLOTS_PER_BUCKET:Int = 2;
    private static inline final MAXIMUM_BUCKET_COUNT:Int = 524288; // 4 slots of 37 bytes each: 74 MB, the largest power of two within 128 MB
    private static inline final NO_MOVE:Int = 0xFFFF;

    public var cutoffScore(default, null):Float = 0;
    public var cutoffMove(default, null):Move = Move.NONE;
    public var narrowedAlpha(default, null):Float = 0;
    public var narrowedBeta(default, null):Float = 0;

    /*
        Every bucket holds `SLOTS_PER_BUCKET` slots, each with one entry of any position hashing there. The first
        `DEEPEST_WINS_SLOTS_PER_BUCKET` are deepest-wins slots, the others are always-replace ones, see `place`.
        An entry stored by an earlier search (see `startNextSearch`) no longer holds its deepest-wins slot against shallower entries,
        but still serves probes until overwritten.
        The table starts small and doubles by rehashing until it reaches `MAXIMUM_BUCKET_COUNT`.
        An unused slot has depth 0, which no stored entry has, since it only reaches the table from `SearchTuning.HASHING_DEPTH`.
        The window the score is exact within is stored in `alphas` and `betas`: `alphas[slot]` is the score itself for an upper bound
        and `betas[slot]` is the score itself for a lower bound.
    */
    private var hashes:Int32Array = new Int32Array(SLOTS_PER_BUCKET * INITIAL_BUCKET_COUNT);
    private var verificationKeys:Int32Array = new Int32Array(SLOTS_PER_BUCKET * INITIAL_BUCKET_COUNT);
    private var moves:Uint16Array = new Uint16Array(SLOTS_PER_BUCKET * INITIAL_BUCKET_COUNT);
    private var depths:Uint16Array = new Uint16Array(SLOTS_PER_BUCKET * INITIAL_BUCKET_COUNT);
    private var generations:Uint8Array = new Uint8Array(SLOTS_PER_BUCKET * INITIAL_BUCKET_COUNT);
    private var scores:Float64Array = new Float64Array(SLOTS_PER_BUCKET * INITIAL_BUCKET_COUNT);
    private var alphas:Float64Array = new Float64Array(SLOTS_PER_BUCKET * INITIAL_BUCKET_COUNT);
    private var betas:Float64Array = new Float64Array(SLOTS_PER_BUCKET * INITIAL_BUCKET_COUNT);
    private var bucketCount:Int = INITIAL_BUCKET_COUNT;
    private var usedSlotCount:Int = 0;
    private var generation:Int = 0;

    /** Marks the entries stored so far as stale: later searches can overwrite them regardless of depth **/
    public function startNextSearch():Void
    {
        generation = (generation + 1) & 255;
    }

    private inline function holds(slot:Int, hash:Int, verificationKey:Int):Bool
    {
        return depths[slot] != 0 && hashes[slot] == hash && verificationKeys[slot] == verificationKey;
    }

    private inline function moveAt(slot:Int):Move
    {
        return moves[slot] == NO_MOVE ? Move.NONE : cast moves[slot];
    }

    /** Maximum depth stored for the position, 0 if there's none **/
    public function deepestDepth(hash:Int, verificationKey:Int):Int
    {
        var firstSlot:Int = SLOTS_PER_BUCKET * (hash & (bucketCount - 1));
        var depth:Int = 0;
        for (slot in firstSlot...firstSlot + SLOTS_PER_BUCKET)
            if (holds(slot, hash, verificationKey) && depths[slot] > depth)
                depth = depths[slot];
        return depth;
    }

    /** Best move of the deepest entry for the position that has one, `Move.NONE` if there's none **/
    public function bestMove(hash:Int, verificationKey:Int):Move
    {
        var firstSlot:Int = SLOTS_PER_BUCKET * (hash & (bucketCount - 1));
        var move:Move = Move.NONE;
        var depth:Int = 0;
        for (slot in firstSlot...firstSlot + SLOTS_PER_BUCKET)
            if (holds(slot, hash, verificationKey) && moves[slot] != NO_MOVE && depths[slot] > depth)
            {
                move = moveAt(slot);
                depth = depths[slot];
            }
        return move;
    }

    /** Looks for entries searched at least as deep as `depth` **/
    public function probe(hash:Int, verificationKey:Int, alpha:Float, beta:Float, depth:Int):ProbeOutcome
    {
        var firstSlot:Int = SLOTS_PER_BUCKET * (hash & (bucketCount - 1));
        var lowerBound:Float = Math.NEGATIVE_INFINITY;
        var upperBound:Float = Math.POSITIVE_INFINITY;
        var hasEntries:Bool = false;

        for (slot in firstSlot...firstSlot + SLOTS_PER_BUCKET)
        {
            if (!holds(slot, hash, verificationKey))
                continue;

            hasEntries = true;
            if (depths[slot] < depth)
                continue;

            var score:Float = scores[slot];
            var entryAlpha:Float = alphas[slot];
            var entryBeta:Float = betas[slot];
            if (score > entryAlpha && score < entryBeta)
                return cutoff(score, moveAt(slot));
            if (score >= entryBeta && lowerBound < entryBeta)
                lowerBound = entryBeta;
            if (score <= entryAlpha && upperBound > entryAlpha)
                upperBound = entryAlpha;
        }

        if (!hasEntries)
            return Miss;

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

    /** Stores `score` found within the window (`alpha`, `beta`) **/
    public function store(hash:Int, verificationKey:Int, alpha:Float, beta:Float, move:Move, score:Float, depth:Int):Void
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

        place(hash, verificationKey, move, depth, score, trustedAlpha, trustedBeta, generation);
        if (usedSlotCount > SLOTS_PER_BUCKET * bucketCount / 2 && bucketCount < MAXIMUM_BUCKET_COUNT)
            grow();
    }

    /**
        Writes the entry into the first of these slots of its bucket: one it supersedes (same position, no deeper, no narrower window),
        an unused one, or the shallowest deepest-wins slot if the entry is at least as deep as it or it is stale.
        Otherwise the entry replaces the shallowest always-replace slot.
    **/
    private function place(hash:Int, verificationKey:Int, move:Move, depth:Int, score:Float, alpha:Float, beta:Float, entryGeneration:Int):Void
    {
        var firstSlot:Int = SLOTS_PER_BUCKET * (hash & (bucketCount - 1));
        var slot:Int = -1;

        for (candidate in firstSlot...firstSlot + SLOTS_PER_BUCKET)
            if (holds(candidate, hash, verificationKey) && depths[candidate] <= depth && alphas[candidate] >= alpha && betas[candidate] <= beta)
            {
                slot = candidate;
                break;
            }

        if (slot == -1)
            for (candidate in firstSlot...firstSlot + SLOTS_PER_BUCKET)
                if (depths[candidate] == 0)
                {
                    slot = candidate;
                    break;
                }

        if (slot == -1)
        {
            var shallowestDeepest:Int = firstSlot;
            for (candidate in firstSlot + 1...firstSlot + DEEPEST_WINS_SLOTS_PER_BUCKET)
                if (depths[candidate] < depths[shallowestDeepest])
                    shallowestDeepest = candidate;

            if (depth >= depths[shallowestDeepest] || generations[shallowestDeepest] != entryGeneration)
                slot = shallowestDeepest;
            else
            {
                slot = firstSlot + DEEPEST_WINS_SLOTS_PER_BUCKET;
                for (candidate in slot + 1...firstSlot + SLOTS_PER_BUCKET)
                    if (depths[candidate] < depths[slot])
                        slot = candidate;
            }
        }

        if (depths[slot] == 0)
            usedSlotCount++;

        hashes[slot] = hash;
        verificationKeys[slot] = verificationKey;
        moves[slot] = move == Move.NONE ? NO_MOVE : cast move;
        depths[slot] = depth;
        generations[slot] = entryGeneration;
        scores[slot] = score;
        alphas[slot] = alpha;
        betas[slot] = beta;
    }

    private function grow():Void
    {
        var oldHashes:Int32Array = hashes;
        var oldVerificationKeys:Int32Array = verificationKeys;
        var oldMoves:Uint16Array = moves;
        var oldDepths:Uint16Array = depths;
        var oldGenerations:Uint8Array = generations;
        var oldScores:Float64Array = scores;
        var oldAlphas:Float64Array = alphas;
        var oldBetas:Float64Array = betas;
        var oldSlotCount:Int = SLOTS_PER_BUCKET * bucketCount;

        bucketCount *= 2;
        hashes = new Int32Array(SLOTS_PER_BUCKET * bucketCount);
        verificationKeys = new Int32Array(SLOTS_PER_BUCKET * bucketCount);
        moves = new Uint16Array(SLOTS_PER_BUCKET * bucketCount);
        depths = new Uint16Array(SLOTS_PER_BUCKET * bucketCount);
        generations = new Uint8Array(SLOTS_PER_BUCKET * bucketCount);
        scores = new Float64Array(SLOTS_PER_BUCKET * bucketCount);
        alphas = new Float64Array(SLOTS_PER_BUCKET * bucketCount);
        betas = new Float64Array(SLOTS_PER_BUCKET * bucketCount);
        usedSlotCount = 0;

        for (slot in 0...oldSlotCount)
            if (oldDepths[slot] != 0)
            {
                var move:Move = oldMoves[slot] == NO_MOVE ? Move.NONE : cast oldMoves[slot];
                place(oldHashes[slot], oldVerificationKeys[slot], move, oldDepths[slot], oldScores[slot], oldAlphas[slot], oldBetas[slot], oldGenerations[slot]);
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
