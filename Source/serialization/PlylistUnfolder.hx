package serialization;

import struct.Ply;
import struct.Situation;
import struct.PieceType;
import struct.Hex;
import struct.HexTransform;
import struct.ReversiblePly;
using StringTools;

class PlylistUnfolder 
{
    public static function unfold(gameLog:String):Array<ReversiblePly> 
    {
        var game:Array<ReversiblePly> = [];
        var situation:Situation = Situation.starting();

        var lines:Array<String> = gameLog.split(";");
        
        for (line in lines)
        {
            line = line.trim();
            if (line.charCodeAt(0) < "0".code || line.charCodeAt(0) > "9".code)
                continue;

            var ply:Ply = PlyDeserializer.deserialize(line);
            game.push(ply.toReversible(situation));
            situation.makeMove(ply);
        }

        return game;
    }
}