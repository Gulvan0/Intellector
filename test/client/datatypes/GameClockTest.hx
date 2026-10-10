package client.datatypes;

import utest.Assert;
import utest.Test;

class GameClockTest extends Test
{
    private function testOnlyTickingSideRunsDown():Void
    {
        var clock:GameClock = new GameClock(60_000, 30_000, White, 1_000);
        Assert.equals(50_000, clock.remainingMs(White, 11_000));
        Assert.equals(30_000, clock.remainingMs(Black, 11_000));
    }

    private function testStoppedClockKeepsBothTimes():Void
    {
        var clock:GameClock = new GameClock(60_000, 30_000, null, 0);
        Assert.equals(60_000, clock.remainingMs(White, 99_000));
        Assert.equals(30_000, clock.remainingMs(Black, 99_000));
    }

    private function testNeverBelowZero():Void
    {
        var clock:GameClock = new GameClock(5_000, 30_000, White, 0);
        Assert.equals(0, clock.remainingMs(White, 10_000));
    }
}
