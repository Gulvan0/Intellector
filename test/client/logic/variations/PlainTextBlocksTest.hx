package client.logic.variations;

import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.logic.variations.PlainTextBlocks.PlainTextBlock;
import intellectorboard.position.Position;
import testutils.Plies;
import testutils.Variations;
import utest.Assert;
import utest.Test;

class PlainTextBlocksTest extends Test
{
    private var tree:PlyTree;

    private function child(parent:PlyTreeNode):PlyTreeNode
    {
        return tree.play(parent, Plies.legal(parent.position, parent.children.length));
    }

    private function setup():Void
    {
        tree = new PlyTree(Position.defaultStarting());
    }

    private function testEmptyTreeIsTheRootAlone():Void
    {
        var blocks:Array<PlainTextBlock> = PlainTextBlocks.layout(tree.root);

        Assert.equals(1, blocks.length);
        Assert.same(Variations.paths([tree.root]), Variations.paths(blocks[0].nodes));
        Assert.equals(0, blocks[0].depth);
    }

    private function testALineIsOneBlock():Void
    {
        var first:PlyTreeNode = child(tree.root);
        var second:PlyTreeNode = child(first);
        var blocks:Array<PlainTextBlock> = PlainTextBlocks.layout(tree.root);

        Assert.equals(1, blocks.length);
        Assert.same(Variations.paths([tree.root, first, second]), Variations.paths(blocks[0].nodes));
    }

    private function testBranchesStartDeeperBlocks():Void
    {
        var main:PlyTreeNode = child(tree.root);
        var mainReply:PlyTreeNode = child(main);
        var sideline:PlyTreeNode = child(tree.root);
        var sidelineMain:PlyTreeNode = child(sideline);
        var sidelineAlternative:PlyTreeNode = child(sideline);
        var blocks:Array<PlainTextBlock> = PlainTextBlocks.layout(tree.root);

        Assert.same(
            [[tree.root], [main, mainReply], [sideline], [sidelineMain], [sidelineAlternative]].map(Variations.paths),
            blocks.map(block -> Variations.paths(block.nodes))
        );
        Assert.same([0, 1, 1, 2, 2], blocks.map(block -> block.depth));
        Assert.same([true, false, true, false, true], blocks.map(block -> block.isLastSibling));
        // the root's children draw no passing rails; the last sideline's own rail has ended
        Assert.same([[], [], [], [false], [false]], blocks.map(block -> block.railsPassing));
    }

    private function testRailOfAnUnfinishedLevelPassesDeeperBlocks():Void
    {
        var main:PlyTreeNode = child(tree.root);
        var branchPoint:PlyTreeNode = child(main);
        child(main);
        var deepMain:PlyTreeNode = child(branchPoint);
        child(branchPoint);
        var blocks:Array<PlainTextBlock> = PlainTextBlocks.layout(tree.root);

        var deepBlock:PlainTextBlock = blocks.filter(block -> block.nodes[0] == deepMain)[0];
        Assert.equals(2, deepBlock.depth);
        Assert.same([true], deepBlock.railsPassing);
    }
}
