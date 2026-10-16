package client.logic.variations;

import client.datatypes.variations.PlyTreeNode;

typedef PlainTextBlock =
{
    /** A run of nodes, each the only child of the one before **/
    nodes:Array<PlyTreeNode>,
    /** Indent level: 0 for the root's block, one more per branching **/
    depth:Int,
    /** Whether the block's first node is its parent's last child (its rail stops at its elbow) **/
    isLastSibling:Bool,
    /** `railsPassing[k]`: whether the rail of level `k + 1` runs past this block to a later sibling **/
    railsPassing:Array<Bool>
}

/**
    The plain view's blocks, in reading order: a block runs until the tree branches, and every
    branch starts a block one indent level deeper.
**/
class PlainTextBlocks
{
    public static function layout(root:PlyTreeNode):Array<PlainTextBlock>
    {
        var blocks:Array<PlainTextBlock> = [];
        collect(root, 0, true, [], blocks);
        return blocks;
    }

    private static function collect(first:PlyTreeNode, depth:Int, isLastSibling:Bool, railsPassing:Array<Bool>, blocks:Array<PlainTextBlock>):Void
    {
        var nodes:Array<PlyTreeNode> = [first];
        var last:PlyTreeNode = first;
        while (last.children.length == 1)
        {
            last = last.children[0];
            nodes.push(last);
        }

        blocks.push({nodes: nodes, depth: depth, isLastSibling: isLastSibling, railsPassing: railsPassing});

        var childRails:Array<Bool> = depth >= 1 ? railsPassing.concat([!isLastSibling]) : [];
        for (i in 0...last.children.length)
            collect(last.children[i], depth + 1, i == last.children.length - 1, childRails, blocks);
    }
}
