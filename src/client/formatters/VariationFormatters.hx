package client.formatters;

import client.datatypes.variations.PlyTreeNode;
import intellectorboard.mappers.notation.PlyFormatter;

class VariationFormatters
{
    /** The ply leading to `node` in notation; null at the root **/
    public static function notation(node:PlyTreeNode):Null<String>
    {
        return node.isRoot() ? null : PlyFormatter.toNotation(node.ply, node.parent.position);
    }

    /** Notations along `line` (as `PlyTreeNode.line` gives it), the root's left out **/
    public static function lineNotations(line:Array<PlyTreeNode>):Array<String>
    {
        return [for (i in 1...line.length) notation(line[i])];
    }
}
