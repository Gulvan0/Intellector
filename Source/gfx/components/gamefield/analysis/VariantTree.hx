package gfx.components.gamefield.analysis;

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

    public var selectedBranch(default, null):Array<Int> = [];

    private var onClick:(nodeCode:Array<Int>)->Void;
    private var onCtrlClick:(nodeCode:Array<Int>)->Void;

    private function deselectAll() 
    {
        var code:String = "";
        for (childNum in selectedBranch)
        {
            code += childNum;
            arrows[code].unhighlight();
            code += ":";
        }
        selectedBranch = [];
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
        selectedBranch = branch.copy();
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
            newArrowMap.set(newCode, arrows.get(formerCode));
            newNodeMap.set(newCode, nodes.get(formerCode));
            newFamilyWidths.set(newCode, familyWidths.get(formerCode));
        }

        arrows = newArrowMap;
        nodes = newNodeMap;
        familyWidths = newFamilyWidths;
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

        //Remove nodes and arrows with children and also their mappings
        for (familyMemberPath in referenceVariant.getFamilyPaths(path))
        {
            var code:String = familyMemberPath.join(":");
            removeChild(arrows.get(code));
            removeChild(nodes.get(code));
            arrows.remove(code);
            nodes.remove(code);
            familyWidths.remove(code);
        }

        //Update upstream parents' family widths and store deltas for the next step
        var childCode:String = path.join(":");
        var parentPath:Array<Int> = Variant.parentPath(path);
        var childDeltaWidth = familyWidths.get(childCode);
        var deltaWidthsByDepth:Map<Int, Float> = [path.length => childDeltaWidth];
        while (parentPath.length > 1)
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
                var deltaWidth = deltaWidthsByDepth[path.length];
                nodes[code].x -= deltaWidth;
                arrows[code].changeDestination(new Point(arrows[code].to.x - deltaWidth, arrows[code].to.y));
            }
        }

        //Apply queued code remappings
        remapKeys(renames);
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

        var offset:Float = 0;
        for (i in 0...nodeNum)
            offset += familyWidths[parentPath.concat([i]).join(":")];
        var leftX:Float = offset + (parentNode == null? 0 : parentNode.x);

        createNodeNaive(nodePath, nodeCode, nodeText, parentCenterX, parentBottomY, selected, leftX);
        familyWidths.set(nodeCode, nodes.get(nodeCode).width + BLOCK_INTERVAL_X);

        //Update upstream parents' family widths and store deltas for the next step
        var upParentPath = parentPath.copy();
        var childDeltaWidth = Math.max(0, offset + familyWidths.get(nodeCode) - familyWidths.get(upParentPath.join(":")));
        var deltaWidthsByDepth:Map<Int, Float> = [];
        while (upParentPath.length > 0)
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
            upParentPath.pop();
        }

        //Move upstream parent right siblings with their families
        var upstreamParents:Array<Array<Int>> = referenceVariant.upstreamParentsPaths(parentPath, true);
        var rightSiblings:Array<Array<Int>> = [];
        for (upParentPath in upstreamParents)
            rightSiblings = rightSiblings.concat(referenceVariant.getRightSiblingsPaths(upParentPath, false));

        for (siblingPath in rightSiblings)
        {
            var siblingFamilyPaths:Array<Array<Int>> = referenceVariant.getFamilyPaths(siblingPath);

            for (path in siblingFamilyPaths)
            {
                if (!deltaWidthsByDepth.exists(path.length))
                    continue;
                var code = path.join(":");
                var deltaWidth = deltaWidthsByDepth[siblingPath.length];
                nodes[code].x += deltaWidth;
                arrows[code].changeDestination(new Point(arrows[code].to.x + deltaWidth, arrows[code].to.y));
            }
        }
        trace(familyWidths);
    }

    private function createNodeNaive(path:Array<Int>, code:String, nodeText:String, parentCenterX:Float, parentBottomY:Float, selected:Bool, leftX:Float)
    {
        var link:Link = new Link();
        link.text = nodeText;
        link.onClick = (e) -> {
            if (e.ctrlKey)
                onCtrlClick(path);
            else
                onClick(path);
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
                    onCtrlClick(childPath);
                else
                    onClick(childPath);
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

    public function init(variant:Variant, nodeTexts:Map<String, String>) 
    {
        removeChildren();
        arrows = [];
        nodes = [];
        familyWidths = [];
        selectedBranch = [];
        drawChildrenRecursive(variant, [], 0, 0, nodeTexts);
    }

    public function new(onClick:(nodeCode:Array<Int>)->Void, onCtrlClick:(nodeCode:Array<Int>)->Void) 
    {
        super();
        this.onClick = onClick;
        this.onCtrlClick = onCtrlClick;
    }
}