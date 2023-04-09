package net.shared.variation;

class DepthFirstIterator
{
    private var currentNode:VariationNode;
    private var startingLevel:Int;

    private function rightShifted(originNode:VariationNode):Null<VariationNode>
    {
        if (originNode.parent == null)
            return null;
        else if (originNode.path.length <= startingLevel)
            return null;
        else 
        {
            var sibling = originNode.rightSibling();

            if (sibling == null)
                return rightShifted(originNode.parent);
            else
                return sibling;
        }
    }

    public function new(startingNode:VariationNode, includeStarting:Bool) 
    {
        this.startingLevel = startingNode.path.length;

        if (includeStarting)
            this.currentNode = startingNode;
        else if (startingNode.hasChildren())
            this.currentNode = startingNode.getChild(0);
        else
            this.currentNode = null;
    }

    public function hasNext()
    {
        return currentNode != null;
    }

    public function next()
    {
        var returnedNode = currentNode;

        if (currentNode.hasChildren())
            currentNode = currentNode.getChild(0);
        else
            currentNode = rightShifted(currentNode);

        return returnedNode;
    }
}