package client.logic.study;

import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.PlyTreePath;
import intellectorboard.mappers.Sip;
import intellectorboard.primitives.ply.RawPly;

/** What a study saves besides its details: the ply tree and the node marked as its card preview **/
class StudyContent
{
    /** Where first children lead from the root; the card preview while no node is marked **/
    public static function mainLineEnd(tree:PlyTree):PlyTreeNode
    {
        return tree.root.line().pop();
    }

    /** The node the study's card shows **/
    public static function previewNode(tree:PlyTree, marked:Null<PlyTreeNode>):PlyTreeNode
    {
        return marked ?? mainLineEnd(tree);
    }

    /** Equal for two contents exactly when they would be saved the same **/
    public static function signature(tree:PlyTree, marked:Null<PlyTreeNode>):String
    {
        var parts:Array<String> = [Sip.fromPosition(tree.root.position)];
        collect(tree.root, parts);
        parts.push(marked != null ? "key " + PlyTreePath.of(marked).toStudyString() : "no key");
        return parts.join(";");
    }

    private static function collect(node:PlyTreeNode, parts:Array<String>):Void
    {
        for (child in node.children)
        {
            parts.push(PlyTreePath.of(child).toStudyString() + " " + plyText(child.ply));
            collect(child, parts);
        }
    }

    private static function plyText(ply:RawPly):String
    {
        return '${ply.from.toScalarCoord()}-${ply.to.toScalarCoord()}' + (ply.morphInto != null ? '=${ply.morphInto}' : "");
    }
}
