package client.ui.common.notifications.challenges;

import testutils.Challenges;
import utest.Assert;
import utest.Test;

class ChallengeStackLayoutTest extends Test
{
    private function assertLayout(waitingIds:Array<Int>, collapsed:Bool, rowIds:Array<Int>, rowHiddenCount:Int, barHiddenCount:Int, ?pos:haxe.PosInfos):Void
    {
        var layout:ChallengeStackLayout = new ChallengeStackLayout(Challenges.makeAll(waitingIds), collapsed);
        Assert.same(rowIds, Challenges.ids(layout.rows), pos);
        Assert.equals(rowHiddenCount, layout.rowHiddenCount, pos);
        Assert.equals(barHiddenCount, layout.barHiddenCount, pos);
    }

    private function testNothingWaiting():Void
    {
        assertLayout([], false, [], 0, 0);
        assertLayout([], true, [], 0, 0);
    }

    private function testExpandedFitsEveryRow():Void
    {
        assertLayout([1, 2, 3], false, [1, 2, 3], 0, 0);
    }

    private function testExpandedOverflowCountedOnBar():Void
    {
        assertLayout([1, 2, 3, 4, 5], false, [3, 4, 5], 0, 2);
    }

    private function testCollapsedFitsOneRow():Void
    {
        assertLayout([1], true, [1], 0, 0);
    }

    private function testCollapsedOverflowCountedOnRow():Void
    {
        assertLayout([1, 2, 3], true, [3], 2, 0);
    }
}
