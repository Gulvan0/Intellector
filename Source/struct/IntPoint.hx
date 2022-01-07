package struct;

import struct.PieceColor;

function equal(p1:Null<IntPoint>, p2:Null<IntPoint>):Bool
{
    if (p1 == null)
        return p2 == null;
    else if (p2 == null)
        return false;
    else 
        return p1.i == p2.i && p1.j == p2.j;
}

class IntPoint 
{
    public var i:Int;
    public var j:Int;

    public static var allHexCoords:Array<IntPoint> = [for (i in 0...9) for (j in 0...(7 - i % 2)) new IntPoint(i, j)];

    public function equals(p:Null<IntPoint>):Bool
    {
        if (p == null)
            return false;
        return i == p.i && j == p.j;
    }

    public function toScalar():Int
    {
        if (i % 2 == 1)
            return 9 * j + (i - 1) / 2 + 5;
        else
            return 9 * j + i / 2;
    }

    public static function fromScalar(s:Int):IntPoint
    {
        var res = s % 9;
        if (res < 5)
            return new IntPoint(2 * res, (s - res) / 9);
        else
            return new IntPoint(2 * res - 9, (s - res) / 9);
    }

    public function toRelative(color:PieceColor):IntPoint 
    {
        return color == White? copy() : invert();
    }

    public function invert():IntPoint
    {
        return new IntPoint(8 - i, 6 - j - i % 2);
    }

    public function copy():IntPoint
    {
        return new IntPoint(i, j);
    }

    public function isFinalForColor(color:PieceColor):Bool
    {
        if (color == White)
            return j == 0 && i % 2 == 0;
        else 
            return j == 6 && i % 2 == 0;
    }

    public function new(i:Int, j:Int) 
    {
        this.i = i;
        this.j = j;    
    }
}