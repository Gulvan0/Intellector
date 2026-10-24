package client.logic.variations;

import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.PlyTreePath;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;

typedef StoredPly =
{
    path:String,
    from:Int,
    to:Int,
    morphInto:Null<String>
}

/** The analysis board in plain data, fit for the browser's navigation state **/
typedef StoredAnalysis =
{
    startingSip:String,
    plies:Array<StoredPly>,
    selectedPath:String,
    markedPath:Null<String>
}

typedef RestoredAnalysis =
{
    tree:PlyTree,
    selected:PlyTreeNode,
    marked:Null<PlyTreeNode>
}

/** Converts the analysis board's ply tree, selection and preview mark to and from `StoredAnalysis` **/
class AnalysisStateCodec
{
    private static inline final ROOT_PATH:String = "root";
    private static final PATH_PATTERN:EReg = ~/^[0-9x:]*$/;

    public static function encode(tree:PlyTree, selected:PlyTreeNode, marked:Null<PlyTreeNode>):StoredAnalysis
    {
        var plies:Array<StoredPly> = [];
        collect(tree.root, plies);
        return {
            startingSip: Sip.fromPosition(tree.root.position),
            plies: plies,
            selectedPath: pathOf(selected),
            markedPath: marked != null ? pathOf(marked) : null
        };
    }

    /** Null unless `raw` is a well-formed stored analysis **/
    public static function decode(raw:Dynamic):Null<RestoredAnalysis>
    {
        try
        {
            return build(raw);
        }
        catch (_)
        {
            return null;
        }
    }

    private static function collect(node:PlyTreeNode, plies:Array<StoredPly>):Void
    {
        for (child in node.children)
        {
            plies.push({
                path: PlyTreePath.of(child).toStudyString(),
                from: child.ply.from.toScalarCoord(),
                to: child.ply.to.toScalarCoord(),
                morphInto: child.ply.morphInto != null ? Std.string(child.ply.morphInto) : null
            });
            collect(child, plies);
        }
    }

    private static function build(raw:Dynamic):Null<RestoredAnalysis>
    {
        if (raw == null || !Reflect.isObject(raw) || !Std.isOfType(raw.startingSip, String) || !Std.isOfType(raw.plies, Array))
            return null;

        var startingPosition:Null<Position> = new Sip(raw.startingSip).toPosition();
        if (startingPosition == null)
            return null;

        var storedPlies:Array<StoredPly> = raw.plies;
        var entries:Array<{path:PlyTreePath, stored:StoredPly}> = [];
        for (stored in storedPlies)
        {
            if (!isPath(stored.path) || !Std.isOfType(stored.from, Int) || !Std.isOfType(stored.to, Int))
                return null;
            entries.push({path: PlyTreePath.fromStudyString(stored.path), stored: stored});
        }
        entries.sort((a, b) -> PlyTreePath.compare(a.path, b.path));

        var tree:PlyTree = new PlyTree(startingPosition);
        for (entry in entries)
        {
            var indices:Array<Int> = entry.path.childIndices();
            var parent:Null<PlyTreeNode> = entry.path.parent().find(tree);
            if (indices.length == 0 || parent == null || parent.children.length != indices[indices.length - 1])
                return null;
            tree.play(parent, plyOf(entry.stored));
        }

        return {
            tree: tree,
            selected: nodeAt(tree, raw.selectedPath) ?? tree.root,
            marked: raw.markedPath != null ? nodeAt(tree, raw.markedPath) : null
        };
    }

    private static function plyOf(stored:StoredPly):RawPly
    {
        var morphInto:Null<PieceKind> = stored.morphInto != null ? Type.createEnum(PieceKind, stored.morphInto) : null;
        return RawPly.construct(HexCoords.fromScalarCoord(stored.from), HexCoords.fromScalarCoord(stored.to), morphInto);
    }

    // the study string of the root's path is empty, like the first child's
    private static function pathOf(node:PlyTreeNode):String
    {
        return node.isRoot() ? ROOT_PATH : PlyTreePath.of(node).toStudyString();
    }

    private static function nodeAt(tree:PlyTree, path:Dynamic):Null<PlyTreeNode>
    {
        if (path == ROOT_PATH)
            return tree.root;

        return isPath(path) ? PlyTreePath.fromStudyString(path).find(tree) : null;
    }

    private static function isPath(value:Dynamic):Bool
    {
        return Std.isOfType(value, String) && PATH_PATTERN.match(value);
    }
}
