package client.datatypes.game;

import intellectorboard.primitives.piece.PieceColor;
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

    private function testPlyAddsIncrementOnlyToARunningClock():Void
    {
        var running:GameClock = new GameClock(60_000, 30_000, White, 0);
        var afterPly:GameClock = running.afterPly(White, 10_000, 2_000, true);
        Assert.equals(52_000, afterPly.whiteMs);
        Assert.equals(Black, afterPly.tickingSide);

        var notStarted:GameClock = new GameClock(60_000, 60_000, null, 0);
        Assert.equals(60_000, notStarted.afterPly(White, 10_000, 2_000, false).whiteMs);
        Assert.isNull(notStarted.afterPly(White, 10_000, 2_000, false).tickingSide);
    }
}
