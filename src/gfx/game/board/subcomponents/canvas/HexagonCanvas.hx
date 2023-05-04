package gfx.game.board.subcomponents.canvas;

import gfx.utils.Colors;
import gfx.game.board.util.HexDimensions;
import gfx.game.board.util.HexagonLayer;
import haxe.ui.backend.html5.svg.SVGBuilder;
import haxe.ui.backend.html5.graphics.SVGGraphicsImpl;
import haxe.ui.geom.Point;
import haxe.ui.util.Color;
import haxe.ui.components.Canvas;

class HexagonCanvas extends Canvas
{
    public function getCenter():Point 
    {
        return new Point(left + width / 2, top + height / 2);
    }

    public function setCenterAt(x:Float, y:Float) 
    {
        left = x - width / 2;
        top = y - height / 2;
    }

    @:access(haxe.ui.backend.ComponentGraphicsImpl)
    @:access(haxe.ui.backend.html5.graphics.SVGGraphicsImpl) 
    private function getBuilder():SVGBuilder
    {
        return cast(componentGraphics._impl, SVGGraphicsImpl)._svg;
    }

    private function drawHexagon(dimensions:HexDimensions, borderThickness:Float, borderColor:Color, fillColor:Color) 
    {
        var currentPoint:Point = new Point(borderThickness / 2, borderThickness / 2);
        currentPoint.addCoords(0, dimensions.height / 2);

        var builder = getBuilder();
        var path = builder.path(currentPoint.x, currentPoint.y);

        path.stroke({color: borderColor.toHex(), thickness: borderThickness});
        path.fill({color: fillColor.toHex()});

        currentPoint.addCoords(dimensions.width / 4, -dimensions.height / 2);
        path.lineTo(currentPoint.x, currentPoint.y);

        currentPoint.addCoords(dimensions.width / 2, 0);
        path.lineTo(currentPoint.x, currentPoint.y);

        currentPoint.addCoords(dimensions.width / 4, dimensions.height / 2);
        path.lineTo(currentPoint.x, currentPoint.y);

        currentPoint.addCoords(-dimensions.width / 4, dimensions.height / 2);
        path.lineTo(currentPoint.x, currentPoint.y);

        currentPoint.addCoords(-dimensions.width / 2, 0);
        path.lineTo(currentPoint.x, currentPoint.y);

        currentPoint.addCoords(-dimensions.width / 4, -dimensions.height / 2);
        path.lineTo(currentPoint.x, currentPoint.y);

        path.close();
    }

    public function new(dimensions:HexDimensions, layer:HexagonLayer, dark:Bool, ?centerX:Float, ?centerY:Float) 
    {
        super();

        var borderThickness:Float = 0.075 * dimensions.sideLength;
        var borderColor:Color = Colors.border;
        var fillColor:Color = Colors.hexFill(layer, dark);
        
        this.width = dimensions.width + Math.ceil(borderThickness);
        this.height = dimensions.height + Math.ceil(borderThickness);

        drawHexagon(dimensions, borderThickness, borderColor, fillColor);
        
        if (centerX != null && centerY != null)
            setCenterAt(centerX, centerY);
    }
}