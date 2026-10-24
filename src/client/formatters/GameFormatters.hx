package client.formatters;

import client.GroupedLocaleResolvers;
import client.datatypes.game.GameEnding;
import client.datatypes.game.OfferAction;
import client.datatypes.game.OfferKind;
import client.datatypes.game.Outcome;
import client.datatypes.game.PlayerRating;
import client.datatypes.timecontrol.TimeControl;
import client.openings.OpeningEntry;
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

    /** `1624`, or `1200?` while provisional **/
    public static function bareRating(rating:PlayerRating):String
    {
        return rating.provisional ? '${rating.elo}?' : Std.string(rating.elo);
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

    /** `dateTime`, or a locale binding saying the date is unknown when `unixMs` is null **/
    public static function optionalDateTime(unixMs:Null<Float>):String
    {
        return unixMs != null ? dateTime(unixMs) : LocaleUtils.localeBinding("intellector.common.date_unknown");
    }

    /** Whether the game is rated, then when it started: `Rated · dd.mm.yyyy hh:mm:ss`; the start is null when not recorded **/
    public static function ratedAndStart(rated:Bool, startedAtMs:Null<Float>):String
    {
        return '${LocaleUtils.resolveText(GroupedLocaleResolvers.challengeRated(rated))} · ${LocaleUtils.resolveText(optionalDateTime(startedAtMs))}';
    }

    /**
        The opening line's text for the current language, null when there's no line: no known
        opening reached yet. Opening names stay in English. A game from a custom position says so instead.
    **/
    public static function opening(opening:Null<OpeningEntry>, customStartingPosition:Bool):Null<Void->String>
    {
        if (customStartingPosition)
            return () -> resolve("intellector.common.custom_starting_position");
        if (opening == null)
            return null;
        return () -> opening.name;
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

    /** The chat's note about a draw or takeback offer changing state **/
    public static function offerLogLine(action:OfferAction, kind:OfferKind, author:PieceColor):String
    {
        var kindKey:String = kind.getName().toLowerCase();
        return switch action {
            case Create: LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.common.game.$kindKey.offered_by'), colorName(author));
            case Cancel: resolve('intellector.live_game.chat.log.$kindKey.cancelled');
            case Accept: resolve('intellector.live_game.chat.log.$kindKey.accepted');
            case Decline: resolve('intellector.live_game.chat.log.$kindKey.declined');
        }
    }

    /** `White: +15 seconds` **/
    public static function timeAddedLogLine(receiver:PieceColor, amountSeconds:Int):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.live_game.chat.log.time_added"), colorName(receiver), amountSeconds);
    }

    /** The chat's note about how the game ended: `Black resigned` **/
    public static function outcomeLogLine(outcome:Outcome):String
    {
        return switch outcome {
            case Decisive(kind, winner):
                var key:String = 'intellector.common.outcome.chatbox.decisive.${snakeCase(kind.getName())}';
                LocaleUtils.resolveText(LocaleUtils.localeBinding(key), colorName(winner), colorName(winner.opposite()));
            case Drawish(kind):
                resolve('intellector.common.outcome.chatbox.drawish.${snakeCase(kind.getName())}');
        }
    }

    /** White won, Black won or Draw **/
    public static function result(ending:GameEnding):String
    {
        return switch ending.outcome {
            case Decisive(_, winner): resolve('intellector.common.outcome.result.${winner.getName().toLowerCase()}_won');
            case Drawish(_): resolve("intellector.common.outcome.result.draw");
        }
    }

    /** How the game ended, in the site's terms: `Fatum`, `Black resigned`; empty while it goes on or for an aborted game **/
    public static function outcomeReason(ending:Null<GameEnding>):String
    {
        if (ending == null)
            return "";

        return switch ending.outcome {
            case Drawish(Abort):
                "";
            case Decisive(kind, winner):
                var key:String = 'intellector.common.outcome_reason.${snakeCase(kind.getName())}';
                LocaleUtils.resolveText(LocaleUtils.localeBinding(key), colorName(winner), colorName(winner.opposite()));
            case Drawish(kind):
                resolve('intellector.common.outcome_reason.${snakeCase(kind.getName())}');
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

    /** `CheatingAbort` → `cheating_abort` **/
    public static function snakeCase(name:String):String
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
