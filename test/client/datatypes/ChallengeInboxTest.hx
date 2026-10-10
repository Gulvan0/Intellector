package client.datatypes;

import testutils.Challenges;
import utest.Assert;
import utest.Test;

class ChallengeInboxTest extends Test
{
    private var inbox:ChallengeInbox;

    private function setup():Void
    {
        inbox = new ChallengeInbox();
    }

    private function receiveAll(ids:Array<Int>, notify:Bool = true):Void
    {
        for (challenge in Challenges.makeAll(ids))
            inbox.receive(challenge, notify);
    }

    private function assertIncoming(ids:Array<Int>, notifiedIds:Array<Int>, ?pos:haxe.PosInfos):Void
    {
        Assert.same(ids, Challenges.ids(inbox.incoming), pos);
        Assert.same(notifiedIds, Challenges.ids(inbox.notification.all), pos);
    }

    private function testReceivedChallengesAreNotified():Void
    {
        receiveAll([1, 2]);
        assertIncoming([1, 2], [1, 2]);
        Assert.isTrue(inbox.hasUnseenIncoming);
    }

    private function testReceiveIgnoresPendingOnes():Void
    {
        receiveAll([1, 2, 1]);
        assertIncoming([1, 2], [1, 2]);
    }

    private function testUnnotifiedChallengeStaysPendingButNeverNotified():Void
    {
        receiveAll([1], false);
        inbox.syncIncoming(Challenges.makeAll([1]), true);
        assertIncoming([1], []);
        Assert.isFalse(inbox.hasUnseenIncoming);
    }

    private function testMarkSeenClearsUnseen():Void
    {
        receiveAll([1]);
        inbox.markSeen();
        Assert.isFalse(inbox.hasUnseenIncoming);
    }

    private function testSyncAddsNewInIdOrderAndRemovesUnlisted():Void
    {
        receiveAll([1, 2]);
        inbox.syncIncoming(Challenges.makeAll([6, 2, 4]), true);
        assertIncoming([2, 4, 6], [2, 4, 6]);
    }

    private function testHiddenChallengeStaysPending():Void
    {
        receiveAll([1, 2]);
        inbox.hideNotified(1);
        assertIncoming([1, 2], [2]);
    }

    private function testHideAllKeepsEverythingPending():Void
    {
        receiveAll([1, 2]);
        inbox.hideAllNotified();
        inbox.syncIncoming(Challenges.makeAll([1, 2]), true);
        assertIncoming([1, 2], []);
    }

    private function testRemoveIncomingDropsItEverywhere():Void
    {
        receiveAll([1, 2]);
        inbox.removeIncoming(1);
        assertIncoming([2], [2]);
    }

    private function testDeclineReturnsAndRemoves():Void
    {
        receiveAll([1, 2]);
        Assert.equals(2, inbox.decline(2)?.id);
        assertIncoming([1], [1]);
    }

    private function testDeclineUnknownReturnsNull():Void
    {
        Assert.isNull(inbox.decline(5));
    }

    private function testDeclineNotifiedLeavesHiddenOnesPending():Void
    {
        receiveAll([1, 2, 3]);
        inbox.hideNotified(2);
        Assert.same([1, 3], Challenges.ids(inbox.declineNotified()));
        assertIncoming([2], []);
    }

    private function testBeginAcceptReturnsTheChallenge():Void
    {
        receiveAll([1, 2]);
        Assert.equals(2, inbox.beginAccept(2)?.id);
        Assert.equals(2, inbox.acceptingId);
    }

    private function testOnlyOneAcceptanceAtATime():Void
    {
        receiveAll([1, 2]);
        inbox.beginAccept(1);
        Assert.isNull(inbox.beginAccept(2));
    }

    private function testNoDeclineWhileAccepting():Void
    {
        receiveAll([1, 2]);
        inbox.beginAccept(1);
        Assert.isNull(inbox.decline(2));
        Assert.same([], inbox.declineNotified());
        assertIncoming([1, 2], [1, 2]);
    }

    private function testNotificationLockedWhileAccepting():Void
    {
        receiveAll([1, 2]);
        inbox.beginAccept(1);
        inbox.selectNotified(2);
        inbox.hideAllNotified();
        Assert.equals(1, inbox.notification.active?.id);
        assertIncoming([1, 2], [1, 2]);
    }

    private function testAcceptFailedEndsAcceptance():Void
    {
        receiveAll([1]);
        inbox.beginAccept(1);
        inbox.acceptFailed(1);
        Assert.isFalse(inbox.accepting);
        assertIncoming([1], [1]);
    }

