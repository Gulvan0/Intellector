package analysis;

import struct.PieceColor;
import struct.PieceType;

class ConcreteHex 
{
    public var type:PieceType;
    public var color:PieceColor;
    public var i:Int;
    public var j:Int;

    public function isEmpty():Bool 
    {
        return type == null;    
    }

    public function copy():ConcreteHex
    {
        return new ConcreteHex(i, j, type, color);
    }

    public function new(i, j, type, color) 
    {
        this.i = i;
        this.j = j;
        this.type = type;
        this.color = color;
    }
}