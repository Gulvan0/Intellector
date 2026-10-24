package net.models.study.mappers;

import client.datatypes.study.Study;
import client.datatypes.study.StudyDetails;
import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.PlyTreePath;
import client.logic.study.StudyContent;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import net.models.common.UserRefWithNickname;
import morestd.DateTime;

class StudyMapper
{
    public static function dtoToDatatype(dto:StudyPublic):Study
    {
        return build(dto.id, dto.author, dto.created_at, dto.modified_at, new StudyDetails(dto.name, dto.description, publicityToDatatype(dto.publicity), tagsOf(dto.tags)));
    }

    public static function summaryToDatatype(dto:StudySummaryPublic):Study
    {
        return build(dto.id, dto.author, dto.created_at, dto.modified_at, new StudyDetails(dto.name, dto.description, publicityToDatatype(dto.publicity), tagsOf(dto.tags)));
    }

    /** The study's plies from its starting position; an unreadable starting SIP falls back to the default position **/
    public static function treeFromDto(dto:StudyPublic):PlyTree
    {
        var startingPosition:Position = new Sip(dto.starting_sip).toPosition() ?? Position.defaultStarting();
        return StudyPlyTreeMapper.fromDto(startingPosition, dto.nodes);
    }

    /** The node marked as the card preview, if `key_path` names one in `tree` **/
    public static function markedNodeFromDto(dto:StudyPublic, tree:PlyTree):Null<PlyTreeNode>
    {
        return dto.key_path != null ? PlyTreePath.fromStudyString(dto.key_path).find(tree) : null;
    }

    public static function createPayload(details:StudyDetails, tree:PlyTree, marked:Null<PlyTreeNode>):StudyCreate
    {
        return {
            name: details.name,
            description: details.description,
            publicity: publicityToDto(details.publicity),
            starting_sip: Sip.fromPosition(tree.root.position),
            key_sip: Sip.fromPosition(StudyContent.previewNode(tree, marked).position),
            key_path: keyPathOf(marked),
            tags: details.tags,
            nodes: StudyPlyTreeMapper.toDto(tree)
        };
    }

    /** Replaces the moves, the starting position and the card preview **/
    public static function contentUpdate(tree:PlyTree, marked:Null<PlyTreeNode>):StudyUpdate
    {
        return {
            starting_sip: Sip.fromPosition(tree.root.position),
            key_sip: Sip.fromPosition(StudyContent.previewNode(tree, marked).position),
            key_path: keyPathOf(marked),
            nodes: StudyPlyTreeMapper.toDto(tree)
        };
    }

    public static function detailsUpdate(details:StudyDetails):StudyUpdate
    {
        return {
            name: details.name,
            description: details.description,
            publicity: publicityToDto(details.publicity),
            tags: details.tags
        };
    }

    private static function build(id:Int, author:UserRefWithNickname, createdAt:DateTime, modifiedAt:DateTime, details:StudyDetails):Study
    {
        return new Study(id, author.user_ref, author.nickname, createdAt.getUnixMs(), modifiedAt.getUnixMs(), details);
    }

    private static function publicityToDatatype(publicity:StudyPublicity):client.datatypes.study.StudyPublicity
    {
        return (publicity : String);
    }

    private static function publicityToDto(publicity:client.datatypes.study.StudyPublicity):StudyPublicity
    {
        return (publicity : String);
    }

    private static function tagsOf(tags:Array<StudyTagPublic>):Array<String>
    {
        return [for (tag in tags) tag.tag];
    }

    private static function keyPathOf(marked:Null<PlyTreeNode>):Null<String>
    {
        return marked != null ? PlyTreePath.of(marked).toStudyString() : null;
    }
}
