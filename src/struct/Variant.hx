package struct;

import net.shared.converters.PlySerializer;
import net.shared.board.RawPly;
import net.shared.converters.SituationSerializer;
import net.shared.board.Situation;

abstract VariantPath(Array<Int>) from Array<Int> to Array<Int>
{
    public var length(get, never):Int;

    public function get_length():Int
    {
        return this.length;
    }

    public function asArray():Array<Int>
    {
        return this;
    }

    public function isRoot():Bool
    {
        return Lambda.empty(this);
    }

    public function isMainLine():Bool
    {
        for (childNum in this)
            if (childNum != 0)
                return false;
        return true;
    }

    public function subpath(subLength:Int):VariantPath
    {
        return this.slice(0, subLength);
    }

    public function lastNodeNum():Int
    {
        return this[this.length - 1];
    }

    public static function fromCode(code:String):VariantPath
    {
        return code == ''? [] : code.split(":").map(Std.parseInt);
    }

    public function code():String
    {
        return this.join(":");
    }

    public function copy():VariantPath
    {
        return this.copy();
    }

    public function parent():Null<VariantPath>
    {
        return Lambda.empty(this)? null : this.slice(0, -1);
    }

    public function child(num:Int):VariantPath
    {
        return this.concat([num]);
    }

    public function upstreamParents(includeThis:Bool):Array<VariantPath>
    {
        var paths:Array<VariantPath> = includeThis? [this] : [];
        var path:Array<Int> = copy();
        for (i in 0...this.length)
        {
            path.pop();
            paths.push(path);
        }
        return paths;
    }

    public function contains(p:VariantPath):Bool
    {
        if (p.length > this.length)
            return false;

        for (i in 0...p.length)
            if (p[i] != this[i])
                return false;
        return true;
    }

    public function equals(p:VariantPath):Bool
    {
        return p.length == this.length && p.contains(this);
    }

    public static function mainLine(length:Int):VariantPath
    {
        return [for (i in 0...length) 0];
    }

    public inline function new(a:Array<Int>) 
    {
        this = a;
    }
}

class VariantNode
{
    public var ply:RawPly;
    public var situationBefore:Situation;
    public var situationAfter:Situation;
    public var children:Array<VariantNode>;

    public function addChild(ply:RawPly) 
    {
        var child = new VariantNode(ply, situationAfter);
        children.push(child);
    }

    public function getPlyStr(?indicateColor:Bool = false):String
    {
        return ply.toNotation(situationBefore, indicateColor);
    }

    public function new(ply:RawPly, situationBefore:Situation) 
    {
        this.ply = ply;
        this.situationBefore = situationBefore;
        this.situationAfter = ply != null? situationBefore.situationAfterRawPly(ply) : situationBefore;
        this.children = [];
    }
}

class Variant extends VariantNode 
{
    public var startingSituation(default, null):Situation;

    public function getAllNodes():Map<String, VariantNode>
    {
        var m:Map<String, VariantNode> = [];
        for (path in getFamilyPaths([]))
            m.set(path.code(), getByPath(path));
        return m;
    }

    public function serialize():String 
    {
        var serialized:String = "";

        for (code => node in getAllNodes())
            if (code != '')
                serialized += code + "/" + PlySerializer.serialize(node.ply) + ";";

        serialized += startingSituation.serialize();
                
        return serialized;
    }

    //! Assumes the valid argument
    public static function deserialize(s:String):Variant
    {
        var variantStrParts:Array<String> = s.split(";");
        var startingSituationSIP:String = variantStrParts.pop();
        var startingSituation:Situation = SituationSerializer.deserialize(startingSituationSIP);
        var nodesByPathLength:Map<Int, Array<{parentPath:VariantPath, nodeNum:Int, ply:RawPly}>> = [];
        var maxPathLength:Int = 0;

        for (nodeStr in variantStrParts)
        {
            var nodeStrParts = nodeStr.split("/");
            var code = nodeStrParts[0];
            var path = VariantPath.fromCode(code);
            var ply = PlySerializer.deserialize(nodeStrParts[1]);
            var nodeInfo = {parentPath: path.parent(), nodeNum: path.lastNodeNum(), ply: ply};
            var pathLength:Int = path.length;

            if (maxPathLength < pathLength)
                maxPathLength = pathLength;
    
            if (nodesByPathLength.exists(pathLength))
                nodesByPathLength[pathLength].push(nodeInfo);
            else
                nodesByPathLength.set(pathLength, [nodeInfo]);
        }

        for (nodesOnSameLevelArray in nodesByPathLength)
            nodesOnSameLevelArray.sort((ni1, ni2) -> ni1.nodeNum - ni2.nodeNum);

        var variant:Variant = new Variant(startingSituation);
        for (pathLength in 1...maxPathLength+1)
            for (nodeInfo in nodesByPathLength[pathLength])
                variant.addChildToNode(nodeInfo.ply, nodeInfo.parentPath);
        
        return variant;
    }

