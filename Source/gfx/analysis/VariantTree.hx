package gfx.analysis;

import haxe.ui.components.Link;
import openfl.geom.Point;
import struct.Variant;
import openfl.display.Sprite;

class VariantTree extends Sprite 
{
    private static var BLOCK_INTERVAL_X:Float = 15;
    private static var BLOCK_INTERVAL_Y:Float = 30;

    private var arrows:Map<String, Arrow> = [];
    private var nodes:Map<String, Link> = [];
    private var familyWidths:Map<String, Float> = [];

    private var onBranchSelect:(nodeCode:Array<Int>)->Void;
    private var onBranchRemove:(nodeCode:Array<Int>)->Void;

    private function deselectAll() 
    {
        var code:String = "";
        for (childNum in selectedBranch)
        {
            code += childNum;
            arrows[code].unhighlight();
            code += ":";
        }
    }

    public function clear()
    {
        for (arrow in arrows)
            removeChild(arrow);
        for (node in nodes)
            removeChild(node);
        arrows = [];
        nodes = [];
        familyWidths = [];
    }

    public function selectBranch(branch:Array<Int>)
    {
        deselectAll();

        var code:String = "";
        for (childNum in branch)
        {
            code += childNum;
            arrows[code].highlight();
            code += ":";
        }
    }

    private function remapKeys(renames:Map<String, String>)
    {
        var newArrowMap:Map<String, Arrow> = arrows.copy();
        var newNodeMap:Map<String, Link> = nodes.copy();
        var newFamilyWidths:Map<String, Float> = familyWidths.copy();

        for (formerCode => newCode in renames.keyValueIterator())
        {
            if (!Lambda.has(renames, formerCode))
            {
                newArrowMap.remove(formerCode);
                newNodeMap.remove(formerCode);
                newFamilyWidths.remove(formerCode);
            }

            var path = newCode.split(":").map(Std.parseInt);
            var node = nodes.get(formerCode);
            node.onClick = (e) -> {
                if (e.ctrlKey)
                    onBranchRemove(path);
                else
                    onBranchSelect(path);
            }

            newArrowMap.set(newCode, arrows.get(formerCode));
            newNodeMap.set(newCode, node);
            newFamilyWidths.set(newCode, familyWidths.get(formerCode));
        }

        arrows = newArrowMap;
        nodes = newNodeMap;
        familyWidths = newFamilyWidths;

        var newSelected = renames[selectedBranch.join(":")];
        if (newSelected != null)
            selectedBranch = newSelected.split(":").map(Std.parseInt);
    }

