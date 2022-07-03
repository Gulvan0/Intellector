package serialization;

import struct.PieceColor;
import struct.Hex;
import struct.PieceType;
import struct.Situation;
import struct.IntPoint;
import struct.PieceType.letter as pieceLetter;
import struct.PieceColor.letter as colorLetter;

class SituationSerializer 
{
    public static function serialize(situation:Situation):String
    {
        var playerPiecesStr:Map<PieceColor, String> = [White => '', Black => ''];

        for (t in 0...IntPoint.hexCount) 
        {
            var piece = situation.getS(t);
            var pieceStr:String = String.fromCharCode(t + 64) + pieceLetter(piece.type);

            playerPiecesStr[piece.color] += pieceStr;
        }

        return colorLetter(situation.turnColor) + playerPiecesStr[White] + "!" + playerPiecesStr[Black];
    }

    public static function deserialize(sip:String):Null<Situation>
    {
        var situation:Situation = Situation.empty();
        var turnColor:PieceColor = colorByLetter(sip.charAt(0));
        situation.turnColor = turnColor;

        var exclamationMarkPassed:Bool = false;
        var ci = 1;
        while (ci < sip.length)
        {
            if (sip.charCodeAt(ci) == "!".code)
            {
                if (exclamationMarkPassed)
                    return null; //Exactly one exclamation mark per SIP expected

                exclamationMarkPassed = true;
                ci++;
                continue;
            }
            
            var scalarCoord:Int = sip.charCodeAt(ci) - 64;
            var type:PieceType = pieceByLetter(sip.charAt(ci + 1));

            if (scalarCoord < 0 || scalarCoord >= IntPoint.hexCount)
                return null; //Invalid hex location
            else if (type == null)
                return null; //Invalid PieceType code

            var location:IntPoint = IntPoint.fromScalar(scalarCoord);
            var color:PieceColor = exclamationMarkPassed? Black : White;

            situation.set(location, Hex.occupied(type, color));
            ci += 2;
        }

        return situation;
    }
}