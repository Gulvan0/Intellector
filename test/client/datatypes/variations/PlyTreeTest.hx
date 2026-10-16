package client.datatypes.variations;

import intellectorboard.plyapplication.PlyPerformer;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import testutils.Plies;
import testutils.Variations;
import utest.Assert;
import utest.Test;

class PlyTreeTest extends Test
{
    private function testPlayingAddsChildrenInCreationOrder():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var first:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 0));
        var second:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 1));

        Assert.equals(2, tree.root.children.length);
        Assert.equals(first, tree.root.children[0]);
        Assert.equals(second, tree.root.children[1]);
        Assert.equals(1, first.depth);
        Assert.equals(tree.root, first.parent);
    }

    private function testPlayingAnExistingPlyReusesItsChild():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var ply:RawPly = Plies.legal(tree.root.position);
        var first:PlyTreeNode = tree.play(tree.root, ply);

        Assert.equals(first, tree.play(tree.root, ply.copy()));
        Assert.equals(1, tree.root.children.length);
    }

    private function testNodeHoldsPositionAfterItsPly():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var ply:RawPly = Plies.legal(tree.root.position);
        var node:PlyTreeNode = tree.play(tree.root, ply);

        Assert.equals(PlyPerformer.positionAfterRawPly(Position.defaultStarting(), ply).getHash(), node.position.getHash());
        Assert.equals(Black, node.position.turnColor);
        Assert.equals(White, node.moverColor());
        Assert.isNull(tree.root.moverColor());
    }

    private function testMoverColorFollowsTheStartingTurn():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting().copy(Black));
        var node:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position));

        Assert.equals(Black, node.moverColor());
    }

    private function testRemoveDropsTheSubtree():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var first:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 0));
        tree.play(first, Plies.legal(first.position));
        var second:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 1));

        tree.remove(first);

        Assert.equals(1, tree.root.children.length);
        Assert.equals(second, tree.root.children[0]);
        Assert.equals(1, tree.moveCount());
    }

    private function testRootCantBeRemoved():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        Assert.raises(() -> tree.remove(tree.root));
    }

    private function testCounts():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        Assert.equals(0, tree.moveCount());
        Assert.equals(0, tree.lineCount());

        var first:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 0));
        var reply:PlyTreeNode = tree.play(first, Plies.legal(first.position, 0));
        tree.play(first, Plies.legal(first.position, 1));
        tree.play(tree.root, Plies.legal(tree.root.position, 1));

        Assert.equals(4, tree.moveCount());
        Assert.equals(3, tree.lineCount());
        Assert.equals(3, first.subtreeSize());
        Assert.equals(1, reply.subtreeSize());
    }

    private function testLineContinuesByFirstChildren():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var first:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 0));
        var main:PlyTreeNode = tree.play(first, Plies.legal(first.position, 0));
        tree.play(first, Plies.legal(first.position, 1));
        var mainNext:PlyTreeNode = tree.play(main, Plies.legal(main.position, 0));
        var sideline:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 1));

        Assert.same(Variations.paths([tree.root, first]), Variations.paths(first.pathFromRoot()));
        Assert.same(Variations.paths([tree.root, first, main, mainNext]), Variations.paths(first.line()));
        Assert.same(Variations.paths([tree.root, first, main, mainNext]), Variations.paths(tree.root.line()));
        Assert.same(Variations.paths([tree.root, sideline]), Variations.paths(sideline.line()));
    }

    private function testContains():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var first:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 0));
        var reply:PlyTreeNode = tree.play(first, Plies.legal(first.position));
        var sideline:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 1));

        Assert.isTrue(first.contains(first));
        Assert.isTrue(first.contains(reply));
        Assert.isFalse(first.contains(sideline));
        Assert.isFalse(reply.contains(first));
    }
}
