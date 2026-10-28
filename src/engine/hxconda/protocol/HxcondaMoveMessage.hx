package engine.hxconda.protocol;

typedef HxcondaMoveMessage = {
    /** Square index, see `BoardGeometry` **/
    var from:Int;
    var to:Int;
    /** Code of the piece standing on `to` after the move, see `Piece` **/
    var resultingPiece:Int;
}
