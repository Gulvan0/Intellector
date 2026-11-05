package client.ui.common.notifications.challenges;

import client.ui.common.notifications.challenges.ChallengeStackLayout.ChallengeStackRowPolicy;
import testutils.Challenges;
import utest.Assert;
import utest.Test;

class ChallengeStackLayoutTest extends Test
{
    private function assertLayout(waitingIds:Array<Int>, policy:ChallengeStackRowPolicy, rowIds:Array<Int>, rowHiddenCount:Int, barHiddenCount:Int, ?pos:haxe.PosInfos):Void
    {
        var layout:ChallengeStackLayout = new ChallengeStackLayout(Challenges.makeAll(waitingIds), policy);
        Assert.same(rowIds, Challenges.ids(layout.rows), pos);
        Assert.equals(rowHiddenCount, layout.rowHiddenCount, pos);
        Assert.equals(barHiddenCount, layout.barHiddenCount, pos);
    }

    private function testNothingWaiting():Void
    {
        assertLayout([], ChallengeStackLayout.EXPANDED_POLICY, [], 0, 0);
        assertLayout([], ChallengeStackLayout.COLLAPSED_POLICY, [], 0, 0);
    }

    private function testExpandedFitsEveryRow():Void
    {
        assertLayout([1, 2, 3], ChallengeStackLayout.EXPANDED_POLICY, [1, 2, 3], 0, 0);
    }

    private function testExpandedOverflowCountedOnBar():Void
    {
        assertLayout([1, 2, 3, 4, 5], ChallengeStackLayout.EXPANDED_POLICY, [3, 4, 5], 0, 2);
    }

    private function testCollapsedFitsOneRow():Void
    {
        assertLayout([1], ChallengeStackLayout.COLLAPSED_POLICY, [1], 0, 0);
    }

    private function testCollapsedOverflowCountedOnRow():Void
    {
        assertLayout([1, 2, 3], ChallengeStackLayout.COLLAPSED_POLICY, [3], 2, 0);
    }
}
