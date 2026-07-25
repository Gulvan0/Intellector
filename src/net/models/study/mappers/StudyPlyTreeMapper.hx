package net.models.study.mappers;

import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.ply.RawPly;
import intellectorboard.plytree.PlyTreeNodeBase;
import intellectorboard.plytree.path.PlyTreePath;
import intellectorboard.position.Position;
import intellectorboard.plytree.PlyTreePlyNode;
import intellectorboard.plytree.PlyTree;

class StudyPlyTreeMapper
{
    public static function toDto(plyTree:PlyTree):Array<ApiPlyTreeNode>
    {
        return [
            for (nodeData in plyTree.collectPlyNodes())
            {path: nodeData.path.toString(), ply: ApiPlyMapper.toDto(nodeData.node.ply)}
        ];
    }

    private static function rawPlyFromNodeDto(dto:StudyPlyTreeNodePublic):RawPly
    {
        return RawPly.construct(new HexCoords(dto.ply_from_i, dto.ply_from_j), new HexCoords(dto.ply_to_i, dto.ply_to_j), dto.ply_morph_into);
    }

    private static function addNode(tree:PlyTree, createdNodes:Map<String, PlyTreePlyNode>, pendingNodes:Map<String, StudyPlyTreeNodePublic>, path:PlyTreePath, dto:StudyPlyTreeNodePublic)
    {
        var parentPath:Null<PlyTreePath> = path.getParent();
        var parentNode:PlyTreeNodeBase = parentPath != null? createdNodes.get(parentPath.toString()) : tree.root;
        var createdNode:PlyTreePlyNode = parentNode.addChild(rawPlyFromNodeDto(nodeDto));

        var pathStr:String = path.toString();
        var dependentDto:Null<StudyPlyTreeNodePublic> = pendingNodes.get(pathStr);
        if (dependentDto == null)
            return;

        pendingNodes.remove(pathStr);
        addNode(tree, createdNodes, pendingNodes, PlyTreePath.fromString(dto.path), dependentDto);
    }

    public static function fromDto(startingPosition:Position, nodeDtos:Array<StudyPlyTreeNodePublic>):PlyTree
    {
        var tree:PlyTree = new PlyTree(startingPosition);
        var createdNodes:Map<String, PlyTreePlyNode> = [];
        var pendingNodes:Map<String, StudyPlyTreeNodePublic> = [];

        for (nodeDto in nodeDtos)
        {
            var nodePath:PlyTreePath = PlyTreePath.fromString(nodeDto.path);

            var dependencyPath:Null<PlyTreePath> = nodePath.getDependency();
            if (dependencyPath != null)
            {
                var dependencyPathStr:String = dependencyPath.toString();
                if (!createdNodes.exists(dependencyPathStr))
                {
                    pendingNodes.set(dependencyPathStr, nodeDto);
                    continue;
                }
            }

            addNode(tree, createdNodes, pendingNodes, nodePath, nodeDto);
        }
    }
}
