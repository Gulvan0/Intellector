package client.logic.variations;

import client.datatypes.variations.PlyTreeNode;

typedef TreeCell =
{
    node:PlyTreeNode,
    row:Int,
    column:Int
}

/**
    The tree view's grid: a node's row is its depth; a first child keeps its parent's column, and
    every later sibling's subtree moves right until each of its cells is strictly right of all the
    cells already placed in its own row and the rows next to it, leaving a clear row between branches.
**/
class TreeGrid
{
    /** Every node of `root`'s subtree, in depth-first order **/
    public static function layout(root:PlyTreeNode):Array<TreeCell>
    {
        return place(root, 0);
    }

    private static function place(node:PlyTreeNode, row:Int):Array<TreeCell>
    {
        var cells:Array<TreeCell> = [{node: node, row: row, column: 0}];

        for (i in 0...node.children.length)
        {
            var subtree:Array<TreeCell> = place(node.children[i], row + 1);
            var shift:Int = i > 0 ? siblingShift(cells, subtree) : 0;
            for (cell in subtree)
                cells.push({node: cell.node, row: cell.row, column: cell.column + shift});
        }

        return cells;
    }

    private static function siblingShift(placed:Array<TreeCell>, subtree:Array<TreeCell>):Int
    {
        var rightmost:Map<Int, Int> = [];
        for (cell in placed)
            if (!rightmost.exists(cell.row) || rightmost.get(cell.row) < cell.column)
                rightmost.set(cell.row, cell.column);

        var shift:Int = 1;
        while (!fits(subtree, shift, rightmost))
            shift++;
        return shift;
    }

    private static function fits(subtree:Array<TreeCell>, shift:Int, rightmost:Map<Int, Int>):Bool
    {
        for (cell in subtree)
            for (row in cell.row - 1...cell.row + 2)
                if (rightmost.exists(row) && cell.column + shift <= rightmost.get(row))
                    return false;
        return true;
    }
}
