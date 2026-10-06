package client.ui.common.board.annotations;

import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardPoint;

/**
    An annotation arrow's outline between two hex centers: a trunk from halfway out of the source
    hex, and a triangular cap tipped at the target's center.
**/
class ArrowGeometry
{
    /** The arrow's polygon, starting at the cap's tip **/
    public static function outline(from:BoardPoint, to:BoardPoint):Array<BoardPoint>
    {
        var direction:BoardPoint = {x: to.x - from.x, y: to.y - from.y};
        var length:Float = Math.sqrt(direction.x * direction.x + direction.y * direction.y);
        var unit:BoardPoint = {x: direction.x / length, y: direction.y / length};
        // toward the outline's clockwise side, where `capClockwise` is
        var orthogonal:BoardPoint = {x: unit.y, y: -unit.x};

        var capBack:BoardPoint = {x: -unit.x * StyleVars.BOARD_ARROW_CAP_SIDE, y: -unit.y * StyleVars.BOARD_ARROW_CAP_SIDE};
        var capCounterclockwise:BoardPoint = add(to, rotated(capBack, -Math.PI / 6));
        var capClockwise:BoardPoint = add(to, rotated(capBack, Math.PI / 6));

        var source:BoardPoint = add(from, scaled(unit, StyleVars.BOARD_ARROW_START_OFFSET));
        var sourceClockwise:BoardPoint = add(source, scaled(orthogonal, StyleVars.BOARD_ARROW_TRUNK_THICKNESS / 2));
        var sourceCounterclockwise:BoardPoint = add(source, scaled(orthogonal, -StyleVars.BOARD_ARROW_TRUNK_THICKNESS / 2));

        var jointInset:Float = (StyleVars.BOARD_ARROW_CAP_SIDE - StyleVars.BOARD_ARROW_TRUNK_THICKNESS) / 2;
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
