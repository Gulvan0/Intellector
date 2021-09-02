package serialization;

import struct.PieceColor;
import struct.Hex;
import struct.PieceType;
import struct.Situation;

class SituationDeserializer 
{
    //! Deprecated: doesn't set intellector pos & doesn't set empty hexes
    /*public static function deserialize(serialized:String):Situation
    {
        var situation:Situation = Situation.starting();
        situation.turnColor = serialized.charAt(0) == "w"? White : Black;

        var ci = 1;
        while (ci < serialized.length)
        {
            var i = Std.parseInt(serialized.charAt(ci));
            var j = Std.parseInt(serialized.charAt(ci + 1));
            var type = typeByCode(serialized.charAt(ci + 2));
            var color = serialized.charAt(ci + 3) == "w"? White : Black;

            situation.setC(i, j, Hex.occupied(type, color));
            ci += 4;
        }

        return situation;
    }*/

    public static function typeByCode(c:String):PieceType 
    {
        return switch c
        {
            case "r": Progressor;
            case "g": Aggressor;
            case "o": Dominator;
            case "e": Defensor;
            case "i": Liberator;
            case "n": Intellector;
            default: null;
        }
    }
}