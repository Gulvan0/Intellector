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
}
