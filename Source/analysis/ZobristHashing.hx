package analysis;

import struct.Situation;
import struct.PieceColor;
import haxe.io.Bytes;
import haxe.crypto.Md5;
import struct.PieceType;
import haxe.Int64;

class ZobristHashing 
{
    public static var hashes:Array<Int64> = [];
    public static var startPosHash:Int64;
    
    public static function init() 
    {
        hashes.push(fromSeed('BLACKTOMOVEHASH'));
        var types = [Progressor, Aggressor, Defensor, Liberator, Dominator, Intellector];
        for (t in 0...types.length)
            for (j in 0...7)
                for (i in 0...9)
                    for (c in [1, 0])
                        hashes.push(fromSeed('GULVAN$t$j$i$c'));
        startPosHash = 0;
        var startingSituation:Situation = Situation.starting();
        for (hex in startingSituation.collectOccupiedFast())
            startPosHash ^= getForPiece(hex.i, hex.j, hex.type, hex.color);
    }

    public static inline function getForPiece(i:Int, j:Int, type:PieceType, color:PieceColor):Int64
    {
        return hashes[1 + typeNumber(type) * 126 + colorNumber(color) * 63 + j * 9 + i];
    }

    private static inline function typeNumber(type:PieceType):Int 
    {
        return switch type 
        {
            case Progressor: 0;
            case Aggressor: 1;
            case Dominator: 2;
            case Liberator: 3;
            case Defensor: 4;
            case Intellector: 5;
        }
    }

    private static inline function colorNumber(color:PieceColor) 
    {
        return color == White? 1 : 0;    
    }

    private static function fromSeed(seed:String):Int64
    {
        var fullhash:String = Md5.encode(seed);
        var highhash:String = fullhash.substr(0, 8);
        var lowhash:String = fullhash.substr(8, 8);
        return Int64.make(Std.parseInt("0x" + highhash), Std.parseInt("0x" + lowhash));    
    }
}