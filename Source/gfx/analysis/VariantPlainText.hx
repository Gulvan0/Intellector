package gfx.analysis;

import haxe.ui.core.Component;
import haxe.ui.components.Label;
import struct.Situation;
import struct.Variant;
import utils.MathUtils;
import struct.Ply;
import gfx.utils.PlyScrollType;
import struct.Variant.VariantPath;
import haxe.ui.styles.Style;
import haxe.ui.components.Link;
import haxe.ui.containers.HBox;

private var DEFAULT_STYLE:Style = {color: 0x333333, fontUnderline: false};

private class PlyNode extends Link
{
    public var path(default, set):VariantPath;
    public var selected(get, set):Bool;

    private function set_path(v:VariantPath):VariantPath
    {
        var newStyle:Style = customStyle.clone();
        newStyle.fontItalic = !v.isMainLine();
        customStyle = newStyle;
        return path = v.copy();
    }

    private function get_selected():Bool
    {
        return customStyle.fontBold;
    }

    private function set_selected(v:Bool):Bool
    {
        var newStyle:Style = customStyle.clone();
        newStyle.fontBold = v;
        customStyle = newStyle;
        return v;
    }

    public function new(path:VariantPath, ply:Ply, onNodeSelectRequest:VariantPath->Void, onNodeRemoveRequest:VariantPath->Void, variantRef:Variant) 
    {
        super();
        
        var parentPath:VariantPath = path.parent();
        var contextSituation:Situation = variantRef.getSituationByPath(parentPath);
        var plyNum:Int = variantRef.startingSituation.turnColor == White? path.length : path.length + 1;

        text = plyNum + ". " + ply.toNotation(contextSituation, false);
        customStyle = DEFAULT_STYLE;
        onClick = e -> {
            if (e.ctrlKey)
                onNodeSelectRequest(this.path);
            else
                onNodeRemoveRequest(this.path);
        }

        set_path(path);
    }
}

typedef NodeInfo = {node:PlyNode, index:Int, ?rbraceIndex:Null<Int>};

enum Item
{
    LBrace(label:Label);
    RBrace(label:Label, ownerInfo:NodeInfo);
    Node(info:NodeInfo);
}

class VariantPlainText extends HBox implements IVariantView
{
    private var variantRef:Variant;
    private var selectedBranch:VariantPath = [];
    private var selectedNode:Null<PlyNode> = null;

    private var eventHandler:PeripheralEvent->Void;

    private var nodeByCode:Map<String, NodeInfo> = [];
    private var items:Array<Item> = [];

    public function init(eventHandler:PeripheralEvent->Void)
    {
        this.eventHandler = eventHandler;
    }

    private function selectBranchUnsafe(fullBranch:VariantPath, selectUpToMove:Int)
    {
        #if debug
        if (fullBranch.code() != variantRef.extendPathLeftmost(fullBranch).code())
            throw "fullBranch isn't really full";
        #end
        
        selectedNode.selected = false;

        selectedBranch = fullBranch.copy();

        if (selectUpToMove == 0)
            selectedNode = null;
        else
        {
            var selectedCode:String = fullBranch.subpath(selectUpToMove).code();
            selectedNode = nodeByCode.get(selectedCode).node;
            selectedNode.selected = true;
        }

    }

    private function onNodeSelectRequest(path:VariantPath)
    {
        var extendedPath:VariantPath;
        if (selectedBranch.contains(path))
            extendedPath = selectedBranch;
        else
            extendedPath = variantRef.extendPathLeftmost(path);

        var branch = variantRef.getBranchByPath(extendedPath);
        var branchStr = variantRef.getBranchNotationByPath(extendedPath);
        var pointer = path.length;

        selectBranchUnsafe(extendedPath, path.length);
        eventHandler(BranchSelected(branch, branchStr, pointer));
    }

    private function asComponent(item:Item):Component
    {
        return switch item 
        {
            case LBrace(label): label;
            case RBrace(label, _): label;
            case Node(info): info.node;
        };
    }

    public function clear(?newStartingSituation:Situation)
    {
        removeAllComponents();

        variantRef.clear(newStartingSituation);

        if (variantRef.startingSituation.turnColor == Black)
            addComponent(label("..."));

        selectedBranch = [];
        selectedNode = null;

        nodeByCode = [];
        items = [];
    }

    private function updateIndexes(start:Int)
    {
        for (i in start...items.length)
            switch items[i] 
            {
                case Node(info):
                    info.index = i;
                case RBrace(_, ownerInfo):
                    ownerInfo.rbraceIndex = i;
                default:
            }
    }

    private function insertNode(info:NodeInfo, at:Int, ?hasBraces:Bool = false) 
    {
        var shift:Int = variantRef.startingSituation.turnColor == White? 0 : 1;
        
        if (hasBraces)
        {
            var lbrace:Label = label("(");
            var rbrace:Label = label(")");

            info.index = at + 1;
            info.rbraceIndex = at + 2;

            addComponentAt(lbrace, shift + at);
            addComponentAt(info.node, shift + at + 1);
            addComponentAt(rbrace, shift + at + 2);

            items.insert(at, LBrace(lbrace));
            items.insert(at + 1, Node(info));
            items.insert(at + 2, RBrace(rbrace, info));

            updateIndexes(at + 3);
        }
        else
        {
            info.index = at;
            addComponentAt(info.node, shift + at);
            items.insert(at, Node(info));
            updateIndexes(at + 1);
        }
    }

