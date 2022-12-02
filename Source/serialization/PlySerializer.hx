package serialization;

import net.shared.PieceType;

class PlySerializer 
{

    public static function deserialize(serialized:String):Ply
    {
        var ply:Ply = new Ply();
        ply.from = new IntPoint(Std.parseInt(serialized.charAt(0)), Std.parseInt(serialized.charAt(1)));
        ply.to = new IntPoint(Std.parseInt(serialized.charAt(2)), Std.parseInt(serialized.charAt(3)));
        ply.morphInto = serialized.length == 4? null : PieceType.createByName(serialized.substr(4));
        return ply;
    }

    public static function serialize(ply:Ply):String
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