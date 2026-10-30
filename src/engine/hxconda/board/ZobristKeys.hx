package engine.hxconda.board;

/**
    Keys of a Zobrist position hash: one per piece per square plus one for black's turn. Empty squares have key 0.
**/
class ZobristKeys
{
    public final blackToMove:Int;

    private final pieceKeys:Array<Int>;

    /** Keys drawn from `Math.random`, different for every search **/
    public static function random():ZobristKeys
    {
        return new ZobristKeys(randomKey);
    }

    /** Keys of a fixed xorshift sequence starting at the nonzero `seed`, leaving `Math.random` untouched **/
    public static function seeded(seed:Int):ZobristKeys
    {
        var state:Int = seed;
        return new ZobristKeys(() -> {
            state ^= state << 13;
            state ^= state >>> 17;
            state ^= state << 5;
            return state;
        });
    }

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

    private function new(nextKey:()->Int)
    {
        pieceKeys = [];
        for (_ in 0...BoardGeometry.SQUARE_COUNT)
        {
            for (_ in 0...Piece.COUNT - 1)
                pieceKeys.push(nextKey());
            pieceKeys.push(0);
        }
        blackToMove = nextKey();
    }
}
