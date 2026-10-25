package client.ui.common.notifications.challenges;

import client.datatypes.challenge.IncomingChallenge;

/** How many waiting challenges get a row, and whether the count of those without one goes on the newest row or on the bar **/
typedef ChallengeStackRowPolicy = {
    maxRows:Int,
    countOnRow:Bool
}

/** Which waiting challenges get a row, and where the count of those without one goes **/
class ChallengeStackLayout
{
    public static final EXPANDED_POLICY:ChallengeStackRowPolicy = {maxRows: 3, countOnRow: false};
    public static final COLLAPSED_POLICY:ChallengeStackRowPolicy = {maxRows: 1, countOnRow: true};
    public static final RAIL_POLICY:ChallengeStackRowPolicy = {maxRows: 0, countOnRow: false}; // the viewport is too short for any row

    /** The newest waiting challenges, oldest first **/
    public final rows:Array<IncomingChallenge>;
    /** Shown on the newest row **/
    public final rowHiddenCount:Int;
    /** Shown on the bar **/
    public final barHiddenCount:Int;

    /** `waiting` in arrival order **/
    public function new(waiting:Array<IncomingChallenge>, policy:ChallengeStackRowPolicy)
    {
        rows = policy.maxRows > 0 ? waiting.slice(-policy.maxRows) : [];

        var withoutRowCount:Int = waiting.length - rows.length;
        rowHiddenCount = policy.countOnRow ? withoutRowCount : 0;
        barHiddenCount = policy.countOnRow ? 0 : withoutRowCount;
    }
}
