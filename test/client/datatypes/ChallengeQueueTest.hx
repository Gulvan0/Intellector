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
        Assert.isFalse(queue.accepting);
    }

    private function testFirstAnnouncedIsActiveOthersWaitInArrivalOrder():Void
    {
        announceAll([5, 3, 8]);
        assertState(5, [3, 8]);
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

    private function testSyncAnnouncesNewInIdOrderAndRemovesUnlisted():Void
    {
        announceAll([1, 2]);
        queue.sync(Challenges.makeAll([6, 2, 4]));
        assertState(2, [4, 6]);
    }

    private function testSyncDoesNotBringBackHidden():Void
    {
        announceAll([1, 2]);
        queue.hideAll();
        queue.sync(Challenges.makeAll([1, 2, 3]));
        assertState(3, []);
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

    private function testBeginAcceptReturnsActive():Void
    {
        announceAll([1, 2]);
        Assert.equals(1, queue.beginAccept()?.id);
        Assert.isTrue(queue.accepting);
        assertState(1, [2]);
    }

    private function testBeginAcceptOnEmptyQueue():Void
    {
        Assert.isNull(queue.beginAccept());
        Assert.isFalse(queue.accepting);
    }

    private function testOnlyOneAcceptanceAtATime():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        Assert.isNull(queue.beginAccept());
    }

    private function testSelectIgnoredWhileAccepting():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        queue.select(2);
        assertState(1, [2]);
    }

    private function testAcceptFailedEndsAcceptance():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        queue.acceptFailed(1);
        Assert.isFalse(queue.accepting);
        assertState(1, [2]);
    }

    private function testAcceptFailedForAnotherIdIsIgnored():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        queue.acceptFailed(2);
        Assert.isTrue(queue.accepting);
    }

    private function testRemovingAcceptedChallengeEndsAcceptance():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        queue.remove(1);
        Assert.isFalse(queue.accepting);
        assertState(2, []);
    }

    private function testRemovingAnotherChallengeKeepsAcceptance():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        queue.remove(2);
        Assert.isTrue(queue.accepting);
    }

    private function testDeclineAllReturnsEveryChallenge():Void
    {
        announceAll([1, 2, 3]);
        queue.select(2);
        Assert.same([1, 2, 3], Challenges.ids(queue.declineAll()));
        assertState(null, []);
    }

    private function testDeclineAllIgnoredWhileAccepting():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        Assert.same([], queue.declineAll());
        assertState(1, [2]);
    }

    private function testHideAllIgnoredWhileAccepting():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        queue.hideAll();
        assertState(1, [2]);
    }

    private function testClearWorksWhileAccepting():Void
    {
        announceAll([1, 2]);
        queue.beginAccept();
        queue.clear();
        assertState(null, []);
        Assert.isFalse(queue.accepting);
    }

    private function testResetForgetsAnnounced():Void
    {
        announceAll([1, 2]);
        queue.reset();
        announceAll([2, 1]);
        assertState(2, [1]);
    }
}
