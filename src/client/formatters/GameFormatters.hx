package client.formatters;

import client.GroupedLocaleResolvers;
import client.datatypes.game.GameEnding;
import client.datatypes.game.Outcome;
import client.datatypes.game.PlayerRating;
import client.datatypes.timecontrol.TimeControl;
import client.openings.OpeningEntry;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceColor;

class GameFormatters
{
    /** `(1624)`, `(1200?)` while provisional, or empty without a rating **/
    public static function rating(rating:Null<PlayerRating>):String
    {
        if (rating == null)
            return "";
        return rating.provisional ? '(${rating.elo}?)' : '(${rating.elo})';
    }

    /** `+12`, `-8` or `±0` **/
    public static function eloDelta(delta:Int):String
    {
        if (delta > 0)
            return '+$delta';
        if (delta < 0)
            return Std.string(delta);
        return "±0";
    }

    /** `3+2 · Blitz`, or the correspondence time control's name **/
    public static function timeControl(timeControl:TimeControl):String
    {
        var kindName:String = LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.common.time_control_kind.${timeControl.getKind().getName().toLowerCase()}'));
        return switch timeControl {
            case None: kindName;
            case Fischer(instance): '${TimeControlFormatters.formatFischerTimeControl(instance)} · $kindName';
        }
    }

    /** `dd.mm.yyyy hh:mm:ss`, local time **/
    public static function dateTime(unixMs:Float):String
    {
        return DateTools.format(Date.fromTime(unixMs), "%d.%m.%Y %H:%M:%S");
    }

    /** Whether the game is rated, then when it started: `Rated · dd.mm.yyyy hh:mm:ss` **/
    public static function ratedAndStart(rated:Bool, startedAtMs:Float):String
    {
        return '${LocaleUtils.resolveText(GroupedLocaleResolvers.challengeRated(rated))} · ${dateTime(startedAtMs)}';
    }

    /**
        The opening line's text for the current language, null when there's no line: no known
        opening reached yet. A game from a custom position says so instead.
    **/
    public static function opening(opening:Null<OpeningEntry>, customStartingPosition:Bool):Null<Void->String>
    {
        if (customStartingPosition)
            return () -> resolve("intellector.common.custom_starting_position");
        if (opening == null)
            return null;
        return () -> LocaleManager.instance.language == "ru" ? opening.name_ru : opening.name_en;
    }

    /** The resolution line: in progress, or how the game ended **/
    public static function resolution(ending:Null<GameEnding>):String
    {
        if (ending == null)
            return resolve("intellector.common.outcome.resolution.in_progress");

        return switch ending.outcome {
            case Decisive(kind, winner):
                var key:String = 'intellector.common.outcome.resolution.decisive.${snakeCase(kind.getName())}';
                LocaleUtils.resolveText(LocaleUtils.localeBinding(key), colorName(winner), colorName(winner.opposite()));
            case Drawish(kind):
                resolve('intellector.common.outcome.resolution.drawish.${snakeCase(kind.getName())}');
        }
    }

    public static function colorName(color:PieceColor):String
    {
        return resolve('intellector.common.color.${color.getName().toLowerCase()}');
    }

    private static function resolve(key:String):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding(key));
    }

    private static function snakeCase(name:String):String
    {
        var result:String = "";
        for (i in 0...name.length)
        {
            var char:String = name.charAt(i);
            var lower:String = char.toLowerCase();
            result += i > 0 && char != lower ? '_$lower' : lower;
        }
        return result;
    }
}
