package client.ui.common.board;

import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.hex.HexCoordsIterator;
import intellectorboard.primitives.piece.PieceColor;

/**
    Where each hex is drawn for the board's orientation; every layer and hit-test goes through it.
    Only `BoardSurface` changes `orientation`.
**/
class BoardProjection
{
    /** The color drawn at the bottom of the screen **/
    public var orientation:PieceColor;

    // The board's own center.
    private final origin:BoardPoint;

    public function new(orientation:PieceColor, origin:BoardPoint)
    {
        this.orientation = orientation;
        this.origin = origin;
    }

    /** The center of the hex at `coords` **/
    public function hexCenter(coords:HexCoords):BoardPoint
    {
        var relative:BoardPoint = relativeHexCenter(coords);
        return {x: origin.x + relative.x, y: origin.y + relative.y};
    }

    /** The hex whose center is nearest to `point`, or `null` if it's over `SIDE_LENGTH` away **/
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

    /** Whether the hex at `coords` is drawn below the board's horizontal midline **/
    public function isInLowerHalf(coords:HexCoords):Bool
    {
        return relativeHexCenter(coords).y > 0;
    }

    /** Where `coords` is drawn horizontally: -1 for the leftmost file, 0 the middle, 1 the rightmost **/
    public function horizontalPosition(coords:HexCoords):Float
    {
        return relativeHexCenter(coords).x / (6 * BoardGeometry.SIDE_LENGTH);
    }

    // relative to the board's center
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
