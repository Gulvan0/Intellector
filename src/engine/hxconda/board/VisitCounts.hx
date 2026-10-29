package engine.hxconda.board;

import js.lib.Int32Array;

/**
    Visit counts keyed by the exact position hash: an open-addressing table with linear probing, growing as needed.
**/
class VisitCounts
{
    private static inline final INITIAL_CAPACITY:Int = 256;

    private var hashes:Int32Array = new Int32Array(INITIAL_CAPACITY);
    /** Zero marks an empty slot **/
    private var counts:Int32Array = new Int32Array(INITIAL_CAPACITY);
    private var occupiedCount:Int = 0;
    /** Count of hash 0, kept apart since it can't be told from an empty slot **/
    private var zeroHashCount:Int = 0;

    public function count(hash:Int):Int
    {
        if (hash == 0)
            return zeroHashCount;

        var slot:Int = slotOf(hash);
        return counts[slot];
    }

    public function increment(hash:Int):Void
    {
        if (hash == 0)
        {
            zeroHashCount++;
            return;
        }

        var slot:Int = slotOf(hash);
        if (counts[slot] > 0)
        {
            counts[slot]++;
            return;
        }

        hashes[slot] = hash;
        counts[slot] = 1;
        occupiedCount++;
        if (occupiedCount * 2 > counts.length)
            grow();
    }

    /** `hash` must have a positive count **/
    public function decrement(hash:Int):Void
    {
        if (hash == 0)
        {
            zeroHashCount--;
            return;
        }

        var slot:Int = slotOf(hash);
        if (counts[slot] > 1)
            counts[slot]--;
        else
            vacate(slot);
    }

    /** The slot holding `hash`, or the empty slot where it would go **/
    private inline function slotOf(hash:Int):Int
    {
        var mask:Int = counts.length - 1;
        var slot:Int = hash & mask;
        while (counts[slot] > 0 && hashes[slot] != hash)
            slot = (slot + 1) & mask;
        return slot;
    }

    /** Empties `slot`, moving back the entries of its probe run that would no longer be found **/
    private function vacate(slot:Int):Void
    {
        var mask:Int = counts.length - 1;
        var gap:Int = slot;
        var next:Int = (slot + 1) & mask;

        while (counts[next] > 0)
        {
            var home:Int = hashes[next] & mask;
            var isReachableWithoutGap:Bool = gap <= next ? home > gap && home <= next : home > gap || home <= next;
            if (!isReachableWithoutGap)
            {
                hashes[gap] = hashes[next];
                counts[gap] = counts[next];
                gap = next;
            }
            next = (next + 1) & mask;
        }

        counts[gap] = 0;
        occupiedCount--;
    }

    private function grow():Void
    {
        var oldHashes:Int32Array = hashes;
        var oldCounts:Int32Array = counts;
        hashes = new Int32Array(oldCounts.length * 2);
        counts = new Int32Array(oldCounts.length * 2);

        for (i in 0...oldCounts.length)
        {
            if (oldCounts[i] > 0)
            {
                var slot:Int = slotOf(oldHashes[i]);
                hashes[slot] = oldHashes[i];
                counts[slot] = oldCounts[i];
            }
        }
    }

    public function new() {}
}
