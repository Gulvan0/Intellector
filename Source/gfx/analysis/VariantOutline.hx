package gfx.analysis;

import haxe.Timer;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import haxe.ui.containers.TreeViewNode;
import struct.Variant;
import struct.Situation;
import struct.Variant.VariantPath;
import struct.Ply;
import gfx.utils.PlyScrollType;
import haxe.ui.containers.TreeView;

class VariantOutline extends TreeView implements IVariantView 
{
    private var variantRef:Variant;
    private var rootNode:TreeViewNode;

    private var eventHandler:PeripheralEvent->Void;

    private var selectedBranch:VariantPath = [];
    private var selectedMove:Int = 0;

    private function addRec(parentTreeNode:TreeViewNode, node:VariantNode)
    {
        var childNode = addChildToSpecificNode(parentTreeNode, node.ply, false);
        for (child in node.children)
            addRec(childNode, child);
    }

    public function new(variant:Variant, ?selectedNodePath:VariantPath)
    {
        super();
        this.variantRef = variant;
        this.percentWidth = 100;
        this.percentHeight = 100;

        rootNode = addNode({text: Dictionary.getPhrase(OPENING_STARTING_POSITION), code: ""});
        rootNode.onClick = e -> {Timer.delay(onNodeChanged.bind(rootNode), 50);};

        for (i => child in variantRef.children.keyValueIterator())
            addRec(rootNode, child);

        if (selectedNodePath != null)
            selectBranchUnsafe(variantRef.extendPathLeftmost(selectedNodePath), selectedNodePath.length);
        else
            selectBranchUnsafe(variantRef.extendPathLeftmost([]), 0);
    }

    private function selectBranchUnsafe(fullBranch:VariantPath, selectUpToMove:Int)
    {
        selectedBranch = fullBranch.copy();
        selectedMove = selectUpToMove;

        if (selectUpToMove > 0)
        {
            var selectedPathStr:String = fullBranch.subpath(selectUpToMove).asArray().join('/');
            rootNode.findNodeByPath(selectedPathStr).selected = true;
        }
        else 
            rootNode.selected = true;
    }

    public function init(eventHandler:PeripheralEvent -> Void) 
    {
        this.eventHandler = eventHandler;
    }

    public function clear(?newStartingSituation:Situation) 
    {
        rootNode.clearNodes();
        variantRef.clear(newStartingSituation);
    }

    private function addChildToSpecificNode(parentNode:TreeViewNode, ply:Ply, selectChild:Bool):TreeViewNode
    {
        parentNode.expanded = true;

        var parentPath:VariantPath = VariantPath.fromCode(parentNode.data.code);
        var contextSituation:Situation = variantRef.getSituationByPath(parentPath);
        var plyNum:Int = variantRef.startingSituation.turnColor == White? parentPath.length + 1: parentPath.length + 2;
        var text:String = plyNum + ". " + ply.toNotation(contextSituation, false);
        var childNum:Int = variantRef.childCount(parentPath);
        var childPath:VariantPath = parentPath.child(childNum);

        var childNode:TreeViewNode = parentNode.addNode({text: text, code: childPath.code(), nodeId: '$childNum'});
        childNode.onClick = onNodeClicked.bind(childNode);

        if (selectChild)
            selectBranchUnsafe(childPath, childPath.length);

        variantRef.addChildToNode(ply, parentPath);

        return childNode;
    }

    public function addChildNode(parentPath:VariantPath, ply:Ply, selectChild:Bool) 
    {
        addChildToSpecificNode(rootNode.findNodeByPath(parentPath.asArray().join('/')), ply, selectChild);
    }

    public function addChildToSelectedNode(ply:Ply, selectChild:Bool) 
    {
        addChildToSpecificNode(selectedNode == null? rootNode : selectedNode, ply, selectChild);
    }

    private function onNodeChanged(treeNode:TreeViewNode)
    {
        var nodePath:VariantPath = VariantPath.fromCode(treeNode.data.code);
        if (treeNode.selected)
        {
            if (!selectedBranch.contains(nodePath))
                selectBranchUnsafe(variantRef.extendPathLeftmost(nodePath), nodePath.length);

            var branch:Array<Ply> = variantRef.getBranchByPath(selectedBranch);
            var branchStr:Array<String> = variantRef.getBranchNotationByPath(selectedBranch);
            var pointer:Int = nodePath.length;
            eventHandler(BranchSelected(branch, branchStr, pointer));
        }
    }

    private var stopClickCapture:Bool = false;

    private function onNodeClicked(treeNode:TreeViewNode, e:MouseEvent)
    {
        if (stopClickCapture)
            return;

        stopClickCapture = true;

        if (e.ctrlKey)
            removeSpecificNode(treeNode);
        else
            Timer.delay(onNodeChanged.bind(treeNode), 50);

        Timer.delay(() -> {stopClickCapture = false;}, 20);
    }

    public function removeNodeByPath(path:VariantPath)
    {
        removeSpecificNode(rootNode.findNodeByPath(path.asArray().join('/')));
    }
    
    private function removeSpecificNode(treeNode:TreeViewNode)
    {
        var nodePath:VariantPath = VariantPath.fromCode(treeNode.data.code);

        selectBranchUnsafe(selectedBranch, selectedMove); //Since haxeui always selects the clicked node

        if (selectedBranch.contains(nodePath))
        {
            selectBranchUnsafe(nodePath.parent(), nodePath.length);

            var branch:Array<Ply> = variantRef.getBranchByPath(selectedBranch);
            var branchStr:Array<String> = variantRef.getBranchNotationByPath(selectedBranch);
            var pointer:Int = selectedBranch.length;
            eventHandler(BranchSelected(branch, branchStr, pointer));
        }
        
        treeNode.parentNode.removeNode(treeNode);

        var nodesToRemap:Array<TreeViewNode> = [];
        var remapSelectedBranch:Bool = false;

        var rightSiblingsPaths = variantRef.getRightSiblingsPaths(nodePath, false);
        for (rsPath in rightSiblingsPaths)
            for (oldPath in variantRef.getFamilyPaths(rsPath))
            {
                nodesToRemap.push(rootNode.findNodeByPath(oldPath.asArray().join('/')));

                if (selectedBranch.equals(oldPath))
                    remapSelectedBranch = true;
            }

        for (node in nodesToRemap)
        {
            var newPath:VariantPath = VariantPath.fromCode(node.data.code);
            newPath.asArray()[nodePath.length - 1]--;
            node.data.code = newPath.code();
            if (newPath.length == nodePath.length)
                node.data.nodeId = '${newPath.lastNodeNum()}';
        }

        if (remapSelectedBranch)
            selectedBranch.asArray()[nodePath.length - 1]--;

        variantRef.removeNode(nodePath);
    }

    public function handlePlyScrolling(type:PlyScrollType) 
    {
        switch type 
        {
            case Home:
                selectBranchUnsafe(selectedBranch, 0);
            case Prev:
                if (selectedMove > 0)
                    selectBranchUnsafe(selectedBranch, selectedMove - 1);
            case Next:
                if (selectedMove < selectedBranch.length)
                    selectBranchUnsafe(selectedBranch, selectedMove + 1);
            case End:
                selectBranchUnsafe(selectedBranch, selectedBranch.length);
            case Precise(plyNum):
                selectBranchUnsafe(selectedBranch, plyNum);
        }
    }
}