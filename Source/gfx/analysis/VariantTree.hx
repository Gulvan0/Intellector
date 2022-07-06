package gfx.analysis;

import haxe.ds.ArraySort;
import utils.MathUtils;
import haxe.Timer;
import dict.Dictionary;
import struct.Ply;
import struct.Situation;
import gfx.analysis.IVariantView.SelectedBranchInfo;
import haxe.ui.components.Link;
import openfl.geom.Point;
import struct.Variant;
import openfl.display.Sprite;

typedef Cell = 
{
    public var row:Int;
    public var column:Int;
}

class DisplacementInfo
{
    public var cellularMapping:Map<String, Cell>;
    public var columnContents:Map<Int, Array<String>>;
    public var maxColumn:Int;

    public function new()
    {

    }
}

class VariantTree extends Sprite implements IVariantView
{
    private static var BLOCK_INTERVAL_X:Float = 15;
    private static var PERIOD_Y:Float = 50;

    private var arrows:Map<String, Arrow> = [];
    private var nodes:Map<String, Node> = [];

    private var columnWidths:Map<Int, Float> = [];

    private var onBranchSelect:SelectedBranchInfo->Void;
    private var onRevertNeeded:(plysToRevert:Int)->Void;

    private var variantRef:Variant;
    private var selectedBranch:VariantPath = [];
    private var selectedMove:Int;

    private var indicateColors:Bool = true;

    private function columnX(column:Int):Float
    {
        var s:Float = 0;
        for (i in 1...column)
            s += columnWidths.get(i) + BLOCK_INTERVAL_X;
        return s;
    }

    private function rowY(row:Int):Float
    {
        return row * PERIOD_Y;
    }

    private function onNodeSelectRequest(code:String)
    {
        var path:VariantPath = VariantPath.fromCode(code);
        var extendedPath:VariantPath;
        if (selectedBranch.contains(path))
            extendedPath = selectedBranch;
        else
            extendedPath = variantRef.extendPathLeftmost(path);

        var info:SelectedBranchInfo = new SelectedBranchInfo();
        info.plyArray = variantRef.getBranchByPath(extendedPath);
        info.plyStrArray = variantRef.getBranchNotationByPath(extendedPath);
        info.selectedPlyNum = path.length;

        selectBranchUnsafe(extendedPath, path.length);
        onBranchSelect(info);
    }

    private function onNodeRemoveRequest(code:String)
    {
        if (code == '')
            return;
        
        var plysToRevert:Null<Int> = null;
        var path:VariantPath = VariantPath.fromCode(code);

        if (selectedBranch.subpath(selectedMove).contains(path))
            plysToRevert = selectedMove - path.length + 1;

        removeNode(path);

        if (plysToRevert != null)
            onRevertNeeded(plysToRevert);
    }

    private function deselectAll() 
    {
        var code:String = "";
        for (childNum in selectedBranch.asArray())
        {
            code += childNum;
            nodes[code].deselect();
            arrows[code].unhighlight();
            code += ":";
        }
        selectedBranch = [];
        selectedMove = 0;
    }

    private function selectBranchUnsafe(fullBranch:VariantPath, selectUpToMove:Int)
    {
        #if debug
        if (fullBranch.code() != variantRef.extendPathLeftmost(fullBranch).code())
            throw "fullBranch isn't really full";
        #end
        
        deselectAll();

        if (selectUpToMove == 0)
            nodes[""].select();

        var code:String = "";
        for (i in 0...fullBranch.length)
        {
            var childNum = fullBranch[i];
            code += childNum;
            arrows[code].highlight(i < selectUpToMove);
            addChild(arrows[code]); //Brings highlighted arrows to the front to make them more visible
            if (i == selectUpToMove - 1)
                nodes[code].select();
            code += ":";
        }

        selectedBranch = fullBranch.copy();
        selectedMove = selectUpToMove;
    }

    public function clear(?newStartingSituation:Situation)
    {
        for (arrow in arrows)
            removeChild(arrow);

        var startNode:Node = nodes.get("");
        startNode.select();
        for (code => node in nodes.keyValueIterator())
            if (code != "")
                removeChild(node);

        variantRef.clear(newStartingSituation);

        arrows = [];
        nodes = ["" => startNode];
        selectedBranch = [];
        selectedMove = 0;
        columnWidths = [];
    }

    public function removeNode(path:VariantPath)
    {
        var parentPath = path.parent();
        var belongsToSelected:Bool = selectedBranch.contains(path);
        var newMoveNumToSelect:Int = Math.round(Math.min(parentPath.length, selectedMove));
        
        if (belongsToSelected)
            deselectAll();

        for (familyMemberPath in variantRef.getFamilyPaths(path))
        {
            var code:String = familyMemberPath.code();
            removeChild(nodes.get(code));
            removeChild(arrows.get(code));
            nodes.remove(code);
            arrows.remove(code);
        }

        for (siblingPath in variantRef.getRightSiblingsPaths(path, false))
            for (familyMemberPath in variantRef.getFamilyPaths(siblingPath))
            {
                var oldCode:String = familyMemberPath.code();
                var newPath:VariantPath = familyMemberPath.copy();
                newPath.asArray()[path.length - 1]--;
                var newCode:String = newPath.code();
                nodes.set(newCode, nodes.get(oldCode));
                nodes.remove(oldCode);
                arrows.set(newCode, arrows.get(oldCode));
                arrows.remove(oldCode);
            }

            variantRef.removeNode(path);

        if (belongsToSelected)
            selectBranchUnsafe(variantRef.extendPathLeftmost(parentPath), newMoveNumToSelect);

        refreshLayout();
    }

