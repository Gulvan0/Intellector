package client.botengine;

import engine.hxconda.protocol.HxcondaMoveMessage;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;

/**
    Conversions between `intellectorboard` and the engine's Anaconda notation: the 59 squares column by column,
    each column from its last row down to row 0, one letter per square, then `w` or `b` for the side to move.
**/
class AnacondaNotation
{
    /** Squares in two adjacent columns **/
    private static inline final COLUMN_PAIR_SIZE:Int = 13;
    private static inline final LONG_COLUMN_LAST_ROW:Int = 6;
    private static inline final SHORT_COLUMN_LAST_ROW:Int = 5;
    private static inline final COLUMN_COUNT:Int = 9;

    public static function fromPosition(position:Position):String
    {
        var notation:StringBuf = new StringBuf();
        for (i in 0...COLUMN_COUNT)
        {
            var j:Int = i % 2 == 0 ? LONG_COLUMN_LAST_ROW : SHORT_COLUMN_LAST_ROW;
            while (j >= 0)
            {
                var piece:Null<PieceData> = position.getPiece(new HexCoords(i, j));
                notation.add(piece != null ? pieceLetter(piece) : "e");
                j--;
            }
        }
        notation.add(position.turnColor == White ? "w" : "b");
        return notation.toString();
    }

    /** `move` as played in `position`, the position it was found for **/
    public static function toRawPly(move:HxcondaMoveMessage, position:Position):RawPly
    {
        var from:HexCoords = squareToCoords(move.from);
        var to:HexCoords = squareToCoords(move.to);
        var movingPiece:Null<PieceData> = position.getPiece(from);
        var resultingPiece:PieceData = pieceOfCode(move.resultingPiece);

        if (movingPiece == null || movingPiece.equals(resultingPiece))
            return RawPly.construct(from, to);
        else
            return RawPly.construct(from, to, resultingPiece.type);
    }

    public static function squareToCoords(square:Int):HexCoords
    {
        var pair:Int = Math.floor(square / COLUMN_PAIR_SIZE);
        var offset:Int = square - pair * COLUMN_PAIR_SIZE;
        if (offset > LONG_COLUMN_LAST_ROW)
            return new HexCoords(2 * pair + 1, COLUMN_PAIR_SIZE - 1 - offset);
        else
            return new HexCoords(2 * pair, LONG_COLUMN_LAST_ROW - offset);
    }

    private static function pieceLetter(piece:PieceData):String
    {
        var letter:String = switch piece.type {
            case Progressor: "p";
            case Aggressor: "a";
            case Dominator: "m";
            case Liberator: "l";
            case Defensor: "d";
            case Intellector: "i";
        }
        return piece.color == White ? letter : letter.toUpperCase();
    }

    /** See `engine.hxconda.board.Piece`: white pieces have even codes, each black one the next odd code **/
    private static function pieceOfCode(code:Int):PieceData
    {
        var kind:PieceKind = switch code >> 1 {
            case 0: Progressor;
            case 1: Dominator;
            case 2: Liberator;
            case 3: Aggressor;
            case 4: Defensor;
            case 5: Intellector;
            default: throw 'Unexpected piece code: $code';
        }
        var color:PieceColor = code % 2 == 0 ? White : Black;
        return new PieceData(kind, color);
    }
}
