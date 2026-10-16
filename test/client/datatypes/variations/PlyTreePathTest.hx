package client.datatypes.variations;

import intellectorboard.position.Position;
import testutils.Plies;
import utest.Assert;
import utest.Test;

class PlyTreePathTest extends Test
{
    // the same as the server's conversion of old per-ply paths (`migration/study.py`)
    private function testStudyEncoding():Void
    {
        Assert.equals("", new PlyTreePath([0]).toStudyString());
        Assert.equals("2", new PlyTreePath([2]).toStudyString());
        Assert.equals("x2:1:", new PlyTreePath([0, 0, 1, 0]).toStudyString());
        Assert.equals("1x3", new PlyTreePath([1, 1, 1]).toStudyString());
        Assert.equals(":3x2:x2", new PlyTreePath([0, 3, 3, 0, 0]).toStudyString());
        Assert.equals("12:1", new PlyTreePath([12, 1]).toStudyString());
    }

    private function testStudyDecoding():Void
    {
        Assert.same([0], PlyTreePath.fromStudyString("").childIndices());
        Assert.same([0, 0, 1, 0], PlyTreePath.fromStudyString("x2:1:").childIndices());
        Assert.same([1, 1, 1], PlyTreePath.fromStudyString("1x3").childIndices());
        Assert.same([0, 3, 3, 0, 0], PlyTreePath.fromStudyString(":3x2:x2").childIndices());
        Assert.same([12, 1], PlyTreePath.fromStudyString("12:1").childIndices());
    }

    private function testRoundTrip():Void
    {
        for (indices in [[0], [1], [0, 0, 0, 0], [2, 0, 2, 2, 1, 0, 0], [0, 10, 10, 0]])
            Assert.same(indices, PlyTreePath.fromStudyString(new PlyTreePath(indices).toStudyString()).childIndices());
    }

    private function testOfAndFind():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var first:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 0));
        var second:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 1));
        var reply:PlyTreeNode = tree.play(second, Plies.legal(second.position));

        Assert.same([], PlyTreePath.of(tree.root).childIndices());
        Assert.same([0], PlyTreePath.of(first).childIndices());
        Assert.same([1, 0], PlyTreePath.of(reply).childIndices());

        Assert.equals(reply, new PlyTreePath([1, 0]).find(tree));
        Assert.equals(tree.root, new PlyTreePath([]).find(tree));
        Assert.isNull(new PlyTreePath([2]).find(tree));
        Assert.isNull(new PlyTreePath([0, 0]).find(tree));
    }

    private function testParent():Void
    {
        Assert.same([1], new PlyTreePath([1, 0]).parent().childIndices());
        Assert.same([], new PlyTreePath([1]).parent().childIndices());
    }

    private function testCompareOrdersParentsFirstThenByIndex():Void
    {
        var paths:Array<PlyTreePath> = [new PlyTreePath([1]), new PlyTreePath([0, 1]), new PlyTreePath([0]), new PlyTreePath([0, 0])];
        paths.sort(PlyTreePath.compare);

        Assert.same([[0], [0, 0], [0, 1], [1]], paths.map(path -> path.childIndices()));
    }
}
