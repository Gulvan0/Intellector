package testutils;

import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.PlyTreePath;

class Variations
{
    /** `nodes` as their child index paths, comparable with `Assert.same` (nodes themselves link both ways) **/
    public static function paths(nodes:Array<PlyTreeNode>):Array<Array<Int>>
    {
        return nodes.map(node -> PlyTreePath.of(node).childIndices());
    }
}