    /**Reference variant should be passed BEFORE any corrections to it**/
    public function removeNode(path:Array<Int>, referenceVariant:Variant)
    {
        var parentPath:Array<Int> = path.slice(0, -1);
        var renames:Map<String, String> = [];

        var changedCodeNodes = [];
        for (rsPath in referenceVariant.getRightSiblingsPaths(path, false))
            changedCodeNodes = changedCodeNodes.concat(referenceVariant.getFamilyPaths(rsPath));

        //Queue right siblings with their families for updating their codes
        for (oldPath in changedCodeNodes)
        {
            var newSiblingNum = oldPath[path.length - 1] - 1;
            var pathToChildResidue = oldPath.slice(path.length);
            var newPath:Array<Int> = parentPath.concat([newSiblingNum]).concat(pathToChildResidue);
            renames.set(oldPath.join(":"), newPath.join(":"));
        }

        var removedNodeCodes = [];

        //Remove nodes and arrows with children and also their mappings
        for (familyMemberPath in referenceVariant.getFamilyPaths(path))
        {
            var code:String = familyMemberPath.join(":");
            removedNodeCodes.push(code);
            removeChild(arrows.get(code));
            removeChild(nodes.get(code));
            arrows.remove(code);
            nodes.remove(code);
        }

        trace("famWidths before update: " + familyWidths);

        //Update upstream parents' family widths and store deltas for the next step
        var childCode:String = path.join(":");
        var parentPath:Array<Int> = Variant.parentPath(path);
        var childDeltaWidth = familyWidths.get(childCode);
        var deltaWidthsByDepth:Map<Int, Float> = [path.length => childDeltaWidth];
        while (parentPath.length >= 1)
        {
            var parentCode = parentPath.join(":");
            var parentFamWidth = familyWidths.get(parentCode);
            var parentOwnWidth = nodes.get(parentCode).width + BLOCK_INTERVAL_X;

            if (parentOwnWidth == parentFamWidth)
                break;

            var newParentFamWidth = Math.max(parentOwnWidth, parentFamWidth - childDeltaWidth);
            familyWidths.set(parentCode, newParentFamWidth);
            childDeltaWidth = parentFamWidth - newParentFamWidth;
            deltaWidthsByDepth.set(parentPath.length, childDeltaWidth);
            parentPath.pop();
        }
        trace("famWidths after update: " + familyWidths);
        trace("deltas: " + deltaWidthsByDepth);
        
        //Move upstream parent right siblings with their families
        var upstreamParents:Array<Array<Int>> = referenceVariant.upstreamParentsPaths(path, true);
        var rightSiblings:Array<Array<Int>> = [];
        for (parentPath in upstreamParents)
            rightSiblings = rightSiblings.concat(referenceVariant.getRightSiblingsPaths(parentPath, false));

        for (siblingPath in rightSiblings)
        {
            var siblingFamilyPaths:Array<Array<Int>> = referenceVariant.getFamilyPaths(siblingPath);

            for (path in siblingFamilyPaths)
            {
                var code = path.join(":");
                var deltaWidth = deltaWidthsByDepth[siblingPath.length];
                nodes[code].x -= deltaWidth;
                if (!Variant.equalPaths(path, siblingPath))
                    arrows[code].changeDeparture(new Point(arrows[code].from.x - deltaWidth, arrows[code].from.y));
                arrows[code].changeDestination(new Point(arrows[code].to.x - deltaWidth, arrows[code].to.y));
            }
        }

        for (code in removedNodeCodes)
            if (!Lambda.has(renames, code))
                familyWidths.remove(code);

        //Apply queued code remappings
        remapKeys(renames);

        trace("famWidths after erasure and remapping: " + familyWidths);
    }

    /**Reference variant should be passed BEFORE any corrections to it**/
    public function addChildNode(parentPath:Array<Int>, nodeText:String, selected:Bool, referenceVariant:Variant)
    {
        trace('add child node: $nodeText');
        var nodeNum:Int = referenceVariant.childCount(parentPath);

        if (selected)
        {
            if (parentPath.join(":") != selectedBranch.join(":"))
                selectBranch(parentPath);
            selectedBranch.push(nodeNum);
        }

        //Draw node and arrow and add their mappings
        var nodePath:Array<Int> = parentPath.concat([nodeNum]);
        var nodeCode:String = nodePath.join(":");

        var parentCode:String = parentPath.join(":");
        var parentNode:Link = nodes.get(parentCode);
        var parentCenterX:Float = parentNode == null? 0 : parentNode.x + parentNode.width / 2;
        var parentBottomY:Float = parentNode == null? 0 : parentNode.y + parentNode.height + 5;

        var leftX:Float;
        if (nodeNum > 0)
        {
            var leftSiblingCode = parentPath.concat([nodeNum - 1]).join(":");
            leftX = familyWidths[leftSiblingCode] + nodes[leftSiblingCode].x;
        }
        else if (parentNode != null)
            leftX = parentNode.x;
        else
            leftX = 0;

        createNodeNaive(nodePath, nodeCode, nodeText, parentCenterX, parentBottomY, selected, leftX);
        familyWidths.set(nodeCode, nodes.get(nodeCode).width + BLOCK_INTERVAL_X);

        var totalChildrenWidth:Float = familyWidths.get(nodeCode);
        for (i in 0...nodeNum)
            totalChildrenWidth += familyWidths.get(parentPath.concat([i]).join(":"));

        //Update upstream parents' family widths and store deltas for the next step
        var upstreamParents:Array<Array<Int>> = Lambda.empty(parentPath)? [] : referenceVariant.upstreamParentsPaths(parentPath, true);
        var childDeltaWidth = Math.max(0, totalChildrenWidth - familyWidths.get(parentPath.join(":")));
        var deltaWidthsByDepth:Map<Int, Float> = [];
        for (upParentPath in upstreamParents)
        {
            var parentCode = upParentPath.join(":");
            var parentFamWidth = familyWidths.get(parentCode);
            var parentOwnWidth = nodes.get(parentCode).width + BLOCK_INTERVAL_X;
            var newParentFamWidth = Math.max(parentOwnWidth, parentFamWidth + childDeltaWidth);

            if (newParentFamWidth == parentFamWidth)
                break;

            familyWidths.set(parentCode, newParentFamWidth);
            childDeltaWidth = newParentFamWidth - parentFamWidth;
            deltaWidthsByDepth.set(upParentPath.length, childDeltaWidth);
        }

        //Move upstream parent right siblings with their families
        var rightSiblings:Array<Array<Int>> = [];
        for (upParentPath in upstreamParents)
            rightSiblings = rightSiblings.concat(referenceVariant.getRightSiblingsPaths(upParentPath, false));

        for (siblingPath in rightSiblings)
        {
            if (!deltaWidthsByDepth.exists(siblingPath.length))
                continue;

            var siblingFamilyPaths:Array<Array<Int>> = referenceVariant.getFamilyPaths(siblingPath);

            for (path in siblingFamilyPaths)
            {
                var code = path.join(":");
                var deltaWidth = deltaWidthsByDepth[siblingPath.length];
                nodes[code].x += deltaWidth;
                if (!Variant.equalPaths(path, siblingPath))
                    arrows[code].changeDeparture(new Point(arrows[code].from.x + deltaWidth, arrows[code].from.y));
                arrows[code].changeDestination(new Point(arrows[code].to.x + deltaWidth, arrows[code].to.y));
            }
        }
    }

