package serialization;

import struct.PieceColor;
import struct.Hex;
import struct.PieceType;
import struct.Situation;
import struct.IntPoint;

class SituationDeserializer 
{
    public static function deserialize(sip:String):Situation
    {
        var situation:Situation = Situation.empty();
        var turnColor:PieceColor = sip.charAt(0) == "w"? White : Black;
        situation.setTurnWithZobris(turnColor);

        var ci = 1;
        while (ci < sip.length)
        {
            var i = Std.parseInt(sip.charAt(ci));
            var j = Std.parseInt(sip.charAt(ci + 1));
            var type = typeByCode(sip.charAt(ci + 2));
            var color = sip.charAt(ci + 3) == "w"? White : Black;

            situation.setWithZobris(new IntPoint(i, j), Hex.occupied(type, color), Hex.empty());
            ci += 4;
        }

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