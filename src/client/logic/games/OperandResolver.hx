package client.logic.games;

import client.datatypes.games.ConditionOperator;
import client.datatypes.games.LocalDateTime;

using StringTools;

/** A `DateTime` operand as search and export requests carry it **/
typedef ResolvedInstant =
{
    /** ISO 8601, UTC **/
    at:String,
    /** Whether the bound is non-strict **/
    inclusive:Bool
}

/** Unix milliseconds of a wall-clock time of the viewer's timezone; `month` is 1-12 **/
typedef LocalClock = (year:Int, month:Int, day:Int, hours:Int, minutes:Int, seconds:Int)->Float;

/**
    Resolves `DateTime` operands into UTC instants in the viewer's timezone, by the rules of their
    operator: a date stands for its local midnight, or the next day's one where the whole day has
    to be taken in.
**/
class OperandResolver
{
    private static inline final DAY_MS:Float = 24 * 3600 * 1000;

    /**
        `index`: the operand's position, 0 or 1 for BETWEEN's bounds. `clock` defaults to `Date`'s,
        under which a time skipped by a DST change shifts forward by the gap and a repeated one
        takes its earlier occurrence.
    **/
    public static function resolve(value:LocalDateTime, conditionOperator:ConditionOperator, index:Int, ?clock:LocalClock):ResolvedInstant
    {
        var localClock:LocalClock = clock ?? dateClock;
        var dated:Bool = value.time == null;
        var upperBound:Bool = conditionOperator == GT || conditionOperator == BETWEEN && index == 1;

        if (dated)
        {
            var ms:Float = upperBound ? nextMidnight(value, localClock) : localClock(value.year, value.month, value.day, 0, 0, 0);
            var inclusive:Bool = conditionOperator == GT || conditionOperator == BETWEEN && index == 0;
            return {at: isoUtc(ms), inclusive: inclusive};
        }

        var ms:Float = localClock(value.year, value.month, value.day, value.time.hours, value.time.minutes, value.time.seconds);
        return {at: isoUtc(ms), inclusive: conditionOperator == BETWEEN};
    }

    /** `YYYY-MM-DDTHH:MM:SSZ`, whole seconds **/
    public static function isoUtc(unixMs:Float):String
    {
        var days:Float = Math.ffloor(unixMs / DAY_MS);
        var secondOfDay:Int = Std.int(Math.ffloor((unixMs - days * DAY_MS) / 1000));

        // Civil date from days since the epoch, after Howard Hinnant's `civil_from_days`
        var shifted:Float = days + 719468;
        var era:Float = Math.ffloor(shifted / 146097);
        var dayOfEra:Float = shifted - era * 146097;
        var yearOfEra:Float = Math.ffloor((dayOfEra - Math.ffloor(dayOfEra / 1460) + Math.ffloor(dayOfEra / 36524) - Math.ffloor(dayOfEra / 146096)) / 365);
        var dayOfYear:Float = dayOfEra - (365 * yearOfEra + Math.ffloor(yearOfEra / 4) - Math.ffloor(yearOfEra / 100));
        var monthFromMarch:Float = Math.ffloor((5 * dayOfYear + 2) / 153);
        var day:Int = Std.int(dayOfYear - Math.ffloor((153 * monthFromMarch + 2) / 5) + 1);
        var month:Int = Std.int(monthFromMarch < 10 ? monthFromMarch + 3 : monthFromMarch - 9);
        var year:Int = Std.int(yearOfEra + era * 400 + (month <= 2 ? 1 : 0));

        var time:String = '${pad(Std.int(secondOfDay / 3600))}:${pad(Std.int(secondOfDay / 60) % 60)}:${pad(secondOfDay % 60)}';
        return '$year-${pad(month)}-${pad(day)}T${time}Z';
    }

    public static function daysInMonth(year:Int, month:Int):Int
    {
        return switch month {
            case 2: isLeapYear(year) ? 29 : 28;
            case 4 | 6 | 9 | 11: 30;
            default: 31;
        }
    }

    private static function nextMidnight(value:LocalDateTime, clock:LocalClock):Float
    {
        var year:Int = value.year;
        var month:Int = value.month;
        var day:Int = value.day + 1;
        if (day > daysInMonth(year, month))
        {
            day = 1;
            month++;
            if (month > 12)
            {
                month = 1;
                year++;
            }
        }
        return clock(year, month, day, 0, 0, 0);
    }

    private static function dateClock(year:Int, month:Int, day:Int, hours:Int, minutes:Int, seconds:Int):Float
    {
        return new Date(year, month - 1, day, hours, minutes, seconds).getTime();
    }

    private static function isLeapYear(year:Int):Bool
    {
        return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    }

    private static function pad(value:Int):String
    {
        return Std.string(value).lpad("0", 2);
    }
}
