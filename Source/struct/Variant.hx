package struct;

import serialization.SituationDeserializer;
import serialization.PlyDeserializer;
import haxe.Json;
import haxe.ui.util.Variant;
import struct.Ply;

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

    public inline function new(a:Array<Int>) 
    {
        this = a;
    }
}

class VariantNode
{
    public var ply:Ply;
    public var situationBefore:Situation;
    public var situationAfter:Situation;
    public var children:Array<VariantNode>;

    public function addChild(ply:Ply) 
    {
        var child = new VariantNode(ply, situationAfter);
        children.push(child);
    }

    public function getPlyStr():String
    {
        return ply.toNotation(situationBefore);
    }

    public function new(ply:Ply, situationBefore:Situation) 
    {
        this.ply = ply;
        this.situationBefore = situationBefore;
        this.situationAfter = ply != null? situationBefore.makeMove(ply) : situationBefore;
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

    //TODO: Rewrite existing study data files on the server to match new format
    public function serialize():String 
    {
        var serialized:String = "";

        for (code => node in getAllNodes())
            if (code != '')
                serialized += code + "/" + PlyDeserializer.serialize(node.ply) + ";";

        serialized += startingSituation.serialize();
                
        return serialized;
    }

    public static function deserialize(s:String):Variant
    {
        var variantStrParts:Array<String> = s.split(";");
        var startingSituationSIP:String = variantStrParts.pop();
        var startingSituation:Situation = SituationDeserializer.deserialize(startingSituationSIP);
        var nodesByPathLength:Map<Int, Array<{parentPath:VariantPath, nodeNum:Int, ply:Ply}>> = [];
        var maxPathLength:Int = 0;

        for (nodeStr in variantStrParts)
        {
            var nodeStrParts = nodeStr.split("/");
            var code = nodeStrParts[0];
            var path = VariantPath.fromCode(code);
            var ply = PlyDeserializer.deserialize(nodeStrParts[1]);
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

    public function addChildToNode(ply:Ply, parentPath:VariantPath) 
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

    public function getBranchByPath(branchPath:VariantPath):Array<Ply>
    {
        var branch:Array<Ply> = [];
        var node:VariantNode = this;
        for (childNum in branchPath.asArray())
        {
            node = node.children[childNum];
            branch.push(node.ply);
        }
        return branch;
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
        return getByPath(path).situationBefore;
    }

    private function getByPath(path:VariantPath):VariantNode
    {
        var node:VariantNode = this;
        for (childNum in path.asArray())
            node = node.children[childNum];
        return node;
    }

    public function new(startingSituation:Situation) 
    {
        super(null, startingSituation);
        this.startingSituation = startingSituation;
    }
}