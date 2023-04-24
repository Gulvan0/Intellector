package gfx.live.interfaces;

import net.shared.variation.VariationPath;
import net.shared.board.Situation;
import net.shared.board.RawPly;
import net.shared.variation.VariationNode;

abstract ReadOnlyVariationNode(VariationNode) from VariationNode
{
    public function getIncomingPlyStr(?indicateColor:Bool = false):String
    {
        return this.getIncomingPlyStr(indicateColor);
    }

    public function collectDescendants(?includeSelf:Bool = true):VariationMap<ReadOnlyVariationNode>
    {
        return this.collectDescendants(includeSelf);
    }

    public function hasChildren():Bool
    {
        return this.hasChildren();
    }

    public function getChild(childNum:Int):ReadOnlyVariationNode
    {
        return this.getChild(childNum);
    }

    public function childCount():Int
    {
        return this.childCount();
    }

    public function hasChild(childNum:Int):Bool
    {
        return this.hasChild(childNum);
    }

    public function leftSibling():Null<ReadOnlyVariationNode>
    {
        return this.leftSibling();
    }

    public function rightSibling():Null<ReadOnlyVariationNode>
    {
        return this.rightSibling();
    }
    
    public function collectRightSiblings(includeSelf:Bool):Array<ReadOnlyVariationNode>
    {
        return this.collectRightSiblings(includeSelf);
    }
    
    public function getLastChild():Null<ReadOnlyVariationNode>
    {
        return this.getLastChild();
    }

    public function getPath():VariationPath
    {
        return this.path;
    }

    public function getChildNum():Int
    {
        return this.childNum;
    }

    public function getSituation():Situation
    {
        return this.situation.copy();
    }

    public function getIncomingPly():Null<RawPly>
    {
        return this.incomingPly == null? null : this.incomingPly.copy();
    }

    public function getParent():ReadOnlyVariationNode
    {
        return this.parent;
    }
}