package gfx.components.gamefield.analysis;

import openfl.display.Sprite;
import openfl.geom.Point;

class Arrow extends Sprite
{
    private static var ARROW_THICKNESS:Float = 2;
    private static var ARROW_TRIANGLE_SIDE:Float = 12;
    private static var STRAIGHT_ARROW_SEGMENT_SIZE:Float = 5;

    public var from(default, null):Point;
    public var to(default, null):Point;
    public var highlighted(default, null):Bool;
    private var arrow:Sprite;

    public function highlight() 
    {
        removeChild(arrow);
        this.highlighted = true;
        drawArrow();
    }

    public function unhighlight() 
    {
        removeChild(arrow);
        this.highlighted = false;
        drawArrow();
    }

    public function changeDeparture(newDep:Point)
    {
        removeChild(arrow);
        this.from = newDep;
        drawArrow();
    }

    public function changeDestination(newDest:Point)
    {
        removeChild(arrow);
        this.to = newDest;
        drawArrow();
    }
    
    private inline function rotatedPoint(p:Point, angle:Float):Point
    {
        return new Point(Math.cos(angle) * p.x - Math.sin(angle) * p.y, Math.cos(angle) * p.y + Math.sin(angle) * p.x);
    }

    private function drawArrow() 
    {
        var vertex1:Point = rotatedPoint(new Point(0, -ARROW_TRIANGLE_SIDE), - Math.PI / 8).add(to);
        var vertex2:Point = rotatedPoint(new Point(0, -ARROW_TRIANGLE_SIDE), Math.PI / 8).add(to);
        var upperSideVector = vertex2.subtract(vertex1);
        upperSideVector.normalize(upperSideVector.length / 2);
        var inputVertex:Point = vertex1.add(upperSideVector);
        var fracturePoint:Point = inputVertex.subtract(new Point(0, STRAIGHT_ARROW_SEGMENT_SIZE));

        var color = highlighted? 0x006600 : 0x333333;

        arrow = new Sprite();
        arrow.graphics.lineStyle(ARROW_THICKNESS, color);
        arrow.graphics.moveTo(from.x, from.y);
        arrow.graphics.lineTo(fracturePoint.x, fracturePoint.y);
        arrow.graphics.lineTo(inputVertex.x, inputVertex.y);

        var triangle:Sprite = new Sprite();
        triangle.graphics.beginFill(color);
        triangle.graphics.moveTo(inputVertex.x, inputVertex.y);
        triangle.graphics.lineTo(vertex1.x, vertex1.y);
        triangle.graphics.lineTo(to.x, to.y);
        triangle.graphics.lineTo(vertex2.x, vertex2.y);
        triangle.graphics.lineTo(inputVertex.x, inputVertex.y);
        triangle.graphics.endFill();

        arrow.addChild(triangle);
        addChild(arrow);
    }

    public function new(from:Point, to:Point, highlighted:Bool) 
    {
        super();

        this.from = from;
        this.to = to;
        this.highlighted = highlighted;
        drawArrow();
    }
}