    private function testAcceptSucceededDropsTheChallengeAndClearsNotification():Void
    {
        receiveAll([1, 2, 3]);
        inbox.beginAccept(2);
        inbox.acceptSucceeded();
        Assert.isFalse(inbox.accepting);
        assertIncoming([1, 3], []);
    }

    private function testRemovingAcceptedChallengeKeepsAcceptanceUntilReported():Void
    {
        receiveAll([1, 2]);
        inbox.beginAccept(1);
        inbox.removeIncoming(1);
        Assert.isTrue(inbox.accepting);
        Assert.isNull(inbox.decline(2));
        inbox.acceptSucceeded();
        Assert.isFalse(inbox.accepting);
        assertIncoming([2], []);
    }

    private function testOutgoingSyncAndRemove():Void
    {
        inbox.syncOutgoing(Challenges.makeAllOutgoing([3, 1, 2]));
        Assert.same([1, 2, 3], Challenges.outgoingIds(inbox.outgoing));
        Assert.equals(2, inbox.removeOutgoing(2)?.id);
        Assert.isNull(inbox.removeOutgoing(2));
        Assert.same([1, 3], Challenges.outgoingIds(inbox.outgoing));
    }

    private function testOutgoingSyncReturnsDropped():Void
    {
        inbox.syncOutgoing(Challenges.makeAllOutgoing([1, 2, 3]));
        Assert.same([1, 3], Challenges.outgoingIds(inbox.syncOutgoing(Challenges.makeAllOutgoing([2, 4]))));
        Assert.same([2, 4], Challenges.outgoingIds(inbox.outgoing));
    }

    private function testAddOutgoingIgnoresPendingOnes():Void
    {
        inbox.addOutgoing(Challenges.makeOutgoing(3));
        inbox.addOutgoing(Challenges.makeOutgoing(1));
        inbox.addOutgoing(Challenges.makeOutgoing(3));
        Assert.same([1, 3], Challenges.outgoingIds(inbox.outgoing));
    }

    private function testHiddenAndUnnotifiedChallengesAreDismissed():Void
    {
        receiveAll([1, 2, 3]);
        receiveAll([4], false);
        inbox.hideNotified(2);
        Assert.same([2, 4], inbox.marks.dismissedIds);
    }

    private function testHideAllAndAcceptDismissTheNotified():Void
    {
        receiveAll([1, 2]);
        inbox.hideAllNotified();
        receiveAll([3, 4]);
        inbox.beginAccept(3);
        inbox.acceptSucceeded();
        Assert.same([1, 2, 4], inbox.marks.dismissedIds);
    }

    private function testDismissedChallengeIsNeverNotified():Void
    {
        inbox.applyMarks(new ChallengeMarks([2], 0));
        receiveAll([1, 2]);
        assertIncoming([1, 2], [1]);
    }

    private function testExternalDismissalTakesChallengeOffNotification():Void
    {
        receiveAll([1, 2, 3]);
        inbox.applyMarks(new ChallengeMarks([1, 3], 0));
        assertIncoming([1, 2, 3], [2]);
        Assert.same([1, 3], inbox.marks.dismissedIds);
    }

    private function testOnlyNewestDismissedIdsAreKept():Void
    {
        inbox.applyMarks(new ChallengeMarks([for (id in 1...106) id], 0));
        Assert.same([for (id in 6...106) id], inbox.marks.dismissedIds);
    }

    private function testUnseenIsAboveSeenId():Void
    {
        receiveAll([1, 2]);
        inbox.markSeen();
        Assert.equals(2, inbox.marks.seenUpToId);
        receiveAll([3]);
        Assert.isTrue(inbox.hasUnseenIncoming);
        inbox.removeIncoming(3);
        Assert.isFalse(inbox.hasUnseenIncoming);
    }

    private function testExternalSeenIdOnlyRaisesIt():Void
    {
        receiveAll([4, 5]);
        inbox.applyMarks(new ChallengeMarks([], 5));
        Assert.isFalse(inbox.hasUnseenIncoming);
        inbox.applyMarks(new ChallengeMarks([], 3));
        Assert.equals(5, inbox.marks.seenUpToId);
    }

    private function testResetForgetsEverything():Void
    {
        receiveAll([1, 2]);
        inbox.syncOutgoing(Challenges.makeAllOutgoing([5]));
        inbox.beginAccept(1);
        inbox.hideNotified(2);
        inbox.markSeen();
        inbox.reset();
        assertIncoming([], []);
        Assert.same([], inbox.outgoing);
        Assert.isFalse(inbox.accepting);
        Assert.same([], inbox.marks.dismissedIds);
        Assert.equals(0, inbox.marks.seenUpToId);
        receiveAll([1]);
        assertIncoming([1], [1]);
    }
}
