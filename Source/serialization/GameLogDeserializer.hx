package serialization;

import gfx.game.GameInfoBox.Outcome;
import struct.PieceColor;
import struct.Ply;
import struct.Situation;
import struct.PieceType;
import struct.Hex;
import struct.HexTransform;
import struct.ReversiblePly;
using StringTools;

class GameLogDeserializer 
{
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