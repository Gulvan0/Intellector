package client.ui.common.board;

import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.hex.HexCoordsIterator;
import intellectorboard.primitives.piece.PieceColor;

/**
    Where each hex is drawn on a `BoardSurface`, given the board's orientation: the single source
    of truth every layer and every hit-test goes through, so no layer keeps its own copy of the
    orientation. Owned by `BoardSurface`; only it changes `orientation`.
**/
class BoardProjection
{
    /**
        The color drawn at the bottom of the screen.
    **/
    public var orientation:PieceColor;

    // The board's own center.
    private final origin:BoardPoint;

    public function new(orientation:PieceColor, origin:BoardPoint)
    {
        this.orientation = orientation;
        this.origin = origin;
    }

    /**
        The center of the hex at `coords`.
    **/
    public function hexCenter(coords:HexCoords):BoardPoint
    {
        var relative:BoardPoint = relativeHexCenter(coords);
        return {x: origin.x + relative.x, y: origin.y + relative.y};
    }

    /**
        The hex whose center is closest to `point`, or `null` if that center is farther than one
        `SIDE_LENGTH` away. Nearest-center search over all 59 hexes - cheap at this count, and
        close enough for pointer interaction without a true point-in-hexagon test.
    **/
    public function hexAt(point:BoardPoint):Null<HexCoords>
    {
        var closest:Null<HexCoords> = null;
        var closestDistanceSquared:Float = BoardGeometry.SIDE_LENGTH * BoardGeometry.SIDE_LENGTH;

        for (coords in new HexCoordsIterator())
        {
            var center:BoardPoint = hexCenter(coords);
            var dx:Float = center.x - point.x;
            var dy:Float = center.y - point.y;
            var distanceSquared:Float = dx * dx + dy * dy;

            if (distanceSquared < closestDistanceSquared)
            {
                closest = coords;
                closestDistanceSquared = distanceSquared;
            }
        }

        return closest;
    }

    /**
        Whether the hex at `coords` is drawn below the board's horizontal midline.
    **/
    public function isInLowerHalf(coords:HexCoords):Bool
    {
        return relativeHexCenter(coords).y > 0;
    }

    /**
        How far left or right of the board's vertical midline the hex at `coords` is drawn: -1 for
        the leftmost file, 1 for the rightmost, 0 for the middle one.
    **/
    public function horizontalPosition(coords:HexCoords):Float
    {
        return relativeHexCenter(coords).x / (6 * BoardGeometry.SIDE_LENGTH);
    }

    // Relative to the board's own center; whichever color is `orientation` is drawn at the bottom.
    private function relativeHexCenter(coords:HexCoords):BoardPoint
    {
        var i:Int = coords.i;
        var j:Int = coords.j;

        if (orientation == Black)
        {
            j = 6 - j - i % 2;
            i = 8 - i;
        }

        var x:Float = 1.5 * (i - 4) * BoardGeometry.SIDE_LENGTH;
        var y:Float = (j - 3) * BoardGeometry.HEX_HEIGHT;

        if (i % 2 == 1)
            y += BoardGeometry.HEX_HEIGHT / 2;

        return {x: x, y: y};
    }
}
