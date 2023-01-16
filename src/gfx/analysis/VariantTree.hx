package gfx.analysis;

import haxe.ui.containers.Box;
import haxe.ui.containers.Absolute;
import net.shared.board.RawPly;
import net.shared.utils.MathUtils;
import net.shared.board.Situation;
import haxe.ui.events.MouseEvent;
import gfx.utils.PlyScrollType;
import haxe.ui.core.Component;
import haxe.ds.ArraySort;
import haxe.Timer;
import dict.Dictionary;
import haxe.ui.components.Link;
import struct.Variant;

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

class VariantTree extends Absolute implements IVariantView
{
    private static var NORMAL_BLOCK_INTERVAL_X:Float = 15;
    private static var NORMAL_PERIOD_Y:Float = 50;

    public var scale(default, null):Float = 1;

    private var arrows:Map<String, Arrow> = [];
    private var nodes:Map<String, Node> = [];

    private var columnWidths:Map<Int, Float> = [];

    private var variantRef:Variant;
    private var selectedBranch:VariantPath = [];
    private var selectedMove:Int = 0;

    private var eventHandler:PeripheralEvent->Void;

    private var indicateColors:Bool = true;

    public function getSelectedNode():VariantPath
    {
        return selectedBranch.subpath(selectedMove);
    }
    
    private function columnX(column:Int):Float
    {
        var s:Float = 0;
        for (i in 1...column)
            s += columnWidths.get(i) + NORMAL_BLOCK_INTERVAL_X * scale;
        return s;
    }

    private function rowY(row:Int):Float
    {
        return row * NORMAL_PERIOD_Y * scale;
    }

    public function handlePlyScrolling(type:PlyScrollType)
    {
        var plyNumber:Int = switch type 
        {
            case Home: 0;
            case Prev: MathUtils.maxInt(selectedMove - 1, 0);
            case Next: MathUtils.minInt(selectedMove + 1, selectedBranch.length);
            case End: selectedBranch.length;
            case Precise(plyNum): plyNum;
        }
        selectBranchUnsafe(selectedBranch, plyNumber);
    }

    private function onNodeSelectRequest(code:String)
    {
        var path:VariantPath = VariantPath.fromCode(code);

        if (selectedBranch.contains(path))
        {
            selectBranchUnsafe(selectedBranch, path.length);
            eventHandler(ScrollBtnPressed(Precise(path.length)));
        }
        else
        {
            var extendedPath:VariantPath = variantRef.extendPathLeftmost(path);

            var branch = variantRef.getBranchByPath(extendedPath);
            var branchStr = variantRef.getBranchNotationByPath(extendedPath);
            var pointer = path.length;
    
            selectBranchUnsafe(extendedPath, path.length);
            eventHandler(BranchSelected(branch, branchStr, pointer));
        }
    }

    private function onNodeRemoveRequest(code:String)
    {
        var path:VariantPath = VariantPath.fromCode(code);

        if (!path.isRoot())
            removeNodeByPath(path);
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
            arrows[code].moveComponentToFront();
            if (i == selectUpToMove - 1)
                nodes[code].select();
            code += ":";
        }

        for (node in nodes)
            node.moveComponentToFront();

