package net.shared.converters;

import net.shared.board.Rules;
import net.shared.board.RawPly;
import net.shared.board.HexCoords;
import net.shared.board.Situation;
import net.shared.PieceType;
import net.shared.PieceColor;

using StringTools;

class Notation 
{
    public static function plySequenceToNotation(plys:Array<RawPly>, startingSituation:Situation):Array<String>
    {
        var plyStrSeq = [];
        var situation = startingSituation.copy();

        for (ply in plys)
        {
            plyStrSeq.push(ply.toNotation(situation));
            situation.performRawPly(ply);
        }

        return plyStrSeq;
    }

    public static function plyFromNotation(plyStr:String, context:Situation):RawPly
    {
        var ply:RawPly = new RawPly();

        if (plyStr.contains(":"))
        {
            var splitted = plyStr.split(":");

            ply.from = Notation.parseHexCoords(splitted[0]);
            ply.to = Notation.parseHexCoords(splitted[1]);
            ply.morphInto = null;

            return ply;
        }
        else
        {
            var movingPiece:PieceType = Notation.pieceFromAbbreviation(plyStr.charAt(0));

            if (movingPiece == null)
                movingPiece = Progressor;
            else
                plyStr = plyStr.substr(1);

            if (plyStr.contains("~") || (plyStr.contains("X") && plyStr.charAt(0) != "X"))
            {
                ply.from = Notation.parseHexCoords(plyStr.substr(0, 2));
                plyStr = plyStr.substr(3);
                ply.to = Notation.parseHexCoords(plyStr.substr(0, 2));
                plyStr = plyStr.substr(2);

                if (plyStr.charAt(0) == "=")
                    ply.morphInto = Notation.pieceFromAbbreviation(plyStr.charAt(1));

                return ply;
            }
            else
            {
                if (plyStr.charAt(0) == "X")
                    plyStr = plyStr.substr(1);

                ply.to = Notation.parseHexCoords(plyStr.substr(0, 2));
                plyStr = plyStr.substr(2);

                if (plyStr.charAt(0) == "=")
                    ply.morphInto = Notation.pieceFromAbbreviation(plyStr.charAt(1));

                for (coords => piece in context.collectPieces())
                    if (piece.color == context.turnColor && piece.type == movingPiece)
                    {
                        ply.from = coords;
                        if (Rules.isPossible(ply, context))
                            return ply;
                    }

                return null;
            }
        }
    }

    public static function plyToNotation(ply:RawPly, context:Situation, ?indicateColor:Bool = false, ?displayedPlyNum:Null<Int>):String
    {
        var hexFrom = context.get(ply.from);
        var hexTo = context.get(ply.to);

        var castle = hexFrom.color() == hexTo.color();
        var capture = !castle && !hexTo.isEmpty();
        var mate = capture && hexTo.type() == Intellector;

        var str:String = "";

        if (indicateColor)
            if (context.turnColor == White)
                str += '⬡';
            else 
                str += '⬢';

        if (displayedPlyNum != null)
            str += '$displayedPlyNum. ';

        if (castle)
            if (hexTo.type() == Intellector)
                return str + Notation.hexNotation(ply.to).toUpperCase() + ":" + Notation.hexNotation(ply.from).toUpperCase();
            else
                return str + Notation.hexNotation(ply.from).toUpperCase() + ":" + Notation.hexNotation(ply.to).toUpperCase();

        str += Notation.pieceAbbreviation(hexFrom.type());

        var another = null;
        for (coords => piece in context.collectPieces())
            if (!coords.equals(ply.from))
                if (piece.type == hexFrom.type() && piece.color == hexFrom.color())
                    if (Lambda.exists(Rules.getPossibleDestinations(coords, context.pieces), ply.to.equals))
                    {
                        another = coords;
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

    public static function hexNotation(pos:HexCoords):String
    {
        return getColumn(pos.i) + getRow(pos.i, pos.j);
    }

    public static function parseHexCoords(s:String):HexCoords
    {
        s = s.toLowerCase();
        var i = s.charCodeAt(0) - 'a'.code;
        var j = 7 - Std.parseInt(s.charAt(1)) - i % 2;
        return new HexCoords(i, j);
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