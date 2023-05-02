package gfx.live.analysis.variation_tree;

import gfx.live.analysis.variation_tree.util.ArrowHighlighting;
import haxe.ui.util.Color;
import haxe.ui.backend.html5.graphics.SVGGraphicsImpl;
import haxe.ui.backend.html5.svg.SVGBuilder;
import net.shared.utils.MathUtils;
import haxe.ui.containers.Absolute;
import haxe.ui.geom.Point;
import haxe.ui.components.Canvas;
import gfx.utils.Colors;

class Arrow extends Canvas
{
    private static var NORMAL_ARROW_THICKNESS:Float = 2;
    private static var NORMAL_ARROW_TRIANGLE_SIDE:Float = 12;
    private static var NORMAL_STRAIGHT_ARROW_SEGMENT_SIZE:Float = 5;

    public var from(default, null):Point;
    public var to(default, null):Point;
    public var highlighting(default, null):ArrowHighlighting;
    public var scale(default, null):Float;

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
        var vertex1:Point = rotatedPoint(new Point(0, -NORMAL_ARROW_TRIANGLE_SIDE * scale), - Math.PI / 8).sum(to);
        var vertex2:Point = rotatedPoint(new Point(0, -NORMAL_ARROW_TRIANGLE_SIDE * scale), Math.PI / 8).sum(to);
        var upperSideVector = vertex2.diff(vertex1).product(0.5);
        var inputVertex:Point = vertex1.sum(upperSideVector);
        var fracturePoint:Point = inputVertex.diff(new Point(0, NORMAL_STRAIGHT_ARROW_SEGMENT_SIZE * scale));

        var color:Color;
        var alpha:Float;

        switch highlighting 
        {
            case Off: 
                color = Colors.variationTreeUnselectedArrow;
                alpha = 1;
            case Semi:
                color = Colors.variationTreeSelectedArrow;
                alpha = 0.4;
            case Full: 
                color = Colors.variationTreeSelectedArrow;
                alpha = 1;
        }

        width = MathUtils.arrmax([inputVertex.x, fracturePoint.x, from.x, to.x, vertex1.x, vertex2.x]) + NORMAL_ARROW_THICKNESS * scale;
        height = MathUtils.arrmax([inputVertex.y, fracturePoint.y, from.y, to.y, vertex1.y, vertex2.y]) + NORMAL_ARROW_THICKNESS * scale;

        componentGraphics.strokeStyle(color, NORMAL_ARROW_THICKNESS * scale, alpha);
        componentGraphics.moveTo(from.x, from.y);
        componentGraphics.lineTo(fracturePoint.x, fracturePoint.y);
        componentGraphics.lineTo(inputVertex.x, inputVertex.y);

        componentGraphics.strokeStyle(null, null, 0);

        var builder = getBuilder();
        var path = builder.path(inputVertex.x, inputVertex.y);

        path.stroke({alpha: 0});
        path.fill({color: color.toHex(), opacity: alpha});
        path.lineTo(vertex1.x, vertex1.y);
        path.lineTo(to.x, to.y);
        path.lineTo(vertex2.x, vertex2.y);
        path.lineTo(inputVertex.x, inputVertex.y);
        path.close();
    }

    public function new(scale:Float) 
    {
        super();
        this.highlighting = Off;
        this.scale = scale;
    }
}