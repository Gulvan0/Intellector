package engine.hxconda.board;

import js.lib.Int32Array;

/**
    Keys of a Zobrist position hash: one per piece per square plus one for black's turn. Empty squares have key 0.
    The same seed always gives the same keys, so hashes stay valid across searches.
**/
class ZobristKeys
{
    public final blackToMove:Int;

    private final pieceKeys:Int32Array;

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

    private function new(nextKey:()->Int)
    {
        pieceKeys = new Int32Array(BoardGeometry.SQUARE_COUNT * Piece.COUNT);
        for (square in 0...BoardGeometry.SQUARE_COUNT)
            for (piece in 0...Piece.COUNT - 1)
                pieceKeys[square * Piece.COUNT + piece] = nextKey();
        blackToMove = nextKey();
    }
}
