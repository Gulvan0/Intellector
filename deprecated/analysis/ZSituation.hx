package analysis;

import haxe.Int64;
import struct.Situation;

class ZSituation extends Situation
{
    public var zobristHash(default, null):Int64;
    
    //TODO: Implement
    /*public static function starting():ZSituation
    {
        + zsituation.zobristHash = ZobristHashing.startPosHash.copy();
    }

    public static function empty():ZSituation
    {
        + zsituation.zobristHash = ZobristHashing.emptyHash;
    }

    public override function makeMove(ply:Ply):ZSituation 
    {
        + next.zobristHash ^= ZobristHashing.hashes[0];
    }

    public inline function setWithZobris(coords:IntPoint, hex:Hex, formerHex:Hex) 
    {
        set(coords, hex);
        if (!formerHex.isEmpty())
            zobristHash ^= ZobristHashing.getForPiece(coords.i, coords.j, formerHex.type, formerHex.color);
        if (!hex.isEmpty())
        {
            zobristHash ^= ZobristHashing.getForPiece(coords.i, coords.j, hex.type, hex.color);
            if (hex.type == Intellector)
                intellectorPos[hex.color] = coords.copy();
        }
        else if (formerHex.type == Intellector && intellectorPos[formerHex.color].equals(coords))
            intellectorPos[formerHex.color] = null;
    }

    public function setTurnWithZobris(color:PieceColor) 
    {
        if (turnColor == null && color == Black)
            zobristHash ^= ZobristHashing.hashes[0];
        else if (turnColor != color)
            zobristHash ^= ZobristHashing.hashes[0];
        turnColor = color;
    }

    public function collectOccupiedFast():Array<ConcreteHex>
    {
        var arr = [];
        for (t in 0...IntPoint.hexCount)
            
                var hex = getC(i, j);
                if (hex.type != null)
                    arr.push(new ConcreteHex(i, j, hex.type, hex.color));
            }
            
        return arr;
    }

    public function copy():Situation 
    {
        + s.zobristHash = zobristHash.copy();
    }

    public function new() 
    {
        super();    
    }
}