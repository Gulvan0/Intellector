package client.datatypes.variations;

import client.datatypes.game.PlyNavigationType;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;
import morestd.Signal;

/**
    A ply tree with one selected node. Navigation follows the selected line: the path to the
    selection, continued by first children down to a leaf.
**/
class PlyTreeCursor
{
    public final onChanged:Signal<PlyTreeChange> = new Signal();

    public var tree(default, null):PlyTree;
    public var selected(default, null):PlyTreeNode;

    public function new(startingPosition:Position)
    {
        tree = new PlyTree(startingPosition);
        selected = tree.root;
    }

    public function select(node:PlyTreeNode):Void
    {
        if (node == selected)
            return;

        selected = node;
        onChanged.dispatch(Selection);
    }

    /** Selects the selection's child reached by `ply`, adding it as a new variation if it's new **/
    public function play(ply:RawPly):Void
    {
        var childCount:Int = selected.children.length;
        selected = tree.play(selected, ply);
        onChanged.dispatch(selected.parent.children.length != childCount ? Structure : Selection);
    }

    public function navigate(type:PlyNavigationType):Void
    {
        var line:Array<PlyTreeNode> = selectedLine();
        var target:Int = switch type {
            case Start: 0;
            case Previous: selected.depth - 1;
            case Next: selected.depth + 1;
            case End: line.length - 1;
            case AfterPly(index): index + 1;
        }
        select(line[Std.int(Math.max(0, Math.min(line.length - 1, target)))]);
    }

    public function selectedLine():Array<PlyTreeNode>
    {
        return selected.line();
    }

    /** Removes the selection with its descendants and selects its parent; never the root **/
    public function deleteSelected():Void
    {
        if (selected.isRoot())
            return;

        var parent:PlyTreeNode = selected.parent;
        tree.remove(selected);
        selected = parent;
        onChanged.dispatch(Structure);
    }

    /** Starts over from `startingPosition`, with no plies **/
    public function reset(startingPosition:Position):Void
    {
        load(new PlyTree(startingPosition));
    }

    /** Replaces the tree with `tree`, selecting its root **/
    public function load(tree:PlyTree):Void
    {
        this.tree = tree;
        selected = tree.root;
        onChanged.dispatch(Structure);
    }
}
