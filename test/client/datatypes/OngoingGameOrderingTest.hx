package client.datatypes;

import testutils.OngoingGames;
import utest.Assert;
import utest.Test;

class OngoingGameOrderingTest extends Test
{
    private function testTimedOwnMoveFirstThenLeastOwnTime():Void
    {
        var games:Array<OngoingGame> = [
            OngoingGames.timed(1, false, 50_000, 10_000),
            OngoingGames.timed(2, true, 90_000, 10_000),
            OngoingGames.timed(3, false, 20_000, 10_000),
            OngoingGames.timed(4, true, 30_000, 10_000)
        ];
        Assert.same([4, 2, 3, 1], OngoingGames.ids(OngoingGameOrdering.timed(games, 0)));
    }

    private function testTimedOrderAccountsForRunningClocks():Void
    {
        // at 25 s, game 1's running own clock is below game 2's stopped one
        var games:Array<OngoingGame> = [
            OngoingGames.timed(2, false, 40_000, 10_000),
            OngoingGames.timed(1, true, 60_000, 10_000)
        ];
        Assert.same([1, 2], OngoingGames.ids(OngoingGameOrdering.timed(games, 25_000)));
    }

    private function testTiesFallBackToId():Void
    {
        var games:Array<OngoingGame> = [
            OngoingGames.timed(7, true, 30_000, 10_000),
            OngoingGames.timed(3, true, 30_000, 10_000)
        ];
        Assert.same([3, 7], OngoingGames.ids(OngoingGameOrdering.timed(games, 0)));
    }

    private function testCorrespondenceOwnMoveFirstThenLongestWaiting():Void
    {
        var games:Array<OngoingGame> = [
            OngoingGames.correspondence(1, false, 100),
            OngoingGames.correspondence(2, true, 300),
            OngoingGames.correspondence(3, true, 200),
            OngoingGames.correspondence(4, false, 50)
        ];
        Assert.same([3, 2, 4, 1], OngoingGames.ids(OngoingGameOrdering.correspondence(games)));
    }

    private function testCorrespondenceWithoutMovesWaitsSinceStart():Void
    {
        var games:Array<OngoingGame> = [
            OngoingGames.correspondence(1, true, 100),
            OngoingGames.correspondence(2, true, null, 50)
        ];
        Assert.same([2, 1], OngoingGames.ids(OngoingGameOrdering.correspondence(games)));
    }
}
