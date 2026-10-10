package client.formatters;

import haxefolio.LocaleUtils;

class OngoingGameFormatters
{
    private static inline final MINUTE_MS:Float = 60 * 1000;
    private static inline final HOUR_MS:Float = 60 * MINUTE_MS;
    private static inline final DAY_MS:Float = 24 * HOUR_MS;

    /** A locale binding telling how long ago the last move was made, in its largest whole unit **/
    public static function lastMoveAgo(elapsedMs:Float):String
    {
        if (elapsedMs >= DAY_MS)
            return LocaleUtils.localeBinding("intellector.games_widget.last_move.days", Std.string(Std.int(elapsedMs / DAY_MS)));
        else if (elapsedMs >= HOUR_MS)
            return LocaleUtils.localeBinding("intellector.games_widget.last_move.hours", Std.string(Std.int(elapsedMs / HOUR_MS)));
        else if (elapsedMs >= MINUTE_MS)
            return LocaleUtils.localeBinding("intellector.games_widget.last_move.minutes", Std.string(Std.int(elapsedMs / MINUTE_MS)));
        else
            return LocaleUtils.localeBinding("intellector.games_widget.last_move.just_now");
    }
}
