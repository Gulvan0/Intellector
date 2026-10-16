package client.formatters;

import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import intellectorboard.mappers.notation.PlyFormatter;
import intellectorboard.position.Position;
import testutils.Plies;
import utest.Assert;
import utest.Test;

class VariationFormattersTest extends Test
{
    private function testNotation():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var node:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position));

        Assert.isNull(VariationFormatters.notation(tree.root));
        Assert.equals(PlyFormatter.toNotation(node.ply, tree.root.position), VariationFormatters.notation(node));
    }

    private function testLineNotationsSkipTheRoot():Void
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var first:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position));
        var second:PlyTreeNode = tree.play(first, Plies.legal(first.position));

        Assert.same([VariationFormatters.notation(first), VariationFormatters.notation(second)], VariationFormatters.lineNotations(tree.root.line()));
        Assert.same([], VariationFormatters.lineNotations([tree.root]));
    }
}
