package utils;

import struct.Situation;
import struct.Ply;
import struct.PieceType;
import struct.IntPoint;
using StringTools;

class Notation 
{
    public static function plyFromNotation(plyStr:String, context:Situation):Ply
    {
        var ply:Ply = new Ply();

        if (plyStr.contains(":"))
        {
            var splitted = plyStr.split(":");

            ply.from = Notation.parseIntPoint(splitted[0]);
            ply.to = Notation.parseIntPoint(splitted[1]);
            ply.morphInto = null;
        }
        else
        {
            var movingPiece:PieceType;

            if (["P", "A", "D", "L", "F", "I"].contains(plyStr.charAt(0)))
            {
                movingPiece = Notation.pieceFromAbbreviation(plyStr.charAt(0));
                plyStr = plyStr.substr(1);
                
            }
            else
                movingPiece = Progressor;

            if (plyStr.contains("~") || (plyStr.contains("X") && plyStr.charAt(0) != "X"))
            {
                ply.from = Notation.parseIntPoint(plyStr.substr(0, 2));
                plyStr = plyStr.substr(3);
                ply.to = Notation.parseIntPoint(plyStr.substr(0, 2));
                plyStr = plyStr.substr(2);
            }
            else
            {
                if (plyStr.charAt(0) == "X")
                    plyStr = plyStr.substr(1);

                ply.to = Notation.parseIntPoint(plyStr.substr(0, 2));
                plyStr = plyStr.substr(2);

                for (p => hex in context.collectOccupiedHexes())
                    if (hex.color == context.turnColor && hex.type == movingPiece)
                        if (Lambda.exists(Rules.possibleFields(p, context.get), p -> p.equals(ply.to)))
                        {
                            ply.from = p.copy();
                            break;
                        }
            }

            if (plyStr.charAt(0) == "=")
                ply.morphInto = Notation.pieceFromAbbreviation(plyStr.charAt(1));
        }

        return ply;
    }

    public static function plyToNotation(ply:Ply, context:Situation, ?indicateColor:Bool):String
    {
        var hexFrom = context.get(ply.from);
        var hexTo = context.get(ply.to);

        var castle = hexFrom.color == hexTo.color;
        var capture = !castle && !hexTo.isEmpty();
        var mate = capture && hexTo.type == Intellector;

        var str:String = "";

        if (indicateColor)
            if (context.turnColor == White)
                str += '⬡';
            else 
                str += '⬢';

        if (castle)
            return str + Notation.hexNotation(ply.from).toUpperCase() + ":" + Notation.hexNotation(ply.to).toUpperCase();

        str += Notation.pieceAbbreviation(hexFrom.type);

        var another = null;
        for (p => hex in context.collectOccupiedHexes())
            if (!p.equals(ply.from))
                if (hex.type == hexFrom.type && hex.color == hexFrom.color)
                    if (Lambda.exists(Rules.possibleFields(p, context.get), ply.to.equals))
                    {
                        another = p.copy();
                        break;
                    }

        if (another != null)
            str += Notation.hexNotation(ply.from);

        if (capture)
            str += "X";
        else if (another != null)
            str += "~";

        str += Notation.hexNotation(ply.to);

        if (ply.morphInto != null)
            str += '=${Notation.pieceAbbreviation(ply.morphInto, true)}';

        if (mate)
            str += "#";

        return str;
    }

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