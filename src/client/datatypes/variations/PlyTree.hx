package client.datatypes.variations;

import intellectorboard.plyapplication.PlyPerformer;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;

/** The plies explored from a starting position, branching into variations **/
class PlyTree
{
    public final root:PlyTreeNode;

    public function new(startingPosition:Position)
    {
        root = new PlyTreeNode(null, null, startingPosition);
    }

    /** The child of `parent` reached by `ply`: an existing one, or else a new last child **/
    public function play(parent:PlyTreeNode, ply:RawPly):PlyTreeNode
    {
        var existing:Null<PlyTreeNode> = parent.findChild(ply);
        if (existing != null)
            return existing;

        var child:PlyTreeNode = new PlyTreeNode(ply.copy(), parent, PlyPerformer.positionAfterRawPly(parent.position, ply));
        parent.children.push(child);
        return child;
    }

    /** Removes `node` with its descendants; the root can't be removed **/
    public function remove(node:PlyTreeNode):Void
    {
        if (node.isRoot())
            throw "The root of a ply tree can't be removed";
        node.parent.children.remove(node);
    }

    /** Every ply in the tree **/
    public function moveCount():Int
    {
        return root.subtreeSize() - 1;
    }

    /** The leaves, the root excepted **/
    public function lineCount():Int
    {
        return root.children.length > 0 ? countLeaves(root) : 0;
    }

    private static function countLeaves(node:PlyTreeNode):Int
    {
        if (node.children.length == 0)
            return 1;

        var count:Int = 0;
        for (child in node.children)
            count += countLeaves(child);
        return count;
    }
}
