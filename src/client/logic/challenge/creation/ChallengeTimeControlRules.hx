package client.logic.challenge.creation;

import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.timecontrol.FischerTimeControl;
import client.datatypes.timecontrol.TimeControl;
import client.datatypes.timecontrol.TimeControlKind;

/**
    The time controls a challenge may have: the presets offered, and the bounds on an initial time
    and a bonus set by hand.
**/
class ChallengeTimeControlRules
{
    public static final PRESETS:Array<FischerTimeControl> = [
        new FischerTimeControl(60, 0),
        new FischerTimeControl(180, 0),
        new FischerTimeControl(180, 2),
        new FischerTimeControl(300, 0),
        new FischerTimeControl(600, 0),
        new FischerTimeControl(600, 5),
        new FischerTimeControl(900, 10),
        new FischerTimeControl(1800, 0),
        new FischerTimeControl(3600, 0)
    ];
    public static inline final MAX_START_SECONDS:Int = 6 * 60 * 60;
    public static inline final MAX_INCREMENT_SECONDS:Int = 120;

    private static inline final STEP_SECONDS:Int = 60;
    private static inline final MIN_STEPPED_START_SECONDS:Int = 30;

    public static function isValidStartSeconds(seconds:Int):Bool
    {
        return seconds > 0 && seconds <= MAX_START_SECONDS;
    }

    public static function isValidIncrementSeconds(seconds:Int):Bool
    {
        return seconds >= 0 && seconds <= MAX_INCREMENT_SECONDS;
    }

    /** `current` moved a minute up (`direction` = 1) or down (-1), kept within the bounds **/
    public static function stepStartSeconds(current:Int, direction:Int):Int
    {
        var stepped:Int = current + direction * STEP_SECONDS;
        return Std.int(Math.max(MIN_STEPPED_START_SECONDS, Math.min(MAX_START_SECONDS, stepped)));
    }

    public static function isValid(draft:ChallengeDraft):Bool
    {
        return !draft.timed || (isValidStartSeconds(draft.startSeconds) && isValidIncrementSeconds(draft.incrementSeconds));
    }

    public static function timeControl(draft:ChallengeDraft):TimeControl
    {
        return draft.timed ? Fischer(new FischerTimeControl(draft.startSeconds, draft.incrementSeconds)) : None;
    }

    public static function kind(draft:ChallengeDraft):TimeControlKind
    {
        return draft.timed ? new FischerTimeControl(draft.startSeconds, draft.incrementSeconds).getKind() : Correspondence;
    }

    /** The index of the preset holding exactly the draft's values, or null **/
    public static function matchingPreset(draft:ChallengeDraft):Null<Int>
    {
        if (!draft.timed)
            return null;

        for (i in 0...PRESETS.length)
            if (PRESETS[i].startSeconds == draft.startSeconds && PRESETS[i].incrementSeconds == draft.incrementSeconds)
                return i;

        return null;
    }
}
