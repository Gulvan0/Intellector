package client.logic.games;

import client.datatypes.games.LocalDateTime;
import client.datatypes.games.TimeOfDay;
import client.logic.games.OperandResolver.ResolvedInstant;
import utest.Assert;
import utest.Test;

class OperandResolverTest extends Test
{
    private static inline final HOUR_MS:Float = 3600 * 1000;

    /** A fixed UTC+2 wall clock **/
    public static function utcPlusTwo(year:Int, month:Int, day:Int, hours:Int, minutes:Int, seconds:Int):Float
    {
        return utcMs(year, month, day, hours, minutes, seconds) - 2 * HOUR_MS;
    }

    /*
        UTC+1 until 2024-03-31 02:00 local, UTC+2 after: 02:00-02:59 that day is skipped, shifting
        forward by the gap as JS Date does
    */
    private static function springForward(year:Int, month:Int, day:Int, hours:Int, minutes:Int, seconds:Int):Float
    {
        var afterChange:Bool = year > 2024 || year == 2024 && (month > 3 || month == 3 && (day > 31 || day == 31 && hours >= 2));
        var skipped:Bool = year == 2024 && month == 3 && day == 31 && hours == 2;
        return utcMs(year, month, day, hours, minutes, seconds) - (afterChange && !skipped ? 2 : 1) * HOUR_MS;
    }

    private function testDateBeforeIsItsMidnightExclusive():Void
    {
        assertResolved({at: "2024-06-12T22:00:00Z", inclusive: false}, date(2024, 6, 13), LT, 0);
    }

    private function testDateAfterIsNextMidnightInclusive():Void
    {
        assertResolved({at: "2024-06-13T22:00:00Z", inclusive: true}, date(2024, 6, 13), GT, 0);
    }

    private function testDateBoundsTakeWholeDays():Void
    {
        assertResolved({at: "2024-06-12T22:00:00Z", inclusive: true}, date(2024, 6, 13), BETWEEN, 0);
        assertResolved({at: "2024-06-14T22:00:00Z", inclusive: false}, date(2024, 6, 14), BETWEEN, 1);
    }

    private function testDateTimes():Void
    {
        var value:LocalDateTime = new LocalDateTime(2024, 6, 13, new TimeOfDay(14, 30, 5));
        assertResolved({at: "2024-06-13T12:30:05Z", inclusive: false}, value, LT, 0);
        assertResolved({at: "2024-06-13T12:30:05Z", inclusive: false}, value, GT, 0);
        assertResolved({at: "2024-06-13T12:30:05Z", inclusive: true}, value, BETWEEN, 0);
        assertResolved({at: "2024-06-13T12:30:05Z", inclusive: true}, value, BETWEEN, 1);
    }

    private function testNextMidnightRollsOver():Void
    {
        assertResolved({at: "2024-02-29T22:00:00Z", inclusive: true}, date(2024, 2, 29), GT, 0);
        assertResolved({at: "2023-02-28T22:00:00Z", inclusive: true}, date(2023, 2, 28), GT, 0);
        assertResolved({at: "2024-12-31T22:00:00Z", inclusive: false}, date(2024, 12, 31), BETWEEN, 1);
    }

    private function testDstChangeDayUsesEachMidnightsOffset():Void
    {
        Assert.same({at: "2024-03-30T23:00:00Z", inclusive: false}, OperandResolver.resolve(date(2024, 3, 31), LT, 0, springForward));
        Assert.same({at: "2024-03-31T22:00:00Z", inclusive: true}, OperandResolver.resolve(date(2024, 3, 31), GT, 0, springForward));
    }

    private function testSkippedTimeShiftsForward():Void
    {
        var skipped:LocalDateTime = new LocalDateTime(2024, 3, 31, new TimeOfDay(2, 30, 0));
        Assert.same({at: "2024-03-31T01:30:00Z", inclusive: false}, OperandResolver.resolve(skipped, LT, 0, springForward));
    }

    private static function date(year:Int, month:Int, day:Int):LocalDateTime
    {
        return new LocalDateTime(year, month, day);
    }

    private static function assertResolved(expected:ResolvedInstant, value:LocalDateTime, conditionOperator:client.datatypes.games.ConditionOperator, index:Int):Void
    {
        Assert.same(expected, OperandResolver.resolve(value, conditionOperator, index, utcPlusTwo));
    }

    private static function utcMs(year:Int, month:Int, day:Int, hours:Int, minutes:Int, seconds:Int):Float
    {
        var days:Float = 0.0;
        for (y in 1970...year)
            days += OperandResolver.daysInMonth(y, 2) == 29 ? 366 : 365;
        for (m in 1...month)
            days += OperandResolver.daysInMonth(year, m);
        days += day - 1;
        return ((days * 24.0 + hours) * 60.0 + minutes) * 60000.0 + seconds * 1000.0;
    }
}
