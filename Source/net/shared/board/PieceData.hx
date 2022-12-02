package net.shared.board;

class PieceData
{
    public final type:PieceType;
    public final color:PieceColor;

    public function toString():String
    {
        return '[$type;$color]';
    }

    public function new(type:PieceType, color:PieceColor)
    {
        if (type == null || color == null)
            throw "type/color can't be null";
        this.type = type;
        this.color = color;
    }
}