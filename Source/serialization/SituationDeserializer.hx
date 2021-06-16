package serialization;

import struct.PieceColor;
import struct.Hex;
import struct.PieceType;
import struct.Situation;

class SituationDeserializer 
{
    public static function deserialize(serialized:String):Situation
    {
        var field = [for (j in 0...7) [for (i in 0...9) Hex.empty()]];

        var ci = 1;
        while (ci < serialized.length)
        {
            var i = Std.parseInt(serialized.charAt(ci));
            var j = Std.parseInt(serialized.charAt(ci + 1));
            var type = typeByCode(serialized.charAt(ci + 2));
            var color = serialized.charAt(ci + 3) == "w"? White : Black;

            field[j][i] = Hex.occupied(type, color);
            ci += 4;
        }

        var situation:Situation = new Situation();
        situation.figureArray = field;
        situation.turnColor = serialized.charAt(0) == "w"? White : Black;

        return situation;
    }

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