package engine.hxconda.board;

/**
    Square lists packed into one flat array: list `n` spans `squares[start(n)...end(n)]`.
**/
class SquareLists
{
    public final squares:Array<Int>;

    private final offsets:Array<Int>;

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
        squares = [];
        offsets = [0];

        for (list in lists)
        {
            for (square in list)
                squares.push(square);
            offsets.push(squares.length);
        }
    }
}
