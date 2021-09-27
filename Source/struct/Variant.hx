package struct;

import haxe.ui.util.Variant;
import struct.Ply;

class VariantNode
{
    public var ply:Ply;
    public var parent:Null<VariantNode>;
    public var children:Array<VariantNode>;

    public function addChild(ply:Ply) 
    {
        var child = new VariantNode(ply, this);
        children.push(child);
    }

    public function new(ply:Ply, parent:Null<VariantNode>) 
    {
        this.ply = ply;
        this.parent = parent;
        this.children = [];
    }
}

class Variant extends VariantNode 
{
    public static function parentPath(childPath:Array<Int>):Array<Int>
    {
        return childPath.slice(0, -1);
    }

    public static function belongs(nodePath:Array<Int>, branchPath:Array<Int>)
    {
        if (nodePath.length > branchPath.length)
            return false;

        for (i in 0...nodePath.length)
            if (nodePath[i] != branchPath[i])
                return false;
        return true;
    }

    public function addChildToNode(ply:Ply, parentPath:Array<Int>) 
    {
        getByPath(parentPath).addChild(ply);
    }

    public function extendPathLeftmost(path:Array<Int>):Array<Int>
    {
        var node:VariantNode = getByPath(path);
        while (!Lambda.empty(node.children))
        {
            node = node.children[0];
            path.push(0);
        }
        return path;
    }

    public function getRightSiblingsPaths(nodePath:Array<Int>, includeSpecifiedNode:Bool):Array<Array<Int>>
    {
        var parent_path:Array<Int> = parentPath(nodePath);
        var nodeNum:Int = nodePath[nodePath.length - 1];
        var parent:VariantNode = getByPath(parent_path);
        var startNum = includeSpecifiedNode? nodeNum : nodeNum+1;
        return [for (i in startNum...parent.children.length) parent_path.concat([i])];
    }

    public function getFamilyPaths(nodePath:Array<Int>):Array<Array<Int>>
    {
        return getFamilyPathsRecursive(getByPath(nodePath), nodePath);
    }

    public function upstreamParentsPaths(nodePath:Array<Int>, includeSpecifiedNode:Bool):Array<Array<Int>>
    {
        var paths:Array<Array<Int>> = includeSpecifiedNode? [nodePath] : [];
        var path = nodePath.copy();
        while (path.length > 1)
        {
            path.pop();
            paths.push(path);
        }
        return paths;
    }

    public function childCount(nodePath:Array<Int>)
    {
        return getByPath(nodePath).children.length;
    }

    private function getFamilyPathsRecursive(node:VariantNode, nodePath:Array<Int>):Array<Array<Int>>
    {
        var paths:Array<Array<Int>> = [nodePath];
        for (i in 0...node.children.length)
        {
            var child = node.children[i];
            paths = paths.concat(getFamilyPathsRecursive(child, nodePath.concat([i])));
        }
        return paths;
    }

    public function getBranchByPath(branchPath:Array<Int>):Array<Ply>
    {
        var branch:Array<Ply> = [];
        var node:VariantNode = this;
        for (childNum in branchPath)
        {
            node = node.children[childNum];
            branch.push(node.ply);
        }
        return branch;
    }

    public function removeDescendant(path:Array<Int>) 
    {
        var parent = getByPath(parentPath(path));
        var childNum = path[path.length - 1];
        parent.children.splice(childNum, 1);
    }

    private function getByPath(path:Array<Int>):VariantNode
    {
        var node:VariantNode = this;
        for (childNum in path)
            node = node.children[childNum];
        return node;
    }

    public function new() 
    {
        super(new Ply(), null);    
    }
}