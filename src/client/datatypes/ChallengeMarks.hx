package client.datatypes;

import morestd.MathTools;

/**
    What the user has done with their incoming challenges, shared between the tabs. Marks only
    accumulate: merging never loses a dismissal or lowers the seen id.
**/
class ChallengeMarks
{
    /** Older dismissed ids are dropped: those challenges are long resolved **/
    public static inline final MAX_DISMISSED_IDS:Int = 100;

    /** Taken off the notification for good; ascending, unique, the newest `MAX_DISMISSED_IDS` **/
    public final dismissedIds:Array<Int>;
    /** Every incoming challenge up to this id has been looked at in the pending list **/
    public final seenUpToId:Int;

    public static function empty():ChallengeMarks
    {
        return new ChallengeMarks([], 0);
    }

    public function new(dismissedIds:Array<Int>, seenUpToId:Int)
    {
        var unique:Map<Int, Bool> = [for (id in dismissedIds) id => true];
        var ids:Array<Int> = [for (id in unique.keys()) id];
        ids.sort((a, b) -> a - b);

        this.dismissedIds = ids.slice(MathTools.maxInt(0, ids.length - MAX_DISMISSED_IDS));
        this.seenUpToId = seenUpToId;
    }

    public function merge(other:ChallengeMarks):ChallengeMarks
    {
        return new ChallengeMarks(dismissedIds.concat(other.dismissedIds), MathTools.maxInt(seenUpToId, other.seenUpToId));
    }
}
