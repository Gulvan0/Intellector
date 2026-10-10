package client.ui.common.board;

import intellectorboard.primitives.hex.HexCoordsIterator;
import utest.Assert;
import utest.Test;

class BoardGeometryTest extends Test
{
    private static inline final EPSILON:Float = 1e-9;

    private static function distance(a:BoardPoint, b:BoardPoint):Float
    {
        return Math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
    }

    private function testVerticesLieOnCircumcircle():Void
    {
        var center:BoardPoint = {x: 37, y: -12};
        for (vertex in BoardGeometry.hexVertices(center))
            Assert.floatEquals(BoardGeometry.SIDE_LENGTH, distance(center, vertex), EPSILON);
    }

    private function testAdjacentVerticesAreOneSideApart():Void
    {
        var vertices:Array<BoardPoint> = BoardGeometry.hexVertices({x: 0, y: 0});
        Assert.equals(6, vertices.length);
        for (k in 0...vertices.length)
            Assert.floatEquals(BoardGeometry.SIDE_LENGTH, distance(vertices[k], vertices[(k + 1) % vertices.length]), EPSILON);
    }

    private function testVerticesStartMiddleLeftAndGoClockwise():Void
    {
        var center:BoardPoint = {x: 10, y: 20};
        var vertices:Array<BoardPoint> = BoardGeometry.hexVertices(center);

        Assert.floatEquals(center.x - BoardGeometry.SIDE_LENGTH, vertices[0].x, EPSILON);
        Assert.floatEquals(center.y, vertices[0].y, EPSILON);

        // a positive shoelace sum is clockwise on screen, where y grows downward
        var doubledArea:Float = 0;
        for (k in 0...vertices.length)
        {
            var next:BoardPoint = vertices[(k + 1) % vertices.length];
            doubledArea += vertices[k].x * next.y - next.x * vertices[k].y;
        }
        Assert.isTrue(doubledArea > 0);
    }

    private function testGridHalfExtentsTightlyCoverEveryHex():Void
    {
        var projection:BoardProjection = new BoardProjection(White, {x: 0, y: 0});
        var maxX:Float = 0;
        var maxY:Float = 0;

        for (coords in new HexCoordsIterator())
            for (vertex in BoardGeometry.hexVertices(projection.hexCenter(coords)))
            {
                maxX = Math.max(maxX, Math.abs(vertex.x));
                maxY = Math.max(maxY, Math.abs(vertex.y));
            }

        Assert.floatEquals(BoardGeometry.GRID_HALF_WIDTH, maxX, EPSILON);
        Assert.floatEquals(BoardGeometry.GRID_HALF_HEIGHT, maxY, EPSILON);
    }
}
