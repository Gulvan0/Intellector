package net.shared.converters;

import net.shared.board.RawPly;
import net.shared.board.HexCoords;

class PlySerializer 
{
    public static function deserialize(serialized:String):RawPly
    {
        var ply:RawPly = new RawPly();
        ply.from = new HexCoords(Std.parseInt(serialized.charAt(0)), Std.parseInt(serialized.charAt(1)));
        ply.to = new HexCoords(Std.parseInt(serialized.charAt(2)), Std.parseInt(serialized.charAt(3)));
        ply.morphInto = serialized.length == 4? null : PieceType.createByName(serialized.substr(4));
        return ply;
    }

    public static function serialize(ply:RawPly):String
    {
        var s:String = "";
        s += ply.from.i;
        s += ply.from.j;
        s += ply.to.i;
        s += ply.to.j;
        s += ply.morphInto == null? "" : ply.morphInto.getName();
        return s;
    }
    
}