    public function addChildToNode(ply:RawPly, parentPath:VariantPath) 
    {
        getByPath(parentPath).addChild(ply);
    }

    public function extendPathLeftmost(path:VariantPath):VariantPath
    {
        var extendedPath = path.copy();
        var node:VariantNode = getByPath(extendedPath);
        
        while (!Lambda.empty(node.children))
        {
            node = node.children[0];
            extendedPath = extendedPath.child(0);
        }
        return extendedPath;
    }

    public function getRightSiblingsPaths(nodePath:VariantPath, includeSpecifiedNode:Bool):Array<VariantPath>
    {
        var parent_path:VariantPath = nodePath.parent();
        var nodeNum:Int = nodePath[nodePath.length - 1];
        var parent:VariantNode = getByPath(parent_path);
        var startNum = includeSpecifiedNode? nodeNum : nodeNum+1;
        return [for (i in startNum...parent.children.length) parent_path.child(i)];
    }

    public function getLastMainLineDescendantPath(nodePath:VariantPath):VariantPath
    {
        var currentPath:VariantPath = nodePath.copy();
        while (pathExists(currentPath.child(0)))
            currentPath = currentPath.child(0);
        return currentPath;
    }

    public function getRightmostSiblingPath(nodePath:VariantPath):VariantPath
    {
        if (Lambda.empty(nodePath))
            throw "Root cannot be passed as an argument";
        return getRightmostChildPath(nodePath.parent());
    }

    public function getRightmostChildPath(nodePath:VariantPath):VariantPath
    {
        return nodePath.child(childCount(nodePath) - 1);
    }

    public function getFamilyPaths(nodePath:VariantPath):Array<VariantPath>
    {
        return getFamilyPathsRecursive(getByPath(nodePath), nodePath);
    }

    public function childCount(nodePath:VariantPath)
    {
        return getByPath(nodePath).children.length;
    }

    private function getFamilyPathsRecursive(node:VariantNode, nodePath:VariantPath):Array<VariantPath>
    {
        var paths:Array<VariantPath> = [nodePath.copy()];
        for (i in 0...node.children.length)
        {
            var child = node.children[i];
            paths = paths.concat(getFamilyPathsRecursive(child, nodePath.child(i)));
        }
        return paths;
    }

    public function getBranchByPath(branchPath:VariantPath):Array<RawPly>
    {
        var branch:Array<RawPly> = [];
        var node:VariantNode = this;
        for (childNum in branchPath.asArray())
        {
            node = node.children[childNum];
            branch.push(node.ply);
        }
        return branch;
    }

    public function getMainLineBranch():Array<RawPly>
    {
        return getBranchByPath(extendPathLeftmost([]));
    }

    public function pathExists(branchPath:VariantPath):Bool
    {
        var node:VariantNode = this;
        for (childNum in branchPath.asArray())
        {
            if (node.children.length <= childNum)
                return false;
            node = node.children[childNum];
        }
        return true;
    }

    public function getBranchNotationByPath(branchPath:VariantPath):Array<String>
    {
        var branch:Array<String> = [];
        var node:VariantNode = this;
        for (childNum in branchPath.asArray())
        {
            node = node.children[childNum];
            branch.push(node.getPlyStr());
        }
        return branch;
    }

    public function removeNode(path:VariantPath) 
    {
        var parent = getByPath(path.parent());
        var childNum = path[path.length - 1];
        parent.children.splice(childNum, 1);
    }

    public function getSituationByPath(path:VariantPath):Situation
    {
        return getByPath(path).situationAfter;
    }

    private function getByPath(path:VariantPath):VariantNode
    {
        var node:VariantNode = this;
        for (childNum in path.asArray())
            node = node.children[childNum];
        return node;
    }

    public function clear(?newStartingSituation:Situation)
    {
        this.ply = null;
        this.children = [];
        if (newStartingSituation != null)
        {
            this.situationBefore = newStartingSituation;
            this.situationAfter = newStartingSituation;
            this.startingSituation = newStartingSituation;
        }
    }

    public function new(startingSituation:Situation) 
    {
        super(null, startingSituation);
        this.startingSituation = startingSituation;
    }
}