package client.ui.common.board;

import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.hex.HexCoordsIterator;
import intellectorboard.primitives.piece.PieceColor;

/**
    Pure hex-position/shape math for a board rendered at a fixed side length, with no notion of a
    concrete pixel size - callers place this math inside a `viewBox`-scaled `SvgSurface`, which
    scales the whole board for free via CSS. Every unit here is a `viewBox` unit.
**/
class BoardGeometry
{
    public static inline final SIDE_LENGTH:Float = 100;
    public static inline final HEX_WIDTH:Float = SIDE_LENGTH * 2;
    public static final HEX_HEIGHT:Float = SIDE_LENGTH * Math.sqrt(3);
    public static inline final BORDER_THICKNESS:Float = SIDE_LENGTH * 0.075;

    /*
        Half-extent, from the board's own center, of the bounding box covering every hex
        (hex centers span [-6*SIDE_LENGTH, 6*SIDE_LENGTH] horizontally and
        [-3*HEX_HEIGHT, 3*HEX_HEIGHT] vertically; adding a half hex in each direction accounts for
        the hexes' own extent around their centers).
    */
    public static inline final GRID_HALF_WIDTH:Float = 7 * SIDE_LENGTH;
    public static final GRID_HALF_HEIGHT:Float = 3.5 * HEX_HEIGHT;

    /**
        The center of the hex at `coords`, relative to the board's own center, with `orientation`
        applied (whichever color is `White` is always drawn as though it sits at the bottom of the
        screen).
    **/
    public static function hexCenter(coords:HexCoords, orientation:PieceColor):{x:Float, y:Float}
    {
        var i:Int = coords.i;
        var j:Int = coords.j;

        if (orientation == Black)
        {
            j = 6 - j - i % 2;
            i = 8 - i;
        }

        var di:Float = i - 4;
        var dj:Float = j - 3;

        var x:Float = 1.5 * di * SIDE_LENGTH;
        var y:Float = dj * HEX_HEIGHT;

        if (i % 2 == 1)
            y += HEX_HEIGHT / 2;

        return {x: x, y: y};
    }

    /**
        The 6 vertices of a hex centered at `(centerX, centerY)`, in clockwise order starting from
        the left (middle-left) vertex - matching the winding a caller draws as a single closed
        path.
    **/
    public static function hexVertices(centerX:Float, centerY:Float):Array<{x:Float, y:Float}>
    {
        var s:Float = SIDE_LENGTH;
        var h:Float = HEX_HEIGHT;

        return [
            {x: centerX - s, y: centerY},
            {x: centerX - s / 2, y: centerY - h / 2},
            {x: centerX + s / 2, y: centerY - h / 2},
            {x: centerX + s, y: centerY},
            {x: centerX + s / 2, y: centerY + h / 2},
            {x: centerX - s / 2, y: centerY + h / 2}
        ];
    }

    /**
        The hex whose center is closest to `(pointX, pointY)` (board-center-relative), or `null`
        if that center is farther than one `SIDE_LENGTH` away. Nearest-center search over all 59
        hexes - cheap at this count, and close enough for pointer interaction without a true
        point-in-hexagon test.
    **/
    public static function hexAt(pointX:Float, pointY:Float, orientation:PieceColor):Null<HexCoords>
    {
        var closest:Null<HexCoords> = null;
        var closestDistSqr:Float = SIDE_LENGTH * SIDE_LENGTH;

        for (coords in new HexCoordsIterator())
        {
            var center = hexCenter(coords, orientation);
            var dx:Float = center.x - pointX;
            var dy:Float = center.y - pointY;
            var distSqr:Float = dx * dx + dy * dy;

            if (distSqr < closestDistSqr)
            {
                closest = coords;
                closestDistSqr = distSqr;
            }
        }

        return closest;
    }
}
