package client.logic.bot;

import client.datatypes.bot.BotKind;

/** Which strengths a bot may play at, and what a strength means for its search **/
class BotStrengthRules
{
    public static inline final MIN_STRENGTH:Int = 1;
    public static inline final MAX_STRENGTH:Int = 9;

    /** The strongest strength `kind` plays at: only Standard reaches `MAX_STRENGTH` **/
    public static function maxStrength(kind:BotKind):Int
    {
        return kind == STANDARD ? MAX_STRENGTH : MAX_STRENGTH - 1;
    }

    public static function isAvailable(kind:BotKind, strength:Int):Bool
    {
        return strength >= MIN_STRENGTH && strength <= maxStrength(kind);
    }

    /** Handicap of the search, in centiprogressors: 0 at the full strength, 200 at the lowest **/
    public static function weakness(strength:Int):Float
    {
        return (MAX_STRENGTH - strength) * 25;
    }

    /** Search depth, in full moves **/
    public static function halfDepth(strength:Int):Int
    {
        if (strength >= 9)
            return 6;
        else if (strength >= 5)
            return 5;
        else if (strength >= 3)
            return 4;
        else
            return 3;
    }
}
