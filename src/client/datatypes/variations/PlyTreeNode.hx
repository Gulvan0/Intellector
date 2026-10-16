package client.datatypes.variations;

import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;

/** A position in a `PlyTree`, reached from its parent by `ply` **/
class PlyTreeNode
{
    /** Null at the root **/
    public final ply:Null<RawPly>;
    public final parent:Null<PlyTreeNode>;
    /** In creation order; the first is the main continuation **/
    public final children:Array<PlyTreeNode> = [];
    /** The position after `ply` **/
    public final position:Position;
    /** How many plies away from the root **/
    public final depth:Int;

    @:allow(client.datatypes.variations.PlyTree)
    private function new(ply:Null<RawPly>, parent:Null<PlyTreeNode>, position:Position)
    {
        this.ply = ply;
        this.parent = parent;
        this.position = position;
        this.depth = parent != null ? parent.depth + 1 : 0;
    }

    public function isRoot():Bool
    {
        return parent == null;
    }

    /** Who played `ply`; null at the root **/
    public function moverColor():Null<PieceColor>
    {
        return parent != null ? parent.position.turnColor : null;
    }

    /** The child reached by `ply`, if there is one **/
    public function findChild(ply:RawPly):Null<PlyTreeNode>
    {
        for (child in children)
            if (child.ply.equals(ply))
                return child;
        return null;
    }

    /** This node and all its descendants **/
    public function subtreeSize():Int
    {
        var size:Int = 1;
        for (child in children)
            size += child.subtreeSize();
        return size;
    }

    /** The root, then every node down to this one **/
    public function pathFromRoot():Array<PlyTreeNode>
    {
        var nodes:Array<PlyTreeNode> = [];
        var node:Null<PlyTreeNode> = this;
        while (node != null)
        {
            nodes.unshift(node);
            node = node.parent;
        }
        return nodes;
    }

    /** `pathFromRoot`, continued by first children down to a leaf; `line()[k]` is at depth `k` **/
    public function line():Array<PlyTreeNode>
    {
        var nodes:Array<PlyTreeNode> = pathFromRoot();
        var node:PlyTreeNode = this;
        while (node.children.length > 0)
        {
            node = node.children[0];
            nodes.push(node);
        }
        return nodes;
    }

    /** Whether `node` is this one or among its descendants **/
    public function contains(node:PlyTreeNode):Bool
    {
        var current:Null<PlyTreeNode> = node;
        while (current != null)
        {
            if (current == this)
                return true;
            current = current.parent;
        }
        return false;
    }
}
