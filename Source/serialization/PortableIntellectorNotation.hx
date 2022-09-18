package serialization;

import struct.Situation;
import struct.PieceColor;
import struct.Outcome;
import utils.TimeControl;
import struct.Ply;
using StringTools;

class PortableIntellectorNotation 
{
    public static function serialize(startingSituation:Situation, movesPlayed:Array<Ply>, ?whiteLogin:String = "Anonymous", ?blackLogin:String = "Anonymous", ?timeControl:TimeControl, ?datetime:Date, ?outcome:Outcome):String
    {
        var pin:String = "";
        if (whiteLogin.startsWith("guest_"))
            whiteLogin = "Unknown Guest";
        if (blackLogin.startsWith("guest_"))
            blackLogin = "Unknown Guest";
        pin += '#Players: $whiteLogin vs $blackLogin;\n';
        if (timeControl != null)
            pin += '#TimeControl: ${timeControl.toString()};\n';
        if (datetime != null)
            pin += '#DateTime: ${datetime.toString()};\n';

        var startingSIP:String = startingSituation.serialize();
        if (startingSIP != Situation.starting().serialize())
            pin += '#CustomStartPosSIP: $startingSIP;\n';

        var moveNum:Int = 1;
        var situation:Situation = startingSituation;
        for (ply in movesPlayed)
        {
            var plyStr:String = ply.toNotation(situation, false);
            pin += '$moveNum. $plyStr;\n';
            situation.makeMove(ply, true);
            moveNum++;
        }

        switch outcome 
        {
            case Mate(winnerColor): 
                if (winnerColor == White)
                    pin += 'Fatum. White won';
                else if (winnerColor == Black)
                    pin += 'Fatum. Black won';
                else 
                    pin += 'Fatum';
            case Breakthrough(winnerColor):
                if (winnerColor == White)
                    pin += 'Breakthrough. White won';
                else if (winnerColor == Black)
                    pin += 'Breakthrough. Black won';
                else 
                    pin += 'Breakthrough';
            case Timeout(winnerColor):
                if (winnerColor == White)
                    pin += 'Black lost on time';
                else if (winnerColor == Black)
                    pin += 'White lost on time';
            case Resign(winnerColor):
                if (winnerColor == White)
                    pin += 'Black resigned';
                else if (winnerColor == Black)
                    pin += 'White resigned';
            case Abandon(winnerColor):
                if (winnerColor == White)
                    pin += 'Black left the game';
                else if (winnerColor == Black)
                    pin += 'White left the game';
            case DrawAgreement:
                pin += 'Draw by agreement';
            case Repetition:
                pin += 'Draw by repetition';
            case NoProgress:
                pin += 'Draw by quiescence';
            case Abort:
                pin += 'Game aborted';
            case null:
        }

        return pin;
    }    
}