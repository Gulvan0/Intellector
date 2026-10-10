package client.ui.common.board;

import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.hex.HexCoordsIterator;
import intellectorboard.primitives.piece.PieceColor;
import utest.Assert;
import utest.Test;

class BoardProjectionTest extends Test
{
    private static inline final EPSILON:Float = 1e-9;
    private static final ORIGIN:BoardPoint = {x: 1000, y: 500};

    private static function allHexes():Array<HexCoords>
    {
        return [for (coords in new HexCoordsIterator()) coords];
    }

    private static function projection(orientation:PieceColor):BoardProjection
    {
        return new BoardProjection(orientation, ORIGIN);
    }

    private static function offset(point:BoardPoint, dx:Float, dy:Float):BoardPoint
    {
        return {x: point.x + dx, y: point.y + dy};
    }

    private function assertHexAt(expected:Null<HexCoords>, projection:BoardProjection, point:BoardPoint, ?pos:haxe.PosInfos):Void
    {
        var actual:Null<HexCoords> = projection.hexAt(point);
        Assert.isTrue(HexCoords.areEqual(expected, actual), 'expected ${expected?.toScalarCoord()}, got ${actual?.toScalarCoord()}', pos);
    }

    private function assertPointEquals(expected:BoardPoint, actual:BoardPoint, ?pos:haxe.PosInfos):Void
    {
        Assert.floatEquals(expected.x, actual.x, EPSILON, pos);
        Assert.floatEquals(expected.y, actual.y, EPSILON, pos);
    }

    private function testEveryHexCenterMapsBackToItsHex():Void
    {
        for (orientation in [White, Black])
        {
            var board:BoardProjection = projection(orientation);
            for (coords in allHexes())
                assertHexAt(coords, board, board.hexCenter(coords));
        }
    }

    private function testPointsInsideAHexMapToIt():Void
    {
        var board:BoardProjection = projection(White);
        var inradius:Float = BoardGeometry.HEX_HEIGHT / 2;

        for (coords in allHexes())
        {
            var center:BoardPoint = board.hexCenter(coords);
            for (k in 0...6)
            {
                var angle:Float = Math.PI / 3 * k;
                assertHexAt(coords, board, offset(center, 0.95 * inradius * Math.cos(angle), 0.95 * inradius * Math.sin(angle)));
            }
        }
    }

    private function testHexAtIsNullBeyondOneSideFromEveryCenter():Void
    {
        var board:BoardProjection = projection(White);
        var leftmost:BoardPoint = board.hexCenter(new HexCoords(0, 3));

        assertHexAt(new HexCoords(0, 3), board, offset(leftmost, -0.95 * BoardGeometry.SIDE_LENGTH, 0));
        assertHexAt(null, board, offset(leftmost, -1.05 * BoardGeometry.SIDE_LENGTH, 0));
        assertHexAt(null, board, offset(ORIGIN, 0, BoardGeometry.GRID_HEIGHT));
    }

    private function testHexCentersDoNotOverlap():Void
    {
        var board:BoardProjection = projection(White);
        var centers:Array<BoardPoint> = allHexes().map(board.hexCenter);

        for (a in 0...centers.length)
            for (b in (a + 1)...centers.length)
            {
                var dx:Float = centers[a].x - centers[b].x;
                var dy:Float = centers[a].y - centers[b].y;
                Assert.isTrue(Math.sqrt(dx * dx + dy * dy) >= BoardGeometry.HEX_HEIGHT - EPSILON);
            }
    }

    private function testColumnNeighborsAreOneHexHeightApart():Void
    {
        var board:BoardProjection = projection(White);
        var upper:BoardPoint = board.hexCenter(new HexCoords(3, 2));

        assertPointEquals(offset(upper, 0, BoardGeometry.HEX_HEIGHT), board.hexCenter(new HexCoords(3, 3)));
    }

    private function testBlackOrientationIsPointReflectionThroughOrigin():Void
    {
        var white:BoardProjection = projection(White);
        var black:BoardProjection = projection(Black);

        for (coords in allHexes())
        {
            var whiteCenter:BoardPoint = white.hexCenter(coords);
            assertPointEquals({x: 2 * ORIGIN.x - whiteCenter.x, y: 2 * ORIGIN.y - whiteCenter.y}, black.hexCenter(coords));
        }
    }

    private function testBlackOrientationDrawsInvertedCoordinatesInPlace():Void
    {
        var white:BoardProjection = projection(White);
        var black:BoardProjection = projection(Black);

        for (coords in allHexes())
            assertPointEquals(white.hexCenter(coords.invert()), black.hexCenter(coords));
    }

    private function testChangingOrientationReprojects():Void
    {
        var board:BoardProjection = projection(White);
        var coords:HexCoords = new HexCoords(4, 6);
        var whiteCenter:BoardPoint = board.hexCenter(coords);

        board.orientation = Black;

        assertPointEquals({x: 2 * ORIGIN.x - whiteCenter.x, y: 2 * ORIGIN.y - whiteCenter.y}, board.hexCenter(coords));
        assertHexAt(coords, board, board.hexCenter(coords));
    }

    private function testOwnSideIsDrawnInLowerHalf():Void
    {
        var whiteHome:HexCoords = new HexCoords(4, 6);
        var blackHome:HexCoords = new HexCoords(4, 0);
        var middle:HexCoords = new HexCoords(4, 3);

        Assert.isTrue(projection(White).isInLowerHalf(whiteHome));
        Assert.isFalse(projection(White).isInLowerHalf(blackHome));
        Assert.isFalse(projection(White).isInLowerHalf(middle));

        Assert.isTrue(projection(Black).isInLowerHalf(blackHome));
        Assert.isFalse(projection(Black).isInLowerHalf(whiteHome));
        Assert.isFalse(projection(Black).isInLowerHalf(middle));
    }

    private function testOddColumnHexesAreHalfAHexLower():Void
    {
        Assert.isFalse(projection(White).isInLowerHalf(new HexCoords(1, 2)));
        Assert.isTrue(projection(White).isInLowerHalf(new HexCoords(1, 3)));
    }

    private function testHorizontalPositionSpansMinusOneToOne():Void
    {
        Assert.floatEquals(-1, projection(White).horizontalPosition(new HexCoords(0, 2)), EPSILON);
        Assert.floatEquals(0, projection(White).horizontalPosition(new HexCoords(4, 2)), EPSILON);
        Assert.floatEquals(1, projection(White).horizontalPosition(new HexCoords(8, 2)), EPSILON);

        Assert.floatEquals(1, projection(Black).horizontalPosition(new HexCoords(0, 2)), EPSILON);
        Assert.floatEquals(-1, projection(Black).horizontalPosition(new HexCoords(8, 2)), EPSILON);
    }
}
