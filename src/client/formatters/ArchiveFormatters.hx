package client.formatters;

import client.datatypes.game.Outcome;
import client.datatypes.games.ConditionOperator;
import client.datatypes.games.ConditionParameter;
import client.datatypes.games.DateTimeBound;
import client.datatypes.games.EqualityValue;
import client.datatypes.games.GameProperty;
import client.datatypes.games.LocalDateTime;
import client.datatypes.games.Operand;
import client.datatypes.games.PlayerValue;
import client.datatypes.games.ResultColumn;
import client.logic.bot.BotKinds;
import client.logic.games.ImplicitRestrictions.ImplicitRestriction;
import client.logic.games.ResultColumns;
import client.openings.OpeningEntry;
import client.openings.OpeningTree;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;

using StringTools;

/** The game database's texts, resolved for the current language **/
class ArchiveFormatters
{
    private static inline final ANACONDA_NAME:String = "Anaconda";
    private static inline final MIN_DAYS_IN_WHOLE_DAYS:Int = 5;
    private static inline final MIDNIGHT:String = "00:00";

    /** `D:HH:MM:SS` in whole seconds, the leading zero components stripped down to `M:SS`: `0:03`, `5:00`, `1:02:03` **/
    public static function clock(ms:Float):String
    {
        var totalSeconds:Float = Math.ffloor(ms / 1000);
        var components:Array<Int> = [
            Std.int(totalSeconds / 86400),
            Std.int(totalSeconds / 3600) % 24,
            Std.int(totalSeconds / 60) % 60,
            Std.int(totalSeconds % 60)
        ];
        while (components.length > 2 && components[0] == 0)
            components.shift();
        return [for (i in 0...components.length) i == 0 ? Std.string(components[i]) : Std.string(components[i]).lpad("0", 2)].join(":");
    }

    /** Whole days from `MIN_DAYS_IN_WHOLE_DAYS` days on (`7 days`), `clock` below **/
    public static function duration(ms:Float):String
    {
        var days:Int = Std.int(ms / 86400000);
        if (days < MIN_DAYS_IN_WHOLE_DAYS)
            return clock(ms);
        return LocaleUtils.resolveText(LocaleUtils.localeBinding(Plurals.key("intellector.games.duration_days", days, LocaleManager.instance.language)), days);
    }

    /** `DD.MM.YYYY` or `DD.MM.YYYY HH:MM:SS` **/
    public static function localDateTime(value:LocalDateTime):String
    {
        var date:String = '${pad(value.day)}.${pad(value.month)}.${value.year}';
        if (value.time == null)
            return date;
        return '$date ${pad(value.time.hours)}:${pad(value.time.minutes)}:${pad(value.time.seconds)}';
    }

    /** What a `DateTime` operand resolves to as `bound`: `Before 13.06.2024, 00:00`; asks for a day while there is none **/
    public static function resolvedBound(value:Null<LocalDateTime>, bound:DateTimeBound):String
    {
        if (value == null)
            return resolve("intellector.games.step.date.pick_day");

        var date:String = localDateTime(new LocalDateTime(value.year, value.month, value.day));
        var time:Null<String> = value.time != null ? '${pad(value.time.hours)}:${pad(value.time.minutes)}:${pad(value.time.seconds)}' : null;
        var key:String = switch [bound, time != null] {
            case [Before, _]: "before";
            case [After, true]: "after";
            case [After, false]: "from_next";
            case [FromInclusive, _]: "from_inclusive";
            case [UpToInclusive, true]: "up_to_inclusive";
            case [UpToInclusive, false]: "through_end";
        }
        var shownDate:String = bound == After && time == null ? nextDay(value) : date;
        return LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.games.step.date.resolved.$key'), shownDate, time ?? MIDNIGHT);
    }

    public static function propertyName(property:GameProperty):String
    {
        return resolve('intellector.games.property.$property');
    }

    /** The property, followed by the side or player it's taken of: `ELO (White)` **/
    public static function conditionSubject(property:GameProperty, parameter:Null<ConditionParameter>):String
    {
        var name:String = propertyName(property);
        return switch parameter {
            case null | EitherColor: name;
            case OfColor(color): '$name (${GameFormatters.colorName(color)})';
            case OfPlayer(player): '$name (${playerName(player)})';
        }
    }

    public static function playerName(player:PlayerValue):String
    {
        return switch player {
            case User(login): login;
            case Guest(id): LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.common.player.guest_name", Std.string(id)));
            case Bot(AnyBot): resolve("intellector.games.value.any_bot");
            case Bot(Anaconda): ANACONDA_NAME;
            case Bot(AnyLevel(kind)): BotKinds.displayName(kind);
            case Bot(Level(kind, level)): '${BotKinds.displayName(kind)} $level';
        }
    }

