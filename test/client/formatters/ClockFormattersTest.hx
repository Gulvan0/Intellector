package client.formatters;

import utest.Assert;
import utest.Test;

class ClockFormattersTest extends Test
{
    private function testUnderAnHour():Void
    {
        Assert.equals("01:48", ClockFormatters.formatRemainingTime(108_000));
        Assert.equals("00:00", ClockFormatters.formatRemainingTime(0));
    }

    private function testRoundsUpToWholeSeconds():Void
    {
        Assert.equals("00:01", ClockFormatters.formatRemainingTime(1));
        Assert.equals("10:00", ClockFormatters.formatRemainingTime(599_001));
    }

    private function testFromAnHourOn():Void
    {
        Assert.equals("1:00:00", ClockFormatters.formatRemainingTime(3_600_000));
        Assert.equals("2:05:09", ClockFormatters.formatRemainingTime(7_509_000));
    }
}
