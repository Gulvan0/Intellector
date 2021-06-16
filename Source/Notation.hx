package;

import struct.PieceType;

class Notation 
{
    public static inline function pieceAbbreviation(piece:PieceType):String
    {
        return switch piece 
        {
            case Progressor: "P";
            case Aggressor: "Ag";
            case Dominator: "Dm";
            case Liberator: "Lb";
            case Defensor: "Df";
            case Intellector: "In";
        }
    }

    public static inline function pieceFromAbbreviation(abb:String):PieceType
    {
        return switch abb 
        {
            case "P": Progressor;
            case "Ag": Aggressor;
            case "Dm": Dominator;
            case "Lb": Liberator;
            case "Df": Defensor;
            case "In": Intellector;
            default: null;
        }
    }

    public static function hexNotation(pos:IntPoint):String
    {
        return getColumn(pos.i) + getRow(pos.i, pos.j);
    }

    public static function parseIntPoint(s:String):IntPoint
    {
        var i = s.charCodeAt(0) - 'a'.code;
        var j = 7 - Std.parseInt(s.charAt(1)) - i % 2;
        return new IntPoint(i, j);
    }

    public static function getColumn(i:Int):String
    {
        return String.fromCharCode('a'.code + i);
    }

    public static function getRow(i:Int, j:Int):String
    {
        var rowNum = 7 - j - i % 2;
        return '$rowNum';
    }
}