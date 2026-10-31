package client.logic.bot;

/** How long a bot may be told to think over a move at most **/
class BotThinkCapRules
{
    public static inline final MIN_SECONDS:Int = 1;
    public static inline final MAX_SECONDS:Int = 1800;

    /** The values the cap steps through **/
    public static final STEPS:Array<Int> = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 300, 600, 900, 1200, 1800];

    public static function isValid(seconds:Int):Bool
    {
        return seconds >= MIN_SECONDS && seconds <= MAX_SECONDS;
    }

    /** The step next to `seconds` in `direction` (-1 or 1), or the last one in that direction **/
    public static function step(seconds:Int, direction:Int):Int
    {
        if (direction > 0)
        {
            for (candidate in STEPS)
                if (candidate > seconds)
                    return candidate;
            return STEPS[STEPS.length - 1];
        }

        var lower:Array<Int> = STEPS.filter(candidate -> candidate < seconds);
        return lower.length > 0 ? lower[lower.length - 1] : STEPS[0];
    }
}
