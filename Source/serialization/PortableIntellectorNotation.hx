package serialization;

import dict.Utils;
import struct.Situation;
import net.shared.PieceColor;
import net.shared.Outcome;
import utils.TimeControl;
import struct.Ply;
using StringTools;

class PortableIntellectorNotation 
{
    public static function serialize(startingSituation:Situation, movesPlayed:Array<Ply>, ?whiteRef:String = "Anonymous", ?blackRef:String = "Anonymous", ?timeControl:TimeControl, ?datetime:Date, ?outcome:Outcome):String
    {
        var pin:String = "";
        var whitePlayer:String = Utils.playerRef(whiteRef);
        var blackPlayer:String = Utils.playerRef(blackRef);
        pin += '#Players: $whitePlayer vs $blackPlayer;\n';
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
            case Decisive(Mate, winnerColor): 
                if (winnerColor == White)
                    pin += 'Fatum. White won';
                else
                    pin += 'Fatum. Black won';
            case Decisive(Breakthrough, winnerColor):
                if (winnerColor == White)
                    pin += 'Breakthrough. White won';
                else
                    pin += 'Breakthrough. Black won';
            case Decisive(Timeout, winnerColor):
                if (winnerColor == White)
                    pin += 'Black lost on time';
                else
                    pin += 'White lost on time';
            case Decisive(Resign, winnerColor):
                if (winnerColor == White)
                    pin += 'Black resigned';
                else
                    pin += 'White resigned';
            case Decisive(Abandon, winnerColor):
                if (winnerColor == White)
                    pin += 'Black left the game';
                else
                    pin += 'White left the game';
            case Drawish(DrawAgreement):
                pin += 'Draw by agreement';
            case Drawish(Repetition):
                pin += 'Draw by repetition';
            case Drawish(NoProgress):
                pin += 'Draw by quiescence';
            case Drawish(Abort):
                pin += 'Game aborted';
            case null:
                pin += '...To be continued';
        }

        return pin;
    }    
}