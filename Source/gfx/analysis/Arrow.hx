package gfx.analysis;

import gfx.utils.Colors;
import openfl.display.Sprite;
import openfl.geom.Point;

enum Highlighting
{
    Off;
    Semi;
    Full;
}

class Arrow extends Sprite
{
    private static var ARROW_THICKNESS:Float = 2;
    private static var ARROW_TRIANGLE_SIDE:Float = 12;
    private static var STRAIGHT_ARROW_SEGMENT_SIZE:Float = 5;

    public var from(default, null):Point;
    public var to(default, null):Point;
    public var highlighting(default, null):Highlighting;
    private var arrow:Sprite = new Sprite();

    public function highlight(fully:Bool) 
    {
        this.highlighting = fully? Full : Semi;

        if (from == null || to == null)
            return;

        removeChild(arrow);
        drawArrow();
    }

    public function unhighlight() 
    {
        this.highlighting = Off;

        if (from == null || to == null)
            return;
        
        removeChild(arrow);
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

    public function changeEndpoints(newDep:Point, newDest:Point)
    {
        removeChild(arrow);
        this.from = newDep;
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

        var color:Int;
        var alpha:Float;

        switch highlighting 
        {
            case Off: 
                color = Colors.variantTreeUnselectedArrow;
                alpha = 1;
            case Semi:
                color = Colors.variantTreeSelectedArrow;
                alpha = 0.4;
            case Full: 
                color = Colors.variantTreeSelectedArrow;
                alpha = 1;
        }

        arrow = new Sprite();
        arrow.graphics.lineStyle(ARROW_THICKNESS, color, alpha);
        arrow.graphics.moveTo(from.x, from.y);
        arrow.graphics.lineTo(fracturePoint.x, fracturePoint.y);
        arrow.graphics.lineTo(inputVertex.x, inputVertex.y);

        var triangle:Sprite = new Sprite();
        triangle.graphics.beginFill(color, alpha);
        triangle.graphics.moveTo(inputVertex.x, inputVertex.y);
        triangle.graphics.lineTo(vertex1.x, vertex1.y);
        triangle.graphics.lineTo(to.x, to.y);
        triangle.graphics.lineTo(vertex2.x, vertex2.y);
        triangle.graphics.lineTo(inputVertex.x, inputVertex.y);
        triangle.graphics.endFill();

        arrow.addChild(triangle);
        addChild(arrow);
    }

    public function new() 
    {
        super();
        this.highlighting = Off;
    }
}