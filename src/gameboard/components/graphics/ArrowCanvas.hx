package gameboard.components.graphics;

import gameboard.util.HexDimensions;
import haxe.ui.backend.html5.svg.SVGBuilder;
import haxe.ui.backend.html5.graphics.SVGGraphicsImpl;
import gfx.utils.Colors;
import haxe.ui.geom.Point;
import haxe.ui.components.Canvas;

class ArrowCanvas extends Canvas
{
    public function redraw(dimensions:HexDimensions, fromCenter:Point, toCenter:Point) 
    {
        componentGraphics.clear();
        draw(dimensions, fromCenter, toCenter);
    }
    
    @:access(haxe.ui.backend.ComponentGraphicsImpl)
    @:access(haxe.ui.backend.html5.graphics.SVGGraphicsImpl) 
    private function getBuilder():SVGBuilder
    {
        return cast(componentGraphics._impl, SVGGraphicsImpl)._svg;
    }

    private function draw(dimensions:HexDimensions, fromCenter:Point, toCenter:Point) 
    {
        var trunkThickness:Float = 0.375 * dimensions.sideLength;
        var capTriangleSide:Float = 0.75 * dimensions.sideLength;
        var startRadius:Float = dimensions.sideLength / 2; //hexSideLength is also a hex radius. We start drawing halfway to the bounding circle's boundary

        var direction:Point = toCenter.diff(fromCenter);
        var orthogonalDirection:Point = direction.orthogonalCW();

        var capSupportVector:Point = direction.opposite().normalized(capTriangleSide);
        var sourceSupportVector:Point = orthogonalDirection.normalized(trunkThickness / 2);
        var jointSupportVector:Point = orthogonalDirection.normalized((capTriangleSide - trunkThickness) / 2);

        var capTopVertex:Point = toCenter.copy();
        var capBottomCCWVertex:Point = capTopVertex.sum(capSupportVector.rotated(-Math.PI / 6));
        var capBottomCWVertex:Point = capTopVertex.sum(capSupportVector.rotated(Math.PI / 6));

        var trueSource:Point = fromCenter.sum(direction.normalized(startRadius));
        var sourceCWVertex:Point = trueSource.sum(sourceSupportVector);
        var sourceCCWVertex:Point = trueSource.diff(sourceSupportVector);

        var jointCWVertex:Point = capBottomCWVertex.diff(jointSupportVector);
        var jointCCWVertex:Point = capBottomCCWVertex.sum(jointSupportVector);

        var interimVertexSequence:Array<Point> = [capBottomCCWVertex, jointCCWVertex, sourceCCWVertex, sourceCWVertex, jointCWVertex, capBottomCWVertex];

        var topLeft:Point = capTopVertex.copy();
        var bottomRight:Point = capTopVertex.copy();

        for (vertex in interimVertexSequence)
        {
            if (vertex.x < topLeft.x)
                topLeft.x = vertex.x;
            else if (vertex.x > bottomRight.x)
                bottomRight.x = vertex.x;

            if (vertex.y < topLeft.y)
                topLeft.y = vertex.y;
            else if (vertex.y > bottomRight.y)
                bottomRight.y = vertex.y;
        }

        left = topLeft.x;
        top = topLeft.y;
        width = bottomRight.x - topLeft.x;
        height = bottomRight.y - topLeft.y;

        var builder = getBuilder();
        var path = builder.path(capTopVertex.x - topLeft.x, capTopVertex.y - topLeft.y);

        path.fill({color: Colors.arrow.toHex(), opacity: 0.75});

        for (vertex in interimVertexSequence)
            path.lineTo(vertex.x - topLeft.x, vertex.y - topLeft.y);

        path.lineTo(capTopVertex.x - topLeft.x, capTopVertex.y - topLeft.y);
        path.close();
    }

    public function new(dimensions:HexDimensions, fromCenter:Point, toCenter:Point) 
    {
        super();

        draw(dimensions, fromCenter, toCenter);
    }
}