package client.ui.common.board;

/**
    Hex-shape math at a fixed side length, in `viewBox` units: no pixel size or orientation (those
    are `BoardProjection`'s).
**/
class BoardGeometry
{
    public static inline final SIDE_LENGTH:Float = 100;
    public static inline final HEX_WIDTH:Float = SIDE_LENGTH * 2;
    public static final HEX_HEIGHT:Float = SIDE_LENGTH * Math.sqrt(3);
    public static inline final BORDER_THICKNESS:Float = SIDE_LENGTH * 0.075;

    // half-extents of the box covering every hex: the outermost centers plus half a hex
    public static inline final GRID_HALF_WIDTH:Float = 7 * SIDE_LENGTH;
    public static final GRID_HALF_HEIGHT:Float = 3.5 * HEX_HEIGHT;

    /** The grid's own bounding box, border included **/
    public static final GRID_WIDTH:Float = 2 * GRID_HALF_WIDTH + BORDER_THICKNESS;
    public static final GRID_HEIGHT:Float = 2 * GRID_HALF_HEIGHT + BORDER_THICKNESS;

    /** The 6 vertices of a hex centered at `center`, clockwise from the middle-left one **/
    public static function hexVertices(center:BoardPoint):Array<BoardPoint>
    {
        var s:Float = SIDE_LENGTH;
        var h:Float = HEX_HEIGHT;

        return [
            {x: center.x - s, y: center.y},
            {x: center.x - s / 2, y: center.y - h / 2},
            {x: center.x + s / 2, y: center.y - h / 2},
            {x: center.x + s, y: center.y},
            {x: center.x + s / 2, y: center.y + h / 2},
            {x: center.x - s / 2, y: center.y + h / 2}
        ];
    }
}
