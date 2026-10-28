package engine.hxconda.board;

/**
    Random keys of the Zobrist position hash: one per piece per square plus one for black's turn. Empty squares have key 0.
**/
class ZobristKeys
{
    public final blackToMove:Int;

    private final pieceKeys:Array<Int>;

    public inline function of(square:Int, piece:Piece):Int
    {
        return pieceKeys[square * Piece.COUNT + piece];
    }

    private static function randomKey():Int
    {
        var key:Float = 0;
        var bitValue:Float = 1;
        for (_ in 0...32)
        {
            key += Math.round(Math.random()) * bitValue;
            bitValue *= 2;
        }
        return Std.int(key);
    }

    public function new()
    {
        pieceKeys = [];
        for (_ in 0...BoardGeometry.SQUARE_COUNT)
        {
            for (_ in 0...Piece.COUNT - 1)
                pieceKeys.push(randomKey());
            pieceKeys.push(0);
        }
        blackToMove = randomKey();
    }
}
