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

        var exclamationMarkPassed:Bool = false;
        var ci = 1;
        while (ci < sip.length)
        {
            if (sip.charCodeAt(ci) == "!".code)
            {
                exclamationMarkPassed = true;
                ci++;
                continue;
            }
            var t = sip.charCodeAt(ci) - 64;
            var i = t % 9;
            var j = cast((t - i) / 9, Int);
            var type = typeByCode(sip.charAt(ci + 1));
            var color = exclamationMarkPassed? Black : White;

            situation.setWithZobris(new IntPoint(i, j), Hex.occupied(type, color), Hex.empty());
            ci += 2;
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