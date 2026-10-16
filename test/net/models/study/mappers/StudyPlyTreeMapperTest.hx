package net.models.study.mappers;

import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.PlyTreePath;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;
import testutils.Plies;
import utest.Assert;
import utest.Test;

class StudyPlyTreeMapperTest extends Test
{
    private static function sample():PlyTree
    {
        var tree:PlyTree = new PlyTree(Position.defaultStarting());
        var main:PlyTreeNode = tree.play(tree.root, Plies.legal(tree.root.position, 0));
        var reply:PlyTreeNode = tree.play(main, Plies.legal(main.position, 0));
        tree.play(reply, Plies.legal(reply.position, 0));
        tree.play(main, Plies.legal(main.position, 3));
        tree.play(tree.root, Plies.legal(tree.root.position, 5));
        return tree;
    }

    private static function nodeDto(apiNode:ApiPlyTreeNode):StudyPlyTreeNodePublic
    {
        var dto:StudyPlyTreeNodePublic = Type.createEmptyInstance(StudyPlyTreeNodePublic);
        dto.path = apiNode.path;
        dto.ply_from_i = apiNode.ply.departure.i;
        dto.ply_from_j = apiNode.ply.departure.j;
        dto.ply_to_i = apiNode.ply.destination.i;
        dto.ply_to_j = apiNode.ply.destination.j;
        dto.ply_morph_into = apiNode.ply.morph_into;
        return dto;
    }

    private static function describe(tree:PlyTree):Array<String>
    {
        var descriptions:Array<String> = [];
        var pending:Array<PlyTreeNode> = [tree.root];
        while (pending.length > 0)
        {
            var node:PlyTreeNode = pending.shift();
            if (!node.isRoot())
                descriptions.push(PlyTreePath.of(node).toStudyString() + "/" + plyKey(node.ply));
            for (child in node.children)
                pending.push(child);
        }
        return descriptions;
    }

    private static function plyKey(ply:RawPly):String
    {
        return '${ply.from.i}${ply.from.j}${ply.to.i}${ply.to.j}${ply.morphInto}';
    }

    private function testToDtoListsParentsFirstWithStudyPaths():Void
    {
        var dtos:Array<ApiPlyTreeNode> = StudyPlyTreeMapper.toDto(sample());

        Assert.same(["", "x2", "x3", ":1", "1"], dtos.map(dto -> dto.path));
        Assert.isNull(dtos[0].ply.morph_into);
    }

    private function testRoundTripInAnyOrder():Void
    {
        var tree:PlyTree = sample();
        var dtos:Array<StudyPlyTreeNodePublic> = StudyPlyTreeMapper.toDto(tree).map(nodeDto);
        dtos.reverse();

        var restored:PlyTree = StudyPlyTreeMapper.fromDto(Position.defaultStarting(), dtos);

        Assert.same(describe(tree), describe(restored));
    }

    private function testOrphansAreDropped():Void
    {
        var dtos:Array<StudyPlyTreeNodePublic> = StudyPlyTreeMapper.toDto(sample()).map(nodeDto);
        var withoutMainReply:Array<StudyPlyTreeNodePublic> = dtos.filter(dto -> dto.path != "x2");

        var restored:PlyTree = StudyPlyTreeMapper.fromDto(Position.defaultStarting(), withoutMainReply);

        Assert.equals(2, restored.moveCount());
        Assert.equals(0, restored.root.children[0].children.length);
    }
}