    public function addChildNode(parentPath:VariantPath, ply:Ply, selectChild:Bool)
    {
        var nodeNum:Int = variantRef.childCount(parentPath);
        var nodePath:VariantPath = parentPath.child(nodeNum);
        var nodeCode:String = nodePath.code();

        var node:PlyNode = new PlyNode(nodePath, ply, onNodeSelectRequest, removeNode, variantRef);
        var nodeInfo:NodeInfo = {node: node, index: -1};
        nodeByCode.set(nodeCode, nodeInfo);

        if (nodeNum > 0)
        {
            var leftSiblingCode:String = nodePath.parent().child(nodeNum - 1).code();
            var leftSiblingInfo:NodeInfo = nodeByCode.get(leftSiblingCode);

            if (leftSiblingInfo.rbraceIndex != null)
                insertNode(nodeInfo, leftSiblingInfo.rbraceIndex + 1, true);
            else
                insertNode(nodeInfo, leftSiblingInfo.index + 1, true);
        }
        else if (nodeCode == "0")
            insertNode(nodeInfo, 0);
        else
        {
            var parentIndex:Int = nodeByCode.get(parentPath.code()).index;
            insertNode(nodeInfo, parentIndex + 1);
        }

        variantRef.addChildToNode(ply, parentPath);

        if (selectChild)
            selectBranchUnsafe(nodePath, nodePath.length);
    }

    public function addChildToSelectedNode(ply:Ply, selectChild:Bool)
    {
        addChildNode(selectedNode.path, ply, selectChild);
    }

    public function removeNode(path:VariantPath)
    {
        if (Lambda.empty(path))
            throw "Cannot remove root";

        var nodeInfo:NodeInfo = nodeByCode.get(path.code());
        var removedItems:Array<Item> = [];

        if (nodeInfo.rbraceIndex != null)
            removedItems = items.splice(nodeInfo.index - 1, nodeInfo.rbraceIndex - nodeInfo.index + 2);
        else
        {
            if (variantRef.childCount(path) > 0)
            {
                var firstbornPath:VariantPath = path.child(0);
                var maxChildPath:VariantPath = variantRef.getRightmostSiblingPath(variantRef.getLastMainLineDescendantPath(firstbornPath));

                var minChild:NodeInfo = nodeByCode.get(firstbornPath.code());
                var maxChild:NodeInfo = nodeByCode.get(maxChildPath.code());

                var minIndex:Int = minChild.rbraceIndex != null? minChild.index - 1 : minChild.index;
                var maxIndex:Int = maxChild.rbraceIndex != null? maxChild.rbraceIndex : maxChild.index;

                removedItems = items.splice(minIndex, maxIndex - minIndex + 1);
            }

            if (path.lastNodeNum() == 0)
            {
                var rightSiblingPath:VariantPath = path.parent().child(1);
                if (variantRef.pathExists(rightSiblingPath))
                {
                    var rightSiblingInfo:NodeInfo = nodeByCode.get(rightSiblingPath.code());
                    if (rightSiblingInfo.rbraceIndex != null)
                    {
                        removedItems = removedItems.concat(items.splice(rightSiblingInfo.rbraceIndex, 1));
                        removedItems = removedItems.concat(items.splice(rightSiblingInfo.index - 1, 1));
                    }
                }
            }

            removedItems = removedItems.concat(items.splice(nodeInfo.index, 1));
        }

        for (item in removedItems)
            removeComponent(asComponent(item));

        updateIndexes(nodeInfo.index - 1);

        var newMap:Map<String, NodeInfo> = nodeByCode.copy();

        var rightSiblingsPaths = variantRef.getRightSiblingsPaths(path, false);
        for (rsPath in rightSiblingsPaths)
            for (oldPath in variantRef.getFamilyPaths(rsPath))
            {
                var remappedMember:NodeInfo = nodeByCode.get(oldPath.code());
                var newPath:VariantPath = oldPath.copy();
                newPath.asArray()[path.length - 1]--;
                remappedMember.node.path = newPath;
                newMap.set(newPath.code(), remappedMember);
            }

        nodeByCode = newMap;

        if (selectedBranch.contains(path))
            selectedBranch.asArray()[path.length - 1]--;
    }

    public function handlePlyScrolling(type:PlyScrollType)
    {
        var plyNumber:Int = switch type 
        {
            case Home: 0;
            case Prev: MathUtils.maxInt(selectedNode.path.length - 1, 0);
            case Next: MathUtils.minInt(selectedNode.path.length + 1, selectedBranch.length);
            case End: selectedBranch.length;
            case Precise(plyNum): plyNum;
        }
        selectBranchUnsafe(selectedBranch, plyNumber);
    }

    public function new(variant:Variant, ?selectedNodePath:VariantPath)
    {
        super();
        this.variantRef = variant;
        this.percentWidth = 100;
        this.continuous = true;

        if (variantRef.startingSituation.turnColor == Black)
            addComponent(label("..."));
    }

    private function label(text:String):Label
    {
        var b:Label = new Label();
        b.text = text;
        b.customStyle = DEFAULT_STYLE;
        return b;
    }
}