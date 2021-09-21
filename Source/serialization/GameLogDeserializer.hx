package serialization;

import struct.PieceColor;
import gfx.components.gamefield.modules.GameInfoBox.Outcome;
import struct.Ply;
import struct.Situation;
import struct.PieceType;
import struct.Hex;
import struct.HexTransform;
import struct.ReversiblePly;
using StringTools;

class GameLogDeserializer 
{
    public static function unfold(gameLog:String):Array<ReversiblePly> 
    {
        var game:Array<ReversiblePly> = [];
        /*var situation:Situation = Situation.starting();

        var lines:Array<String> = gameLog.split(";");
        
        for (line in lines)
        {
            line = line.trim();
            if (line.charCodeAt(0) < "0".code || line.charCodeAt(0) > "9".code)
                continue;

            var ply:Ply = PlyDeserializer.deserialize(line);
            game.push(ply.toReversible(situation));
            situation = situation.makeMove(ply);
        }*/
        throw "Deprecated";
        return game;
    }

    public static function decodeOutcome(reasonCode:String, ?winnerLetter:String):Null<Outcome>
    {
        return switch reasonCode 
        {
            case "mat": Mate;
            case "bre": Breakthrough;
            case "res": Resign;
            case "tim": Timeout;
            case "aba": Abandon;
            case "rep": Repetition;
            case "100": NoProgress;
            case "agr": DrawAgreement;
            case "abo": Abort; 
            default: null;
        }
    }

    public static function decodeColor(letter:String):Null<PieceColor> 
    {
        return switch letter 
        {
            case "w": White;
            case "b": Black;
            default: null;
        }
    }
}