package gfx.analysis;

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

    private var variant:Variant;
    private var selectedBranch:VariantPath = []; //TODO: Consider init() with selectedBranch as a parameter

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
        //TODO: Fill
    }

    private function onNodeRemoveRequest(code:String)
    {
        if (code == '')
            return;
        
        var plysToRevert:Null<Int>;
        var path:VariantPath = VariantPath.fromCode(code);

        if (selectedBranch.contains(path))
            plysToRevert = selectedBranch.length - path.length + 1;

        removeNode(path);

        if (plysToRevert != null)
            onRevertNeeded(plysToRevert);
    }

    private function deselectAll() 
    {
        nodes[selectedBranch.code()].deselect();

        var code:String = "";
        for (childNum in selectedBranch.asArray())
        {
            code += childNum;
            arrows[code].unhighlight();
            code += ":";
        }
        selectedBranch = [];
    }

    private function selectBranch(branchToSelect:VariantPath)
    {
        deselectAll();
        var extendedBranch = variant.extendPathLeftmost(branchToSelect);
        var normalLength:Int = branchToSelect.length;
        var extendedLength:Int = extendedBranch.length;

        var code:String = "";
        for (i in 0...extendedLength)
        {
            var childNum = extendedBranch[i];
            code += childNum;
            arrows[code].highlight(i < normalLength);
            if (i == normalLength - 1)
                nodes[code].select();
            code += ":";
        }
        selectedBranch = branchToSelect.copy();
    }

    public function clear(?newStartingSituation:Situation)
    {
        var startingSit:Situation = newStartingSituation != null? newStartingSituation.copy() : variant.startingSituation;
        variant = new Variant(startingSit);
        for (arrow in arrows)
            removeChild(arrow);

        var startNode:Node;
        for (code => node in nodes.keyValueIterator())
            if (code != "")
                removeChild(node);
            else
                startNode = node;

        arrows = [];
        nodes = ["" => startNode];
        selectedBranch = [];
        columnWidths = [];
    }

    public function removeNode(path:VariantPath)
    {
        var code:String = path.code();

        variant.removeNode(path);

        removeChild(nodes.get(code));
        removeChild(arrows.get(code));
        nodes.remove(code);
        arrows.remove(code);

        refreshLayout();

        if (selectedBranch.contains(path))
            selectBranch(path.parent());
    }

    public function addChildNode(parentPath:VariantPath, ply:Ply, selectChild:Bool)
    {
        var nodeNum:Int = variant.childCount(parentPath);
        var nodePath:VariantPath = parentPath.child(nodeNum);
        var nodeCode:String = nodePath.code();

        var plyStr:String = ply.toNotation(variant.getSituationByPath(parentPath));

        variant.addChildToNode(ply, parentPath);

        var node:Node = new Node(nodeCode, plyStr, selectChild, onNodeSelectRequest, onNodeRemoveRequest);
        nodes.set(nodeCode, node);
        addChild(node);

        var arrow:Arrow = new Arrow();
        arrows.set(nodeCode, arrow);
        addChild(arrow);

        refreshLayout();

        if (selectChild)
            selectBranch(nodePath);
    }

    private function refreshLayout()
    {
        var displacement:DisplacementInfo = buildOptimalDisplacement();

        //Update column widths
        columnWidths = [];
        for (column => codes in displacement.columnContents.keyValueIterator())
        {
            var maxWidth:Float = 0;
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
        info.cellularMapping = [];
        info.columnContents = [];
        info.maxColumn = 0;

        var rowLengths:Map<Int, Int> = [];

        function recursive(path:VariantPath)
        {
            for (childNum in 0...variant.childCount(path))
                recursive(path.child(childNum));

            var row:Int = path.length;
            if (row == 0)
                return;

            var code:String = path.code();

            var column:Null<Int> = rowLengths.get(row);
            if (column == null)
            {
                column = 1;
                rowLengths[row] = 1;
            }
            else
                rowLengths[row]++;

            info.cellularMapping.set(code, {row: row, column: column});

            if (info.columnContents.exists(column))
                info.columnContents[column].push(code);
            else
            {
                info.columnContents[column] = [code];
                if (info.maxColumn < column)
                    info.maxColumn = column;
            }
        }

        recursive([]);
        return info;
    }

    public function addChildToSelectedNode(ply:Ply, selectChild:Bool) 
    {
        addChildNode(selectedBranch, ply, selectChild);
    }

    public function getSerializedVariant():String 
    {
		return variant.serialize();
	}

    public function getSelectedBranch():VariantPath 
    {
		return selectedBranch.copy();
	}

    public function getStartingSituation():Situation 
    {
		return variant.startingSituation.copy();
	}

    public function init(onBranchSelect:SelectedBranchInfo->Void, onRevertNeeded:Int->Void)
    {
        this.onBranchSelect = onBranchSelect;
        this.onRevertNeeded = onRevertNeeded;
    }

    public function new(?initialVariant:Variant, ?selectedBranch:VariantPath) 
    {
        super();

        var startingNode:Node = new Node('', Dictionary.getPhrase(OPENING_STARTING_POSITION), false, onNodeSelectRequest, v->{});
        nodes.set('', startingNode);
        addChild(startingNode);

        if (initialVariant == null)
            this.variant = new Variant(Situation.starting());
        else
        {
            this.variant = initialVariant;
            for (code => nodeInfo in initialVariant.getAllNodes())
            {
                if (code == '')
                    continue;

                var node = new Node(code, nodeInfo.getPlyStr(), false, onNodeSelectRequest, onNodeRemoveRequest);
                var arrow = new Arrow();

                nodes.set(code, node);
                arrows.set(code, arrow);

                addChild(node);
                addChild(arrow);
            }
        }

        if (selectedBranch != null)
            selectBranch(selectedBranch);
        else
            selectBranch([]);
    }
}