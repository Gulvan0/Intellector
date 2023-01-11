package net.shared.board;

import net.shared.board.PieceData;

enum InternalHex
{
    Empty;
    Occupied(piece:PieceData);
}

@:forward abstract Hex(InternalHex) from InternalHex to InternalHex
{
    public function type():Null<PieceType>  
    {
        return switch this
        {
            case Empty: null;
            case Occupied(piece): piece.type;
        }
    }

    public function color():Null<PieceColor>  
    {
        return switch this
        {
            case Empty: null;
            case Occupied(piece): piece.color;
        }
    }

    public function piece():Null<PieceData>  
    {
        return switch this
        {
            case Empty: null;
            case Occupied(piece): piece;
        }
    }

    public function isEmpty():Bool
    {
        return this.match(Empty);
    }

    public function equals(otherHex:Hex):Bool
    {
        return switch this
        {
            case Empty: otherHex.isEmpty();
            case Occupied(piece): piece.color == otherHex.color() && piece.type == otherHex.type();
        }
    }

    public static function construct(type:PieceType, color:PieceColor):Hex
    {
        return Occupied(new PieceData(type, color));
    }
}