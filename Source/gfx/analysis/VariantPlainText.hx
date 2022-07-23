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
        verticalAlign = 'center';
        customStyle = DEFAULT_STYLE;
        onClick = e -> {
            if (e.ctrlKey)
                onNodeRemoveRequest(this.path);
            else
                onNodeSelectRequest(this.path);
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
        
        if (selectedNode != null)
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

    /**
        Prevents the occurence of the lone brackets due to the line break by combining each of them with the nearest node into a single (non-continuous) HBox.
        May only be called once. Breaks the connection between the child components and `items` array until the `unpack()` method is called.
        Relevant only for the actual modification of the variant: `addChildNode()`, `removeNode()`
    **/
    private function pack()
    {
        #if debug
        trace("Before pack(): ");
        for (child in childComponents)
            if (Std.isOfType(child, HBox))
            {
                trace("HBox [");
                for (c in cast(child, HBox).childComponents)
                    if (Std.isOfType(c, PlyNode))
                        trace('PlyNode: ${cast(c, PlyNode).text}');
                    else if (Std.isOfType(c, Label))
                        trace('Label: ${cast(c, Label).text}');
                    else
                        trace('Unknown: ${Type.getClassName(Type.getClass(c))}');
                trace("]");
            }
            else if (Std.isOfType(child, PlyNode))
                trace('PlyNode: ${cast(child, PlyNode).text}');
            else if (Std.isOfType(child, Label))
                trace('Label: ${cast(child, Label).text}');
            else
                trace('Unknown: ${Type.getClassName(Type.getClass(child))}');
        trace("-------");
        #end

        var itemsIndex:Int = 0;
        var childIndex:Int = variantRef.startingSituation.turnColor == White? 0 : 1;
        
        var itemsLength:Int = items.length;

        var lastHBox:HBox = null;
        var lastNode:PlyNode = null;
        var rbracesLabelText:String = "";

        while (itemsIndex <= itemsLength)
        {
            var currentItem:Item = items[itemsIndex];

            if (rbracesLabelText != "" && (itemsIndex == itemsLength || !currentItem.match(RBrace(_, _))))
            {
                var combinedLabel:Label = label(rbracesLabelText);

                if (lastHBox != null)
                    lastHBox.addComponent(combinedLabel);
                else
                {
                    removeComponent(lastNode, false);

                    var hbox:HBox = new HBox();
                    hbox.verticalAlign = 'center';
                    hbox.customStyle = {horizontalSpacing: 0};
                    hbox.addComponent(lastNode);
                    hbox.addComponent(combinedLabel);
                    addComponentAt(hbox, childIndex - 1);
                    lastNode.validateComponentStyle();
                }

                rbracesLabelText = "";
            }

            if (itemsIndex == itemsLength)
                break;

            switch currentItem
            {
                case LBrace(label):
                    var braceOwner:Component = getComponentAt(childIndex + 1);

                    removeComponent(label, false);
                    removeComponent(braceOwner, false);

                    var hbox:HBox = new HBox();
                    hbox.verticalAlign = 'center';
                    hbox.customStyle = {horizontalSpacing: 0};
                    hbox.addComponent(label);
                    hbox.addComponent(braceOwner);
                    addComponentAt(hbox, childIndex);
                    braceOwner.validateComponentStyle();

                    lastHBox = hbox;
                    lastNode = null;

                    childIndex++;
                    itemsIndex += 2;
                case RBrace(label, ownerInfo):
                    removeComponent(label);
                    rbracesLabelText += ")";

                    itemsIndex++;
                case Node(info):
                    lastHBox = null;
                    lastNode = info.node;

                    childIndex++;
                    itemsIndex++;
            }
        }

        #if debug
        trace("After pack(): ");
        for (child in childComponents)
            if (Std.isOfType(child, HBox))
            {
                trace("HBox [");
                for (c in cast(child, HBox).childComponents)
                    if (Std.isOfType(c, PlyNode))
                        trace('PlyNode: ${cast(c, PlyNode).text}');
                    else if (Std.isOfType(c, Label))
                        trace('Label: ${cast(c, Label).text}');
                    else
                        trace('Unknown: ${Type.getClassName(Type.getClass(c))}');
                trace("]");
            }
            else if (Std.isOfType(child, PlyNode))
                trace('PlyNode: ${cast(child, PlyNode).text}');
            else if (Std.isOfType(child, Label))
                trace('Label: ${cast(child, Label).text}');
            else
                trace('Unknown: ${Type.getClassName(Type.getClass(child))}');
        trace("----------------------------");
        #end
    }

    /**
        Reverts the effect of the `pack()` call, restoring the connection between the `items` array and the child components of `this`
    **/
    private function unpack()
    {
        #if debug
        trace("Before unpack(): ");
        for (child in childComponents)
            if (Std.isOfType(child, HBox))
            {
                trace("HBox [");
                for (c in cast(child, HBox).childComponents)
                    if (Std.isOfType(c, PlyNode))
                        trace('PlyNode: ${cast(c, PlyNode).text}');
                    else if (Std.isOfType(c, Label))
                        trace('Label: ${cast(c, Label).text}');
                    else
                        trace('Unknown: ${Type.getClassName(Type.getClass(c))}');
                trace("]");
            }
            else if (Std.isOfType(child, PlyNode))
                trace('PlyNode: ${cast(child, PlyNode).text}');
            else if (Std.isOfType(child, Label))
                trace('Label: ${cast(child, Label).text}');
            else
                trace('Unknown: ${Type.getClassName(Type.getClass(child))}');
        trace("-------");
        #end

        var childIndex:Int = variantRef.startingSituation.turnColor == White? 0 : 1;

        while (childIndex < numChildren)
        {
            var child:Component = getComponentAt(childIndex);
            if (Std.isOfType(child, HBox))
            {
                var hbox:HBox = cast(child, HBox);
                var member:Component = hbox.getComponentAt(0);

                if (!Std.isOfType(member, PlyNode))
                {
                    hbox.removeComponent(member, false);
                    addComponentAt(member, childIndex);
                    childIndex++;
                    member = hbox.getComponentAt(0);
                }

                hbox.removeComponent(member, false);
                addComponentAt(member, childIndex);
                childIndex++;
                member = hbox.getComponentAt(0);

                if (member != null)
                {
                    var rbraceCnt:Int = cast(member, Label).text.length;
                    for (i in 0...rbraceCnt)
                    {
                        var label:Label = label(")");
                        var itemIndex:Int = variantRef.startingSituation.turnColor == White? childIndex : childIndex - 1;
                        switch items[itemIndex]
                        {
                            case RBrace(_, ownerInfo):
                                items[itemIndex] = RBrace(label, ownerInfo);
                            default:
                                throw "Expected RBrace";
                        }
                        addComponentAt(label, childIndex);
                        childIndex++;
                    }
                }

                removeComponent(hbox);
            }
            else
                childIndex++;
        }

        #if debug
        trace("After unpack(): ");
        for (child in childComponents)
            if (Std.isOfType(child, HBox))
            {
                trace("HBox [");
                for (c in cast(child, HBox).childComponents)
                    if (Std.isOfType(c, PlyNode))
                        trace('PlyNode: ${cast(c, PlyNode).text}');
                    else if (Std.isOfType(c, Label))
                        trace('Label: ${cast(c, Label).text}');
                    else
                        trace('Unknown: ${Type.getClassName(Type.getClass(c))}');
                trace("]");
            }
            else if (Std.isOfType(child, PlyNode))
                trace('PlyNode: ${cast(child, PlyNode).text}');
            else if (Std.isOfType(child, Label))
                trace('Label: ${cast(child, Label).text}');
            else
                trace('Unknown: ${Type.getClassName(Type.getClass(child))}');
        trace("--------------");
        #end
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
        unpack();

        var nodeNum:Int = variantRef.childCount(parentPath);
        var nodePath:VariantPath = parentPath.child(nodeNum);
        var nodeCode:String = nodePath.code();

        var node:PlyNode = new PlyNode(nodePath, ply, onNodeSelectRequest, removeNodeByPath, variantRef);
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
            var parentCode:String = parentPath.code();
            var yongestAuntCode:String = variantRef.getRightmostSiblingPath(parentPath).code();

            var insertAt:Int;
            if (yongestAuntCode != parentCode && parentPath.lastNodeNum() == 0)
                insertAt = nodeByCode.get(yongestAuntCode).rbraceIndex + 1;
            else
                insertAt = nodeByCode.get(parentCode).index + 1;

            insertNode(nodeInfo, insertAt);
        }

        variantRef.addChildToNode(ply, parentPath);

        if (selectChild)
            selectBranchUnsafe(nodePath, nodePath.length);

        pack();
    }

    public function addChildToSelectedNode(ply:Ply, selectChild:Bool)
    {
        var selectedPath:VariantPath = selectedNode == null? [] : selectedNode.path;
        addChildNode(selectedPath, ply, selectChild);
    }

    public function removeNodeByPath(path:VariantPath)
    {
        if (Lambda.empty(path))
            throw "Cannot remove root";

        unpack();

        var nodeInfo:NodeInfo = nodeByCode.get(path.code());
        var parentPath = path.parent();
        var totalSiblings = variantRef.childCount(parentPath);

        if (nodeInfo.rbraceIndex != null) //Just remove the whole variation if it is identified by the move requested to be removed
            for (item in items.splice(nodeInfo.index - 1, nodeInfo.rbraceIndex - nodeInfo.index + 2))
                removeComponent(asComponent(item));
        else
        {
            //Step 1. Remove all children (if any) of a node being removed
            if (variantRef.childCount(path) > 0)
            {
                var firstbornPath:VariantPath = path.child(0);
                var maxChildPath:VariantPath = variantRef.getRightmostSiblingPath(variantRef.getLastMainLineDescendantPath(firstbornPath));

                var minChild:NodeInfo = nodeByCode.get(firstbornPath.code());
                var maxChild:NodeInfo = nodeByCode.get(maxChildPath.code());

                var minIndex:Int = minChild.rbraceIndex != null? minChild.index - 1 : minChild.index;
                var maxIndex:Int = maxChild.rbraceIndex != null? maxChild.rbraceIndex : maxChild.index;

                for (item in items.splice(minIndex, maxIndex - minIndex + 1))
                    removeComponent(asComponent(item));
            }

            //If the node being removed is the main line and it has at least one alternative variation, the first of these variations will become the new main line.
            //    This means that we will need to remove the braces associated with this variation, ...
            if (path.lastNodeNum() == 0 && totalSiblings > 1)
            {
                var closestSiblingPath:VariantPath = parentPath.child(1);
                var closestSiblingInfo:NodeInfo = nodeByCode.get(closestSiblingPath.code());

                //...moreover, if there are more alt. variations than just one, after the first one becomes the main line, others may become wrongly placed.
                //    More precisely, this happens when the new main line consists of more than one move. The problem is that all the other alternative variations
                //    will follow the LAST move of the first line while we need them to be placed right after the FIRST move of it.
                if (totalSiblings > 2 && variantRef.childCount(closestSiblingPath) > 0)
                {
                    var firstRemainingSibling:NodeInfo = nodeByCode.get(parentPath.child(2).code());
                    var lastRemainingSibling:NodeInfo = nodeByCode.get(parentPath.child(totalSiblings - 1).code());

                    var shiftedPartStart:Int = firstRemainingSibling.index - 1;
                    var shiftedPartEnd:Int = lastRemainingSibling.rbraceIndex;

                    //Step 2. Remove the alternative variations for the node being removed 
                    //    except for the very first one (which will become the main line after the removal is done).
                    //    These variations will be attached to the first move of the new main line, so we keep them intact.

                    var shiftedPart:Array<Item> = items.splice(shiftedPartStart, shiftedPartEnd - shiftedPartStart + 1);
                    shiftedPart.reverse();

                    for (item in shiftedPart)
                        removeComponent(asComponent(item), false);

                    //Step 3. Remove the right brace of the new main line

                    for (item in items.splice(closestSiblingInfo.rbraceIndex, 1))
                        removeComponent(asComponent(item));

                    //Step 4. Insert the alternative variations after the first move of the new main line

                    var insertShiftedPartAt:Int = closestSiblingInfo.index + 1;
                    var componentInsertionPosition:Int = variantRef.startingSituation.turnColor == White? insertShiftedPartAt : insertShiftedPartAt + 1;

                    for (item in shiftedPart)
                    {
                        items.insert(insertShiftedPartAt, item);
                        addComponentAt(asComponent(item), componentInsertionPosition);
                    }

                    //Step 5. Remove the left brace of the new main line

                    for (item in items.splice(closestSiblingInfo.index - 1, 1))
                        removeComponent(asComponent(item));
                }
                else //Otherwise, if the new main line is the only alternative variation, things become much simpler
                {
                    //Step 2-5. Remove the right brace and then the left brace of the new main line 
                    for (item in items.splice(closestSiblingInfo.rbraceIndex, 1))
                        removeComponent(asComponent(item));
                    for (item in items.splice(closestSiblingInfo.index - 1, 1))
                        removeComponent(asComponent(item));
                }
            }

            //Step 6. Finally, remove the move requested to be removed
            for (item in items.splice(nodeInfo.index, 1))
                removeComponent(asComponent(item));
        }

        //Now, just update the indexes starting from where the move requested to be removed was (-1 is to account for the possible left brace)
        updateIndexes(MathUtils.maxInt(nodeInfo.index - 1, 0));

        //And also update the code-to-node (equivalently, path-to-node) mappings (affects nodeByCode and selectedBranch)

        var newMap:Map<String, NodeInfo> = nodeByCode.copy();
        var remapSelectedBranch:Bool = false;

        var rightSiblingsPaths = variantRef.getRightSiblingsPaths(path, false);
        for (rsPath in rightSiblingsPaths)
            for (oldPath in variantRef.getFamilyPaths(rsPath))
            {
                var remappedMember:NodeInfo = nodeByCode.get(oldPath.code());
                var newPath:VariantPath = oldPath.copy();
                newPath.asArray()[path.length - 1]--;
                remappedMember.node.path = newPath;
                newMap.set(newPath.code(), remappedMember);

                if (selectedBranch.equals(oldPath))
                    remapSelectedBranch = true;
            }

        nodeByCode = newMap;

        if (remapSelectedBranch)
            selectedBranch.asArray()[path.length - 1]--;

        //After all the visual work has been done, update the variant itself

        variantRef.removeNode(path);

        pack();
    }

    public function handlePlyScrolling(type:PlyScrollType)
    {
        var plyNumber:Int = switch type 
        {
            case Home: 0;
            case Prev: selectedNode == null? 0 : selectedNode.path.length - 1;
            case Next: selectedNode == null? 1 : MathUtils.minInt(selectedNode.path.length + 1, selectedBranch.length);
            case End: selectedBranch.length;
            case Precise(plyNum): plyNum;
        }
        selectBranchUnsafe(selectedBranch, plyNumber);
    }

    private function addRec(parentPath:VariantPath, childNum:Int, node:VariantNode)
    {
        addChildNode(parentPath, node.ply, false);
        for (i => child in node.children.keyValueIterator())
            addRec(parentPath.child(childNum), i, child);
    }

    public function new(variant:Variant, ?selectedNodePath:VariantPath)
    {
        super();
        this.variantRef = variant;
        this.percentWidth = 100;
        this.continuous = true;

        if (variantRef.startingSituation.turnColor == Black)
            addComponent(label("..."));

        for (i => child in variantRef.children.keyValueIterator())
            addRec([], i, child);

        if (selectedNodePath != null)
            selectBranchUnsafe(variantRef.extendPathLeftmost(selectedNodePath), selectedNodePath.length);
        else
            selectBranchUnsafe(variantRef.extendPathLeftmost([]), 0);
    }

    private function label(text:String):Label
    {
        var b:Label = new Label();
        b.text = text;
        b.verticalAlign = 'center';
        b.customStyle = DEFAULT_STYLE;
        return b;
    }
}