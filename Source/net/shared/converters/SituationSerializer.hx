package net.shared.converters;

import net.shared.board.PieceData;
import net.shared.board.PieceArrangement;
import net.shared.board.HexCoords;
import net.shared.PieceType.letter as pieceLetter;
import net.shared.PieceColor.letter as colorLetter;
import net.shared.PieceType;
import net.shared.PieceColor;
import net.shared.board.Situation;

class SituationSerializer 
{
    public static function deserialize(sip:String):Null<Situation>
    {
        var pieces:PieceArrangement = PieceArrangement.emptyArrangement();
        var turnColor:PieceColor = colorByLetter(sip.charAt(0));
        var intellectorPos:Map<PieceColor, HexCoords> = [];

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
            if (scalarCoord < 0 || scalarCoord >= 59)
                return null; //Invalid hex location

            var pieceType:Null<PieceType> = pieceByLetter(sip.charAt(ci + 1));
            var pieceColor:PieceColor = exclamationMarkPassed? Black : White;

            if (pieceType == null)
                return null; //Invalid PieceType code
            else
            {
                var coords:HexCoords = HexCoords.fromScalarCoord(scalarCoord);
                pieces.set(coords, Occupied(new PieceData(pieceType, pieceColor)));
                if (pieceType == Intellector)
                    if (intellectorPos.exists(pieceColor))
                        return null;
                    else
                        intellectorPos.set(pieceColor, coords);
            }

            ci += 2;
        }

        return new Situation(pieces, turnColor, intellectorPos);
    }

    public static function serialize(situation:Situation):String
    {
		var playerPiecesStr:Map<PieceColor, String> = [White => '', Black => ''];
        
        for (hexData in situation.collectPiecesStable()) 
        {
            var pieceStr:String = String.fromCharCode(hexData.scalarCoord + 64) + pieceLetter(hexData.piece.type);

            playerPiecesStr[hexData.piece.color] += pieceStr;
        }

        return colorLetter(situation.turnColor) + playerPiecesStr[White] + "!" + playerPiecesStr[Black];
	}    
}