    /** `<`, `≥`, or a word for BETWEEN and UNKNOWN; `compact` gives `?` for UNKNOWN, as the operator list shows it **/
    public static function operatorSymbol(conditionOperator:ConditionOperator, compact:Bool = false):String
    {
        if (compact && conditionOperator == UNKNOWN)
            return "?";
        return switch conditionOperator {
            case LT: "<";
            case GT: ">";
            case LE: "≤";
            case GE: "≥";
            case EQ: "=";
            case BETWEEN: resolve("intellector.games.operator.between");
            case UNKNOWN: resolve("intellector.games.operator.unknown");
        }
    }

    /** Joins BETWEEN's bounds **/
    public static function boundsConjunction():String
    {
        return resolve("intellector.games.operator.and");
    }

    public static function operandText(operand:Operand):String
    {
        return switch operand {
            case DateTimeValue(value): localDateTime(value);
            case DurationValue(ms): duration(ms);
            case IntValue(value): Std.string(value);
        }
    }

    public static function valueText(value:EqualityValue):String
    {
        return switch value {
            case IsPlayer(player): playerName(player);
            case IsOngoing: resolve("intellector.games.value.no_winner_yet");
            case IsDraw: resolve("intellector.games.value.no_winner_draw");
            case IsTimeControlKind(kind): resolve('intellector.common.time_control_kind.${kind.getName().toLowerCase()}');
            case IsBool(flag): resolve(flag ? "intellector.games.value.yes" : "intellector.games.value.no");
            case IsDecisiveOutcome(kind): resolve('intellector.games.outcome_kind.${GameFormatters.snakeCase(kind.getName())}');
            case IsDrawishOutcome(kind): resolve('intellector.games.outcome_kind.${GameFormatters.snakeCase(kind.getName())}');
            case IsDefaultPosition: resolve("intellector.games.value.default_position");
            case IsCustomPosition(sip): sip;
            case IsOpening(id): openingName(id);
            case IsResult(result): resolve('intellector.games.value.result.$result');
        }
    }

    public static function openingName(id:Int):String
    {
        var entry:Null<OpeningEntry> = OpeningTree.byId.get(id);
        return entry != null ? entry.name : '#$id';
    }

    /** `Also excludes correspondence games and games paul did not play` **/
    public static function restrictions(restrictions:Array<ImplicitRestriction>):String
    {
        var parts:Array<String> = restrictions.map(restriction -> switch restriction {
            case ExcludesCorrespondence: resolve("intellector.games.restriction.correspondence");
            case ExcludesUnrated: resolve("intellector.games.restriction.unrated");
            case ExcludesOngoing: resolve("intellector.games.restriction.ongoing");
            case OnlyGamesOf(player): LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.restriction.not_played"), playerName(player));
        });
        var listed:String = parts.length > 1 ? LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.restriction.pair"), parts.slice(0, -1).join(", "), parts[parts.length - 1]) : parts[0];
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.restriction.also_excludes"), listed);
    }

    public static function columnName(column:ResultColumn):String
    {
        return resolve(ResultColumns.nameKey(column));
    }

    /** How the game ended, as the game cards tell it; null while it goes on **/
    public static function outcome(outcome:Null<Outcome>):Null<String>
    {
        return switch outcome {
            case null: null;
            case Drawish(Abort): resolve("intellector.games.outcome_kind.abort");
            case Decisive(kind, winner): LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.common.outcome_reason.${GameFormatters.snakeCase(kind.getName())}'), GameFormatters.colorName(winner), GameFormatters.colorName(winner.opposite()));
            case Drawish(kind): resolve('intellector.common.outcome_reason.${GameFormatters.snakeCase(kind.getName())}');
        }
    }

    public static function result(outcome:Null<Outcome>):String
    {
        return switch outcome {
            case null: resolve("intellector.games.value.result.ongoing");
            case Decisive(_, White): resolve("intellector.common.outcome.result.white_won");
            case Decisive(_, Black): resolve("intellector.common.outcome.result.black_won");
            case Drawish(_): resolve("intellector.common.outcome.result.draw");
        }
    }

    private static function resolve(key:String):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding(key));
    }

    private static function nextDay(value:LocalDateTime):String
    {
        var next:Date = new Date(value.year, value.month - 1, value.day + 1, 0, 0, 0);
        return localDateTime(new LocalDateTime(next.getFullYear(), next.getMonth() + 1, next.getDate()));
    }

    private static function pad(value:Int):String
    {
        return Std.string(value).lpad("0", 2);
    }
}
