package serialization;

import struct.Situation;
import struct.Ply;
import struct.PieceType;
import struct.ReversiblePly;

class PlyDeserializer 
{

    public static function deserialize(serialized:String):Ply
    {
        var ply:Ply = new Ply();
        ply.from = new IntPoint(Std.parseInt(serialized.charAt(0)), Std.parseInt(serialized.charAt(1)));
        ply.to = new IntPoint(Std.parseInt(serialized.charAt(2)), Std.parseInt(serialized.charAt(3)));
        ply.morphInto = serialized.length == 4? null : PieceType.createByName(serialized.substr(4));
        return ply;
    }
    
}