package net.models.study.mappers;

import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.PlyTreePath;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;
import net.models.common.mappers.PieceKindMapper;

class StudyPlyTreeMapper
{
    /** Every node but the root, parents before their children **/
    public static function toDto(tree:PlyTree):Array<ApiPlyTreeNode>
    {
        var dtos:Array<ApiPlyTreeNode> = [];
        collect(tree.root, dtos);
        return dtos;
    }

    private static function collect(node:PlyTreeNode, dtos:Array<ApiPlyTreeNode>):Void
    {
        for (child in node.children)
        {
            dtos.push({path: PlyTreePath.of(child).toStudyString(), ply: ApiPlyMapper.toDto(child.ply)});
            collect(child, dtos);
        }
    }

    /** The nodes may come in any order; a node whose parent or earlier sibling is missing is dropped with its descendants **/
    public static function fromDto(startingPosition:Position, dtos:Array<StudyPlyTreeNodePublic>):PlyTree
    {
        var entries:Array<{path:PlyTreePath, dto:StudyPlyTreeNodePublic}> = [
            for (dto in dtos)
                {path: PlyTreePath.fromStudyString(dto.path), dto: dto}
        ];
        entries.sort((a, b) -> PlyTreePath.compare(a.path, b.path));

        var tree:PlyTree = new PlyTree(startingPosition);
        for (entry in entries)
        {
            var indices:Array<Int> = entry.path.childIndices();
            var parent:Null<PlyTreeNode> = entry.path.parent().find(tree);
            if (indices.length == 0 || parent == null || parent.children.length != indices[indices.length - 1])
                continue;
            tree.play(parent, plyOf(entry.dto));
        }
        return tree;
    }

    private static function plyOf(dto:StudyPlyTreeNodePublic):RawPly
    {
        var morphInto:Null<PieceKind> = dto.ply_morph_into != null ? PieceKindMapper.dtoToDatatype(dto.ply_morph_into) : null;
        return RawPly.construct(new HexCoords(dto.ply_from_i, dto.ply_from_j), new HexCoords(dto.ply_to_i, dto.ply_to_j), morphInto);
    }
}
