package;

import struct.PieceType;

class Notation 
{
    public static inline function pieceAbbreviation(piece:PieceType, progressorNonEmpty:Bool = false):String
    {
        return switch piece 
        {
            case Progressor: progressorNonEmpty? "P" : "";
            case Aggressor: "A";
            case Dominator: "D";
            case Liberator: "L";
            case Defensor: "F";
            case Intellector: "I";
        }
    }

    public static inline function pieceFromAbbreviation(abb:String):PieceType
    {
        return switch abb 
        {
            case "": Progressor;
            case "P": Progressor;
            case "A": Aggressor;
            case "D": Dominator;
            case "L": Liberator;
            case "F": Defensor;
            case "I": Intellector;
            default: null;
        }
    }

    public static function hexNotation(pos:IntPoint):String
    {
        return getColumn(pos.i) + getRow(pos.i, pos.j);
    }

    public static function parseIntPoint(s:String):IntPoint
    {
        s = s.toLowerCase();
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