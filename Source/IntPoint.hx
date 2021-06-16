package;

import struct.PieceColor;

class IntPoint 
{
    public var i:Int;
    public var j:Int;

    public static var allHexCoords:Array<IntPoint> = [for (i in 0...9) for (j in 0...(7 - i % 2)) new IntPoint(i, j)];

    public function equals(p:IntPoint):Bool
    {
        if (p == null)
            return false;
        return i == p.i && j == p.j;
    }

    public function toRelative(color:PieceColor):IntPoint 
    {
        return color == White? copy() : invert();
    }

    public function invert():IntPoint
    {
        return new IntPoint(i, 6 - j - i % 2);
    }

    public function copy():IntPoint
    {
        return new IntPoint(i, j);
    }

    public function new(i:Int, j:Int) 
    {
        this.i = i;
        this.j = j;    
    }
}