    private function createNodeNaive(path:Array<Int>, code:String, nodeText:String, parentCenterX:Float, parentBottomY:Float, selected:Bool, leftX:Float)
    {
        var link:Link = new Link();
        link.text = nodeText;
        link.onClick = (e) -> {
            if (e.ctrlKey)
                onBranchRemove(path);
            else
                onBranchSelect(path);
        };
        nodes.set(code, link);
        addChild(link);
        link.validateNow();

        link.x = leftX;
        link.y = parentBottomY + BLOCK_INTERVAL_Y;

        trace('new node added at (${link.x}, ${link.y})');

        var arrow:Arrow = new Arrow(new Point(parentCenterX, parentBottomY), new Point(link.x + link.width/2, link.y), selected);
        arrows.set(code, arrow);
        addChild(arrow);
    }

    private function drawChildrenRecursive(parent:VariantNode, parentPath:Array<Int>, parentCenterX:Float, parentBottomY:Float, nodeTexts:Map<String, String>):Float
    {
        var accumulatedWidth:Float = 0;
        var childNum:Int = 0;
        var firstChildWidth:Float = -1;

        for (child in parent.children)
        {
            var childPath:Array<Int> = parentPath.concat([childNum]);
            var childCode:String = childPath.join(":");

            var link:Link = new Link();
            link.text = nodeTexts[childCode];
            link.onClick = (e) -> {
                if (e.ctrlKey)
                    onBranchRemove(childPath);
                else
                    onBranchSelect(childPath);
            };
            nodes.set(childCode, link);
            addChild(link);
            link.validateNow();

            if (childNum == 0)
            {
                link.x = parentCenterX - link.width / 2;
                firstChildWidth = link.width;
            }
            else 
                link.x = parentCenterX - firstChildWidth / 2 + accumulatedWidth;
            link.y = parentBottomY + BLOCK_INTERVAL_Y;

            var arrow:Arrow = new Arrow(new Point(parentCenterX, parentBottomY), new Point(link.x + link.width/2, link.y), false);
            arrows.set(childCode, arrow);
            addChild(arrow);

            var descendantsWidth:Float = drawChildrenRecursive(child, childPath, link.x + link.width/2, link.y + link.height + 5, nodeTexts);

            var familyWidth = Math.max(link.width, descendantsWidth) + BLOCK_INTERVAL_X;
            familyWidths.set(childCode, familyWidth);
            accumulatedWidth += familyWidth;
            childNum++;
        }

        return accumulatedWidth;
    }

    public function init(onBranchSelect:Array<Int>->Void, onBranchRemove:Array<Int>->Void) 
    {
        this.onBranchSelect = onBranchSelect;
        this.onBranchRemove = onBranchRemove;
    }

    public function new() 
    {
        super();
    }
}