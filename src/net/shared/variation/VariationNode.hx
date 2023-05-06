package net.shared.variation;

import net.shared.board.RawPly;
import net.shared.board.Situation;

class VariationNode
{
    public var path(default, null):VariationPath;
    public var childNum(default, null):Int;

    public final situation:Situation;
    public final incomingPly:Null<RawPly>;

    public final parent:Null<VariationNode>;
    private final children:Array<VariationNode>;

    public function addChild(ply:RawPly) 
    {
        var childPath:VariationPath = path.childPath(childCount());
        var situationAfter:Situation = situation.situationAfterRawPly(ply);
        var child:VariationNode = new VariationNode(childPath, ply, situationAfter, this);
        children.push(child);
    }

    public function getIncomingPlyStr(?indicateColor:Bool = false):String
    {
        if (incomingPly != null && parent != null)
            return incomingPly.toNotation(parent.situation, indicateColor);
        else 
            return "start";
    }

    public function collectDescendants(?includeSelf:Bool = true):VariationMap<VariationNode>
    {
        var map:VariationMap<VariationNode> = new VariationMap<VariationNode>();

        if (includeSelf)
            map.set(path, this);

        for (childNum => childNode in children.keyValueIterator())
            map.update(childNode.collectDescendants(true));

        return map;
    }

    public function hasChildren():Bool
    {
        return !Lambda.empty(children);
    }

    public function getChild(childNum:Int):VariationNode
    {
        return children[childNum];
    }

    public function childCount():Int
    {
        return children.length;
    }

    public function hasChild(childNum:Int):Bool
    {
        return childNum < childCount();
    }

    public function leftSibling():Null<VariationNode>
    {
        if (parent != null && childNum > 0)
            return parent.getChild(childNum - 1);
        else
            return null;
    }

    public function rightSibling():Null<VariationNode>
    {
        if (parent != null && parent.hasChild(childNum + 1))
            return parent.getChild(childNum + 1);
        else
            return null;
    }

    public function spliceChildrenAt(droppedChildNum:Int)
    {
        children.splice(droppedChildNum, 1);
    }

    public function collectRightSiblings(includeSelf:Bool):Array<VariationNode>
    {
        var nodes = includeSelf? [this] : [];
        var node = rightSibling();

        while (node != null)
        {
            nodes.push(node);
            node = rightSibling();
        }

        return nodes;
    }

    public function getLastChild():Null<VariationNode>
    {
        if (hasChildren())
            return children[children.length - 1];
        else
            return null;
    }

    public function shiftPathIndexLeft(level:Int) 
    {
        var modifiedPath:Array<Int> = path.asArray();
        modifiedPath[level]--;
        path = modifiedPath;

        if (level == modifiedPath.length - 1)
            childNum--;
    }

    public function new(path:VariationPath, incomingPly:RawPly, situation:Situation, parent:Null<VariationNode>) 
    {
        this.path = path;
        this.childNum = path.last();
        this.incomingPly = incomingPly;
        this.situation = situation;
        this.parent = parent;
        this.children = [];
    }
}