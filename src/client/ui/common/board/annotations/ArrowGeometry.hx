package client.ui.common.board.annotations;

import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardPoint;

/**
    The outline of an annotation arrow between two hex centers, in board units: a trunk starting
    halfway out of the source hex, and a triangular cap whose tip is the target hex's center.
**/
class ArrowGeometry
{
    private static inline final TRUNK_THICKNESS:Float = 0.375 * BoardGeometry.SIDE_LENGTH;
    private static inline final CAP_SIDE:Float = 0.75 * BoardGeometry.SIDE_LENGTH;
    // Halfway from the source hex's center to its corners.
    private static inline final START_OFFSET:Float = 0.5 * BoardGeometry.SIDE_LENGTH;

    /**
        The arrow's polygon, starting at the cap's tip.
    **/
    public static function outline(from:BoardPoint, to:BoardPoint):Array<BoardPoint>
    {
        var direction:BoardPoint = {x: to.x - from.x, y: to.y - from.y};
        var length:Float = Math.sqrt(direction.x * direction.x + direction.y * direction.y);
        var unit:BoardPoint = {x: direction.x / length, y: direction.y / length};
        // Orthogonal to the direction, toward the clockwise side of the outline (the side `capClockwise` is on).
        var orthogonal:BoardPoint = {x: unit.y, y: -unit.x};

        var capBack:BoardPoint = {x: -unit.x * CAP_SIDE, y: -unit.y * CAP_SIDE};
        var capCounterclockwise:BoardPoint = add(to, rotated(capBack, -Math.PI / 6));
        var capClockwise:BoardPoint = add(to, rotated(capBack, Math.PI / 6));

        var source:BoardPoint = add(from, scaled(unit, START_OFFSET));
        var sourceClockwise:BoardPoint = add(source, scaled(orthogonal, TRUNK_THICKNESS / 2));
        var sourceCounterclockwise:BoardPoint = add(source, scaled(orthogonal, -TRUNK_THICKNESS / 2));

        var jointInset:Float = (CAP_SIDE - TRUNK_THICKNESS) / 2;
        var jointClockwise:BoardPoint = add(capClockwise, scaled(orthogonal, -jointInset));
        var jointCounterclockwise:BoardPoint = add(capCounterclockwise, scaled(orthogonal, jointInset));

        return [to, capCounterclockwise, jointCounterclockwise, sourceCounterclockwise, sourceClockwise, jointClockwise, capClockwise];
    }

    private static function add(a:BoardPoint, b:BoardPoint):BoardPoint
    {
        return {x: a.x + b.x, y: a.y + b.y};
    }

    private static function scaled(v:BoardPoint, factor:Float):BoardPoint
    {
        return {x: v.x * factor, y: v.y * factor};
    }

    private static function rotated(v:BoardPoint, angle:Float):BoardPoint
    {
        var cos:Float = Math.cos(angle);
        var sin:Float = Math.sin(angle);
        return {x: v.x * cos - v.y * sin, y: v.x * sin + v.y * cos};
    }
}
