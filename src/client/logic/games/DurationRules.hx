package client.logic.games;

import client.datatypes.games.DurationUnit;
import client.datatypes.games.GameProperty;
import client.logic.challenge.creation.ChallengeTimeControlRules;

/** Which units a `Duration` operand is entered in, and which totals it admits, per property **/
class DurationRules
{
    /** Largest first **/
    public static function units(property:GameProperty):Array<DurationUnit>
    {
        return switch property {
            case INITIAL_TIME | TIME_LEFT: [Hour, Minute, Second];
            case BONUS_TIME: [Minute, Second];
            case DURATION: [Day, Hour, Minute];
            default: throw 'Not a duration property: $property';
        }
    }

    public static function minMs(property:GameProperty):Float
    {
        return property == INITIAL_TIME ? 1000.0 : 0.0;
    }

    /** Null: unbounded **/
    public static function maxMs(property:GameProperty):Null<Float>
    {
        return switch property {
            case INITIAL_TIME: ChallengeTimeControlRules.MAX_START_SECONDS * 1000.0;
            case BONUS_TIME: ChallengeTimeControlRules.MAX_INCREMENT_SECONDS * 1000.0;
            default: null;
        }
    }

    public static function unitMs(unit:DurationUnit):Float
    {
        return switch unit {
            case Millisecond: 1;
            case Second: 1000;
            case Minute: 60000;
            case Hour: 3600000;
            case Day: 86400000;
            case Month: 30 * 86400000.0;
        }
    }

    /** The field's own range below the largest unit, which is bounded by the total alone **/
    public static function naturalMax(unit:DurationUnit):Int
    {
        return switch unit {
            case Millisecond: 999;
            case Second | Minute: 59;
            case Hour: 23;
            case Day: 29;
            case Month: throw "Months are never below another unit";
        }
    }

    /** `ms` split into `units` (largest first), the smallest one taking the remainder **/
    public static function split(ms:Float, units:Array<DurationUnit>):Array<Int>
    {
        var remaining:Float = ms;
        var parts:Array<Int> = [];
        for (unit in units)
        {
            var part:Float = Math.ffloor(remaining / unitMs(unit));
            parts.push(Std.int(part));
            remaining -= part * unitMs(unit);
        }
        return parts;
    }

    public static function join(parts:Array<Int>, units:Array<DurationUnit>):Float
    {
        var total:Float = 0;
        for (i in 0...units.length)
            total += parts[i] * unitMs(units[i]);
        return total;
    }
}