        selectedBranch = fullBranch.copy();
        selectedMove = selectUpToMove;
    }

    public function clear(?newStartingSituation:Situation)
    {
        for (arrow in arrows)
            removeComponent(arrow);

        var startNode:Node = nodes.get("");
        startNode.select();
        for (code => node in nodes.keyValueIterator())
            if (code != "")
                removeComponent(node);

        variantRef.clear(newStartingSituation);

        arrows = [];
        nodes = ["" => startNode];
        selectedBranch = [];
        selectedMove = 0;
        columnWidths = [];
    }

    public function removeNodeByPath(path:VariantPath)
    {
        var parentPath = path.parent();
        var belongsToSelected:Bool = selectedBranch.contains(path);
        var newMoveNumToSelect:Int = Math.round(Math.min(parentPath.length, selectedMove));
        
        if (belongsToSelected)
            deselectAll();

        for (familyMemberPath in variantRef.getFamilyPaths(path))
        {
            var code:String = familyMemberPath.code();
            removeComponent(nodes.get(code));
            removeComponent(arrows.get(code));
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
        {
            selectBranchUnsafe(variantRef.extendPathLeftmost(parentPath), newMoveNumToSelect);

            var branch = variantRef.getBranchByPath(selectedBranch);
            var branchStr = variantRef.getBranchNotationByPath(selectedBranch);
            eventHandler(BranchSelected(branch, branchStr, selectedMove));
        }

        refreshLayout();
    }

    public function addChildNode(parentPath:VariantPath, ply:RawPly, selectChild:Bool)
    {
        var nodeNum:Int = variantRef.childCount(parentPath);
        var nodePath:VariantPath = parentPath.child(nodeNum);
        var nodeCode:String = nodePath.code();

        var plyStr:String = ply.toNotation(variantRef.getSituationByPath(parentPath), indicateColors);

        variantRef.addChildToNode(ply, parentPath);

        var node:Node = new Node(scale, nodeCode, plyStr, selectChild, onNodeSelectRequest, onNodeRemoveRequest);
        nodes.set(nodeCode, node);
        addComponent(node);

        var arrow:Arrow = new Arrow(scale);
        arrows.set(nodeCode, arrow);
        addComponent(arrow);
        arrow.moveComponentToBack();

        refreshLayout();

        if (selectChild)
            selectBranchUnsafe(nodePath, nodePath.length);
    }

    public function refreshLayout()
    {
        var displacement:DisplacementInfo = buildOptimalDisplacement();
        
        //Update column widths
        columnWidths = [];
        for (column => codes in displacement.columnContents.keyValueIterator())
        {
            var maxWidth:Float = column == 1? nodes.get('').textSize.width : 0;
            for (code in codes)
            {
                var node = nodes.get(code);
                if (node.textSize.width > maxWidth)
                    maxWidth = node.textSize.width;
            }
            columnWidths.set(column, maxWidth);
        }
        
        //Update nodes
        for (code => cell in displacement.cellularMapping.keyValueIterator())
        {
            var node:Node = nodes.get(code);
            node.left = columnX(cell.column);
            node.top = rowY(cell.row);
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

    public function addChildToSelectedNode(ply:RawPly, selectChild:Bool) 
    {
        addChildNode(selectedBranch.subpath(selectedMove), ply, selectChild);
    }

    public function setScale(scale:Float)
    {
        removeAllComponents();

        arrows = [];
        nodes = [];
        selectedBranch = [];
        selectedMove = 0;
        columnWidths = [];

        this.scale = scale;

        drawFromScratch(variantRef, selectedBranch.subpath(selectedMove));
        refreshLayout();
    }

    private function drawFromScratch(variant:Variant, ?selectedNodePath:VariantPath)
    {
        var startingNode:Node = new Node(scale, '', Dictionary.getPhrase(OPENING_STARTING_POSITION), false, onNodeSelectRequest, v->{});
        nodes.set('', startingNode);
        addComponent(startingNode);

        for (code => nodeInfo in variant.getAllNodes())
        {
            if (code == '')
                continue;

            var node = new Node(scale, code, nodeInfo.getPlyStr(indicateColors), false, onNodeSelectRequest, onNodeRemoveRequest);
            var arrow = new Arrow(scale);

            nodes.set(code, node);
            arrows.set(code, arrow);

            addComponent(node);
            addComponent(arrow);
            arrow.moveComponentToBack();
        }

        if (selectedNodePath != null)
            selectBranchUnsafe(variant.extendPathLeftmost(selectedNodePath), selectedNodePath.length);
        else
        {
            var branch:VariantPath = variant.getLastMainLineDescendantPath([]);
            selectBranchUnsafe(branch, branch.length);
        }
    }

    public function init(eventHandler:PeripheralEvent->Void)
    {
        this.eventHandler = eventHandler;
    }

    public function new(variant:Variant, ?selectedNodePath:VariantPath) 
    {
        super();
        this.variantRef = variant;
        this.indicateColors = Preferences.branchingTurnColorIndicators.get();

        drawFromScratch(variant, selectedNodePath);
    }
}