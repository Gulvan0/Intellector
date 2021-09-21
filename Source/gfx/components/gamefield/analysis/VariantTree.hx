package gfx.components.gamefield.analysis;

import haxe.ui.components.Link;
import openfl.geom.Point;
import struct.Variant;
import openfl.display.Sprite;

class VariantTree extends Sprite 
{
    private static var BLOCK_INTERVAL_X:Float = 15;
    private static var BLOCK_INTERVAL_Y:Float = 30;
    private static var ARROW_THICKNESS:Float = 2;
    private static var ARROW_TRIANGLE_SIDE:Float = 12;
    private static var STRAIGHT_ARROW_SEGMENT_SIZE:Float = 5;

    private var onClick:(nodeCode:String)->Void;

    private inline function rotatedPoint(p:Point, angle:Float):Point
    {
        return new Point(Math.cos(angle) * p.x - Math.sin(angle) * p.y, Math.cos(angle) * p.y + Math.sin(angle) * p.x);
    }

    private function drawArrow(from:Point, to:Point) 
    {
        var vertex1:Point = rotatedPoint(new Point(0, -ARROW_TRIANGLE_SIDE), - Math.PI / 8).add(to);
        var vertex2:Point = rotatedPoint(new Point(0, -ARROW_TRIANGLE_SIDE), Math.PI / 8).add(to);
        var upperSideVector = vertex2.subtract(vertex1);
        upperSideVector.normalize(upperSideVector.length / 2);
        var inputVertex:Point = vertex1.add(upperSideVector);
        var fracturePoint:Point = inputVertex.subtract(new Point(0, STRAIGHT_ARROW_SEGMENT_SIZE));

        var arrow:Sprite = new Sprite();
        arrow.graphics.lineStyle(ARROW_THICKNESS, 0x333333);
        arrow.graphics.moveTo(from.x, from.y);
        arrow.graphics.lineTo(fracturePoint.x, fracturePoint.y);
        arrow.graphics.lineTo(inputVertex.x, inputVertex.y);

        var triangle:Sprite = new Sprite();
        triangle.graphics.beginFill(0x333333);
        triangle.graphics.moveTo(inputVertex.x, inputVertex.y);
        triangle.graphics.lineTo(vertex1.x, vertex1.y);
        triangle.graphics.lineTo(to.x, to.y);
        triangle.graphics.lineTo(vertex2.x, vertex2.y);
        triangle.graphics.lineTo(inputVertex.x, inputVertex.y);
        triangle.graphics.endFill();

        arrow.addChild(triangle);
        addChild(arrow);
    }

    private function drawChildrenRecursive(parent:VariantNode, parentCode:String, parentCenterX:Float, parentBottomY:Float):Float
    {
        var accumulatedWidth:Float = 0;
        var childNum:Int = 0;
        var firstChildWidth:Float = -1;

        for (child in parent.children)
        {
            var childCode:String = parentCode + childNum;

            var link:Link = new Link();
            link.text = child.plyStr;
            link.onClick = (e) -> {onClick(childCode);};
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

            drawArrow(new Point(parentCenterX, parentBottomY), new Point(link.x + link.width/2, link.y));

            var descendantsWidth:Float = drawChildrenRecursive(child, childCode, link.x + link.width/2, link.y + link.height + 5);

            accumulatedWidth += Math.max(link.width, descendantsWidth) + BLOCK_INTERVAL_X;
            childNum++;
        }

        return accumulatedWidth;
    }

    public function init(variant:Variant) 
    {
        removeChildren();
        drawChildrenRecursive(variant, "", 0, 0);
    }

    public function new(onClick:(nodeCode:String)->Void) 
    {
        super();
        this.onClick = onClick;
    }
}