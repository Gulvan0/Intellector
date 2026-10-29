package engine.hxconda.board;

import js.lib.Int8Array;

/**
    The piece on each square, as piece codes in a typed array.
**/
abstract PieceArray(Int8Array)
{
    @:arrayAccess
    private inline function get(square:Int):Piece
    {
        return cast this[square];
    }

    @:arrayAccess
    private inline function set(square:Int, piece:Piece):Piece
    {
        this[square] = piece;
        return piece;
    }

    /** All squares empty **/
    public inline function new(squareCount:Int)
    {
        this = new Int8Array(squareCount);
        this.fill(Piece.Empty);
    }
}
