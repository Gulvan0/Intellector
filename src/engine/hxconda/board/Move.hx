package engine.hxconda.board;

/**
    A move packed into a single integer: origin and destination squares plus the piece that ends up on the destination.
    The latter differs from the moving piece for promotions. Packed values are below `2^16` and can index lookup tables.
**/
abstract Move(Int) to Int
{
    public static inline final NONE:Move = cast -1;

    public var from(get, never):Int;
    public var to(get, never):Int;
    public var resultingPiece(get, never):Piece;

    private inline function get_from():Int
    {
        return this & 63;
    }

    private inline function get_to():Int
    {
        return (this >> 6) & 63;
    }

    private inline function get_resultingPiece():Piece
    {
        return cast this >> 12;
    }

    public inline function new(from:Int, to:Int, resultingPiece:Piece)
    {
        this = from | (to << 6) | (resultingPiece << 12);
    }
}
