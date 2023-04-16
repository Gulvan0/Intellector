package gfx.live.interfaces;

import net.shared.variation.DepthFirstIterator;
import net.shared.variation.VariationMap;
import net.shared.variation.VariationPath;
import net.shared.variation.Variation;

abstract ReadOnlyVariation(Variation)
{
    public function collectNodes(includeRoot:Bool):VariationMap<ReadOnlyVariationNode>
    {
        return this.collectNodes(includeRoot);
    }

    public function collectNodesAlongsidePath(path:VariationPath, includeStartingNode:Bool, ?startingNodePath:VariationPath):Array<ReadOnlyVariationNode>
    {
        return this.collectNodesAlongsidePath(path, includeStartingNode, startingNodePath);
    }

    public function getFullMainline(includeRoot:Bool, ?parentPath:VariationPath):Array<ReadOnlyVariationNode>
    {
        return this.getFullMainline(includeRoot, parentPath);
    }
    
    public function getMainlineDescendants(includeParent:Bool, ?parentPath:VariationPath):Array<ReadOnlyVariationNode>
    {
        return this.getMainlineDescendants(includeParent, parentPath);
    }
        
    public function getFullMainlinePath(?parentPath:VariationPath):VariationPath
    {
        return this.getFullMainlinePath(parentPath);
    }
    
    public function rootNode():ReadOnlyVariationNode
    {
        return this.rootNode();
    }
    
    public function getNode(path:VariationPath):Null<ReadOnlyVariationNode>
    {
        return this.getNode(path);
    }

    public function depthFirst(includeStarting:Bool, ?startingPath:VariationPath):DepthFirstIterator<ReadOnlyVariationNode>
    {
        return this.readOnlyDepthFirst(includeStarting, startingPath);
    }

    public function serialize():String
    {
        return this.serialize();
    }
}