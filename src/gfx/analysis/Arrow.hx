package gfx.analysis;

import haxe.ui.util.Color;
import haxe.ui.backend.html5.graphics.SVGGraphicsImpl;
import haxe.ui.backend.html5.svg.SVGBuilder;
import net.shared.utils.MathUtils;
import haxe.ui.containers.Absolute;
import haxe.ui.geom.Point;
import haxe.ui.components.Canvas;
import gfx.utils.Colors;

enum Highlighting
{
    Off;
    Semi;
    Full;
}

class Arrow extends Canvas
{
    private static var ARROW_THICKNESS:Float = 2;
    private static var ARROW_TRIANGLE_SIDE:Float = 12;
    private static var STRAIGHT_ARROW_SEGMENT_SIZE:Float = 5;

    public var from(default, null):Point;
    public var to(default, null):Point;
    public var highlighting(default, null):Highlighting;

    public function highlight(fully:Bool) 
    {
        this.highlighting = fully? Full : Semi;

        if (from == null || to == null)
            return;

        componentGraphics.clear();
        drawArrow();
    }

    public function unhighlight() 
    {
        this.highlighting = Off;

        if (from == null || to == null)
            return;
        
        componentGraphics.clear();
        drawArrow();
    }

    public function changeDeparture(newDep:Point)
    {
        componentGraphics.clear();
        this.from = newDep;
        drawArrow();
    }

    public function changeDestination(newDest:Point)
    {
        componentGraphics.clear();
        this.to = newDest;
        drawArrow();
    }

    public function changeEndpoints(newDep:Point, newDest:Point)
    {
        componentGraphics.clear();
        this.from = newDep;
        this.to = newDest;
        drawArrow();
    }
    
    private inline function rotatedPoint(p:Point, angle:Float):Point
    {
        return new Point(Math.cos(angle) * p.x - Math.sin(angle) * p.y, Math.cos(angle) * p.y + Math.sin(angle) * p.x);
    }

    @:access(haxe.ui.backend.ComponentGraphicsImpl)
    @:access(haxe.ui.backend.html5.graphics.SVGGraphicsImpl) 
    private function getBuilder():SVGBuilder
    {
        return cast(componentGraphics._impl, SVGGraphicsImpl)._svg;
    }

    private function drawArrow() 
    {
        var vertex1:Point = rotatedPoint(new Point(0, -ARROW_TRIANGLE_SIDE), - Math.PI / 8).sum(to);
        var vertex2:Point = rotatedPoint(new Point(0, -ARROW_TRIANGLE_SIDE), Math.PI / 8).sum(to);
        var upperSideVector = vertex2.diff(vertex1).product(0.5);
        var inputVertex:Point = vertex1.sum(upperSideVector);
        var fracturePoint:Point = inputVertex.diff(new Point(0, STRAIGHT_ARROW_SEGMENT_SIZE));

        var color:Color;
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

        width = MathUtils.arrmax([inputVertex.x, fracturePoint.x, from.x, to.x, vertex1.x, vertex2.x]) + ARROW_THICKNESS;
        height = MathUtils.arrmax([inputVertex.y, fracturePoint.y, from.y, to.y, vertex1.y, vertex2.y]) + ARROW_THICKNESS;

        componentGraphics.strokeStyle(color, ARROW_THICKNESS, alpha);
        componentGraphics.moveTo(from.x, from.y);
        componentGraphics.lineTo(fracturePoint.x, fracturePoint.y);
        componentGraphics.lineTo(inputVertex.x, inputVertex.y);

        var builder = getBuilder();
        var path = builder.path(inputVertex.x, inputVertex.y);

        path.fill({color: color.toHex(), opacity: alpha});
        path.lineTo(vertex1.x, vertex1.y);
        path.lineTo(to.x, to.y);
        path.lineTo(vertex2.x, vertex2.y);
        path.lineTo(inputVertex.x, inputVertex.y);
        path.close();
    }

    public function new() 
    {
        super();
        this.highlighting = Off;
    }
}