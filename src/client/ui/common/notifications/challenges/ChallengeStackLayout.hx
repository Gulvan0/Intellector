package client.ui.common.notifications.challenges;

import client.datatypes.IncomingChallenge;

/** Which waiting challenges get a row, and where the count of those without one goes **/
class ChallengeStackLayout
{
    private static inline final MAX_ROWS_EXPANDED:Int = 3;
    private static inline final MAX_ROWS_COLLAPSED:Int = 1;

    /** The newest waiting challenges, oldest first **/
    public final rows:Array<IncomingChallenge>;
    /** Shown on the newest row; collapsed only **/
    public final rowHiddenCount:Int;
    /** Shown on the bar; expanded only **/
    public final barHiddenCount:Int;

    /** `waiting` in arrival order **/
    public function new(waiting:Array<IncomingChallenge>, collapsed:Bool)
    {
        rows = waiting.slice(collapsed ? -MAX_ROWS_COLLAPSED : -MAX_ROWS_EXPANDED);

        var withoutRowCount:Int = waiting.length - rows.length;
        rowHiddenCount = collapsed ? withoutRowCount : 0;
        barHiddenCount = collapsed ? 0 : withoutRowCount;
    }
}
