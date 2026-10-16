package client.logic.variations;

import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.logic.variations.TreeGrid.TreeCell;
import intellectorboard.position.Position;
import testutils.Plies;
import testutils.Variations;
import utest.Assert;
import utest.Test;

class TreeGridTest extends Test
{
    private var tree:PlyTree;

    private function child(parent:PlyTreeNode):PlyTreeNode
    {
        return tree.play(parent, Plies.legal(parent.position, parent.children.length));
    }

    private function cellOf(cells:Array<TreeCell>, node:PlyTreeNode):TreeCell
    {
        for (cell in cells)
            if (cell.node == node)
                return cell;
        return null;
    }

    private function assertCell(cells:Array<TreeCell>, node:PlyTreeNode, row:Int, column:Int, ?pos:haxe.PosInfos):Void
    {
        var cell:TreeCell = cellOf(cells, node);
        Assert.notNull(cell, pos);
        Assert.equals(row, cell.row, pos);
        Assert.equals(column, cell.column, pos);
    }

    private function setup():Void
    {
        tree = new PlyTree(Position.defaultStarting());
    }

    private function testSingleLineIsOneColumn():Void
    {
        var first:PlyTreeNode = child(tree.root);
        var second:PlyTreeNode = child(first);
        var cells:Array<TreeCell> = TreeGrid.layout(tree.root);

        Assert.equals(3, cells.length);
        assertCell(cells, tree.root, 0, 0);
        assertCell(cells, first, 1, 0);
        assertCell(cells, second, 2, 0);
    }

    private function testSecondSiblingMovesOneColumnRight():Void
    {
        var main:PlyTreeNode = child(tree.root);
        child(main);
        var sideline:PlyTreeNode = child(tree.root);
        var sidelineReply:PlyTreeNode = child(sideline);
        var cells:Array<TreeCell> = TreeGrid.layout(tree.root);

        assertCell(cells, sideline, 1, 1);
        assertCell(cells, sidelineReply, 2, 1);
    }

    private function testSiblingClearsTheRowsNextToItsCells():Void
    {
        var main:PlyTreeNode = child(tree.root);
        var mainReply:PlyTreeNode = child(main);
        child(mainReply);
        var innerSideline:PlyTreeNode = child(main);
        var outerSideline:PlyTreeNode = child(tree.root);
        var cells:Array<TreeCell> = TreeGrid.layout(tree.root);

        assertCell(cells, innerSideline, 2, 1);
        // row 1 is free past column 0, but the inner sideline sits in row 2 at column 1
        assertCell(cells, outerSideline, 1, 2);
    }

    private function testDistantSiblingRowsDontPush():Void
    {
        var main:PlyTreeNode = child(tree.root);
        var mainReply:PlyTreeNode = child(main);
        var mainThird:PlyTreeNode = child(mainReply);
        child(mainThird);
        var deepSideline:PlyTreeNode = child(mainThird);
        var outerSideline:PlyTreeNode = child(tree.root);
        var cells:Array<TreeCell> = TreeGrid.layout(tree.root);

        // the deep sideline's column 1 is in row 4, more than a row below the outer sideline's row 1
        assertCell(cells, deepSideline, 4, 1);
        assertCell(cells, outerSideline, 1, 1);
    }

    private function testCellsAreDepthFirst():Void
    {
        var main:PlyTreeNode = child(tree.root);
        var mainReply:PlyTreeNode = child(main);
        var sideline:PlyTreeNode = child(tree.root);
        var cells:Array<TreeCell> = TreeGrid.layout(tree.root);

        Assert.same(Variations.paths([tree.root, main, mainReply, sideline]), Variations.paths(cells.map(cell -> cell.node)));
    }
}
