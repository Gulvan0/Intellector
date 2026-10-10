package client.datatypes;

import testutils.Challenges;
import utest.Assert;
import utest.Test;

class ChallengeQueueTest extends Test
{
    private var queue:ChallengeQueue;

    private function setup():Void
    {
        queue = new ChallengeQueue();
    }

    private function announceAll(ids:Array<Int>):Void
    {
        for (challenge in Challenges.makeAll(ids))
            queue.announce(challenge);
    }

    private function assertState(activeId:Null<Int>, waitingIds:Array<Int>, ?pos:haxe.PosInfos):Void
    {
        Assert.equals(activeId, queue.active?.id, pos);
        Assert.same(waitingIds, Challenges.ids(queue.waiting), pos);
    }

    private function testEmptyQueue():Void
    {
        assertState(null, []);
    }

    private function testFirstAnnouncedIsActiveOthersWaitInArrivalOrder():Void
    {
        announceAll([5, 3, 8]);
        assertState(5, [3, 8]);
        Assert.same([5, 3, 8], Challenges.ids(queue.all));
    }

    private function testAnnounceIgnoresRepeats():Void
    {
        announceAll([1, 2, 1]);
        assertState(1, [2]);
    }

    private function testRemovedChallengeIsNotAnnouncedAgain():Void
    {
        announceAll([1, 2]);
        queue.remove(2);
        announceAll([2]);
        assertState(1, []);
    }

    private function testSkippedChallengeIsNeverAnnounced():Void
    {
        queue.skip(1);
        announceAll([1, 2]);
        assertState(2, []);
    }

    private function testRemovingActivePromotesNewest():Void
    {
        announceAll([1, 2, 3]);
        queue.remove(1);
        assertState(3, [2]);
    }

    private function testRemovingWaitingKeepsActive():Void
    {
        announceAll([1, 2, 3]);
        queue.remove(3);
        assertState(1, [2]);
    }

    private function testRemovingLastLeavesQueueEmpty():Void
    {
        announceAll([1]);
        queue.remove(1);
        assertState(null, []);
    }

    private function testRemovingUnknownIdChangesNothing():Void
    {
        announceAll([1, 2]);
        queue.remove(7);
        assertState(1, [2]);
    }

    private function testSelectSwitchesActive():Void
    {
        announceAll([1, 2, 3]);
        queue.select(2);
        assertState(2, [1, 3]);
    }

    private function testSelectIgnoresUnknownId():Void
    {
        announceAll([1, 2]);
        queue.select(7);
        assertState(1, [2]);
    }

    private function testClearedChallengesStayAnnounced():Void
    {
        announceAll([1, 2]);
        queue.clear();
        announceAll([1, 2, 3]);
        assertState(3, []);
    }

    private function testResetForgetsAnnounced():Void
    {
        announceAll([1, 2]);
        queue.reset();
        announceAll([2, 1]);
        assertState(2, [1]);
    }
}
