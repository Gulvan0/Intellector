package net.shared.variation;

import gfx.live.interfaces.ReadOnlyVariationNode;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import haxe.Unserializer;
import haxe.Serializer;

typedef SerializableVariation = {startingSIP:String, orderedPlys:Array<{serializedParentPath:String, serializedPly:String}>};

abstract Variation(VariationNode)
{
    public function collectNodes(includeRoot:Bool):VariationMap<VariationNode>
    {
        return this.collectDescendants([], includeRoot);
    }
    
    public function collectNodesAlongsidePath(path:VariationPath, includeStartingNode:Bool, ?startingNodePath:VariationPath):Array<VariationNode>
    {
        var nodes:Array<VariationNode> = [];

        var node:VariationNode = startingNodePath != null? getNode(startingNodePath) : rootNode();

        if (includeStartingNode)
            nodes.push(node);
        
        for (childNum in path)
        {
            node = node.getChild(childNum);
            nodes.push(node);
        }

        return nodes;
    }

    public function getFullMainline(includeRoot:Bool, ?parentPath:VariationPath):Array<VariationNode>
    {
        if (parentPath == null)
            return getMainlineDescendants(includeRoot);

        return collectNodesAlongsidePath(parentPath, includeRoot).concat(getMainlineDescendants(false, parentPath));
    }

    public function getMainlineDescendants(includeParent:Bool, ?parentPath:VariationPath):Array<VariationNode>
    {
        if (parentPath == null)
            parentPath = VariationPath.root();

        var node:VariationNode = getNode(parentPath);

        var desc:Array<VariationNode> = includeParent? [node] : [];

        while (node.hasChildren())
        {
            node = node.getChild(0);
            desc.push(node);
        }
        
        return desc;
    }

    public function getFullMainlinePath(?parentPath:VariationPath):VariationPath
    {
        var path:VariationPath = parentPath ?? VariationPath.root();
        var node:VariationNode = getNode(path);

        while (node.hasChildren())
        {
            path = path.childPath(0);
            node = node.getChild(0);
        }

        return path;
    }

    public function rootNode():VariationNode
    {
        return this;
    }

    public function getNode(path:VariationPath):Null<VariationNode>
    {
        var node:VariationNode = rootNode();

        for (childNum in path)
            if (node.hasChild(childNum))
                node = node.getChild(childNum);
            else
                return null;

        return node;
    }

    public function addChild(path:VariationPath, ply:RawPly)
    {
        getNode(path).addChild(ply);
    }

    public function removeNode(path:VariationPath):NodeRemovalOutput
    {
        var output:NodeRemovalOutput = new NodeRemovalOutput();

        for (removedNode in depthFirst(true, path))
            output.pathsRemoved.push(removedNode.path);

        var mainRemovedNode:VariationNode = getNode(path);
        var removalLevel:Int = path.length;

        for (rightSibling in mainRemovedNode.collectRightSiblings(false))
            for (shiftedNode in depthFirst(true, rightSibling.path))
            {
                var oldPath:VariationPath = shiftedNode.path;
                shiftedNode.shiftPathIndexLeft(removalLevel);
                var newPath:VariationPath = shiftedNode.path;
                output.pathUpdates.push({oldPath: oldPath, newPath: newPath});
            }

        mainRemovedNode.parent.spliceChildrenAt(mainRemovedNode.childNum);

        return output;
    }

    public function clear(?newStartingSituation:Situation)
    {
        if (newStartingSituation == null)
            newStartingSituation = startingSituation;

        this = new VariationNode([], null, newStartingSituation, null);
    }

    public function depthFirst(includeStarting:Bool, ?startingPath:VariationPath):DepthFirstIterator<VariationNode>
    {
        if (startingPath == null)
            startingPath = VariationPath.root();

        return new DepthFirstIterator<VariationNode>(getNode(startingPath), includeStarting);    
    }

    public function readOnlyDepthFirst(includeStarting:Bool, ?startingPath:VariationPath):DepthFirstIterator<ReadOnlyVariationNode>
    {
        if (startingPath == null)
            startingPath = VariationPath.root();

        return new DepthFirstIterator<ReadOnlyVariationNode>(getNode(startingPath), includeStarting);    
    }

    public function serialize():String
    {
        var orderedPlys:Array<{serializedParentPath:String, serializedPly:String}> = [for (node in depthFirst(false)) {serializedParentPath: node.path.parentPath().serialize(), serializedPly: node.incomingPly.serialize()}];
        var serializableVariation:SerializableVariation = {startingSIP: this.situation.serialize(), orderedPlys: orderedPlys};

        return Serializer.run(serializableVariation);
    }

    public static function deserialize(str:String):Variation
    {
        var serializableVariation:SerializableVariation = Unserializer.run(str);
        var variation:Variation = new Variation(serializableVariation.startingSIP);

        for (nodeData in serializableVariation.orderedPlys)
            variation.addChild(VariationPath.deserialize(nodeData.serializedParentPath), RawPly.deserialize(nodeData.serializedPly));
        
        return variation;
    }

    public function new(startingSituation:Situation) 
    {
        this = new VariationNode([], null, startingSituation, null);
    }
}