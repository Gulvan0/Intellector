package testutils;

import intellectorboard.primitives.hex.HexCoords;

class Hexes
{
    public static function hex(i:Int, j:Int):HexCoords
    {
        return new HexCoords(i, j);
    }
}
