package client.formatters;

import haxefolio.LocaleUtils;

class OngoingGameFormatters
{
    private static inline final MINUTE_MS:Float = 60 * 1000;
    private static inline final HOUR_MS:Float = 60 * MINUTE_MS;
    private static inline final DAY_MS:Float = 24 * HOUR_MS;

    /** A locale binding telling how long ago the last move was made, in its largest whole unit; `elapsedMs` is null when not recorded **/
    public static function lastMoveAgo(elapsedMs:Null<Float>):String
    {
        var unitMs:Null<Float> = lastMoveUnitMs(elapsedMs);
        if (elapsedMs == null || unitMs == null)
            return LocaleUtils.localeBinding(lastMoveKey(elapsedMs, unitMs));
        else
            return LocaleUtils.localeBinding(lastMoveKey(elapsedMs, unitMs), Std.string(Std.int(elapsedMs / unitMs)));
    }

    /** `lastMoveAgo`, resolved in the current language **/
    public static function lastMoveAgoText(elapsedMs:Null<Float>):String
    {
        var unitMs:Null<Float> = lastMoveUnitMs(elapsedMs);
        var binding:String = LocaleUtils.localeBinding(lastMoveKey(elapsedMs, unitMs));
        if (elapsedMs == null || unitMs == null)
            return LocaleUtils.resolveText(binding);
        else
            return LocaleUtils.resolveText(binding, Std.int(elapsedMs / unitMs));
    }

    /** The time since `sinceMs` at Unix time `nowMs`, null when `sinceMs` is **/
    public static function elapsedSince(sinceMs:Null<Float>, nowMs:Float):Null<Float>
    {
        return sinceMs != null ? nowMs - sinceMs : null;
    }

    /** The largest whole unit that has passed, or null if not even a minute has or the time isn't known **/
    private static function lastMoveUnitMs(elapsedMs:Null<Float>):Null<Float>
    {
        if (elapsedMs == null)
            return null;
        else if (elapsedMs >= DAY_MS)
            return DAY_MS;
        else if (elapsedMs >= HOUR_MS)
            return HOUR_MS;
        else if (elapsedMs >= MINUTE_MS)
            return MINUTE_MS;
        else
            return null;
    }

    private static function lastMoveKey(elapsedMs:Null<Float>, unitMs:Null<Float>):String
    {
        if (elapsedMs == null)
            return "intellector.games_widget.last_move.unknown";
        else if (unitMs == DAY_MS)
            return "intellector.games_widget.last_move.days";
        else if (unitMs == HOUR_MS)
            return "intellector.games_widget.last_move.hours";
        else if (unitMs == MINUTE_MS)
            return "intellector.games_widget.last_move.minutes";
        else
            return "intellector.games_widget.last_move.just_now";
    }
}
