package engine.hxconda.board;

import js.lib.Int16Array;
import js.lib.Int8Array;

/**
    Square lists packed into one flat array: list `n` spans `squares[start(n)...end(n)]`.
**/
class SquareLists
{
    public final squares:Int8Array;

    private final offsets:Int16Array;

    /** Packs per-square rays: the ray going from `square` in `direction` becomes list `square * DIRECTION_COUNT + direction` **/
    public static function ofRays(rays:Array<Array<Array<Int>>>):SquareLists
    {
        return new SquareLists([for (squareRays in rays) for (ray in squareRays) ray]);
    }

    public inline function start(list:Int):Int
    {
        return offsets[list];
    }

    public inline function end(list:Int):Int
    {
        return offsets[list + 1];
    }

    public inline function size(list:Int):Int
    {
        return offsets[list + 1] - offsets[list];
    }

    public function new(lists:Array<Array<Int>>)
    {
        var squareCount:Int = 0;
        for (list in lists)
            squareCount += list.length;

        squares = new Int8Array(squareCount);
        offsets = new Int16Array(lists.length + 1);

        var offset:Int = 0;
        for (i in 0...lists.length)
        {
            for (square in lists[i])
                squares[offset++] = square;
            offsets[i + 1] = offset;
        }
    }
}
