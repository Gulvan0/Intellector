package client.datatypes.variations;

enum PlyTreeChange
{
    /** Only the selection moved **/
    Selection;
    /** Nodes were added or removed, or the tree was replaced; the selection may have moved too **/
    Structure;
}