    public function addChildNode(parentPath:VariantPath, ply:Ply, selectChild:Bool)
    {
        var nodeNum:Int = variantRef.childCount(parentPath);
        var nodePath:VariantPath = parentPath.child(nodeNum);
        var nodeCode:String = nodePath.code();

        var plyStr:String = ply.toNotation(variantRef.getSituationByPath(parentPath), indicateColors);

        variantRef.addChildToNode(ply, parentPath);

        var node:Node = new Node(nodeCode, plyStr, selectChild, onNodeSelectRequest, onNodeRemoveRequest);
        nodes.set(nodeCode, node);
        addChild(node);

        var arrow:Arrow = new Arrow();
        arrows.set(nodeCode, arrow);
        addChild(arrow);

        refreshLayout();

        if (selectChild)
            selectBranchUnsafe(nodePath, nodePath.length);
    }

    private function refreshLayout()
    {
        var displacement:DisplacementInfo = buildOptimalDisplacement();
        
        //Update column widths
        columnWidths = [];
        for (column => codes in displacement.columnContents.keyValueIterator())
        {
            var maxWidth:Float = column == 1? nodes.get('').textWidth : 0;
            for (code in codes)
            {
                var node = nodes.get(code);
                if (node.textWidth > maxWidth)
                    maxWidth = node.textWidth;
            }
            columnWidths.set(column, maxWidth);
        }
        
        //Update nodes
        for (code => cell in displacement.cellularMapping.keyValueIterator())
        {
            var node:Node = nodes.get(code);
            node.x = columnX(cell.column);
            node.y = rowY(cell.row);
            node.width = columnWidths.get(cell.column);
            node.code = code;
        }

        //Update arrows
        for (code => arrow in arrows.keyValueIterator())
        {
            var parentCode = code.split(":").slice(0, -1).join(":");
            var departure = nodes.get(parentCode).outputPos();
            var destination = nodes.get(code).inputPos();
            arrow.changeEndpoints(departure, destination);
        }
    }

    private function buildOptimalDisplacement():DisplacementInfo
    {
        var info:DisplacementInfo = new DisplacementInfo();
        info.cellularMapping = ['' => {row: 0, column: 1}];
        info.columnContents = [];
        info.maxColumn = 0;

        var rowLengths:Map<Int, Int> = [];

        function recursive(path:VariantPath)
        {
            var row:Int = path.length;
            var code:String = path.code();
            var parentCode:String = path.parent().code();

            var column:Int = 1;
            var iteratedRow:Int = row;
            var iteratedDescendantPath:VariantPath = path.copy();
            while (rowLengths.exists(iteratedRow) && variantRef.pathExists(iteratedDescendantPath))
            {
                column = MathUtils.maxInt(column, rowLengths.get(iteratedRow) + 1);
                iteratedRow++;
                iteratedDescendantPath = iteratedDescendantPath.child(0);
            }

            column = MathUtils.maxInt(column, info.cellularMapping.get(parentCode).column);
            rowLengths[row] = column;

            info.cellularMapping.set(code, {row: row, column: column});

            if (info.columnContents.exists(column))
                info.columnContents[column].push(code);
            else
            {
                info.columnContents[column] = [code];
                if (info.maxColumn < column)
                    info.maxColumn = column;
            }

            for (childNum in 0...variantRef.childCount(path))
                recursive(path.child(childNum));
        }

        var path:VariantPath = [];
        for (childNum in 0...variantRef.childCount(path))
            recursive(path.child(childNum));
        return info;
    }

    public function addChildToSelectedNode(ply:Ply, selectChild:Bool) 
    {
        addChildNode(selectedBranch.subpath(selectedMove), ply, selectChild);
    }

    public function init(onBranchSelect:SelectedBranchInfo->Void, onRevertNeeded:Int->Void)
    {
        this.onBranchSelect = onBranchSelect;
        this.onRevertNeeded = onRevertNeeded;
    }

    public function new(variant:Variant, ?selectedNodePath:VariantPath) 
    {
        super();
        this.variantRef = variant;
        this.indicateColors = Preferences.branchingTurnColorIndicators.get();

        var startingNode:Node = new Node('', Dictionary.getPhrase(OPENING_STARTING_POSITION), false, onNodeSelectRequest, v->{});
        nodes.set('', startingNode);
        addChild(startingNode);

        for (code => nodeInfo in initialVariant.getAllNodes())
        {
            if (code == '')
                continue;

            var node = new Node(code, nodeInfo.getPlyStr(indicateColors), false, onNodeSelectRequest, onNodeRemoveRequest);
            var arrow = new Arrow();

            nodes.set(code, node);
            arrows.set(code, arrow);

            addChild(node);
            addChild(arrow);
        }

        if (selectedNodePath != null)
            selectBranchUnsafe(variantRef.extendPathLeftmost(selectedNodePath), selectedNodePath.length);
        else
            selectBranchUnsafe(variantRef.extendPathLeftmost([]), 0);

        Timer.delay(refreshLayout, 200);
    }
}