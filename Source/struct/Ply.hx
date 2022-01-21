package struct;
import utils.Notation;
using StringTools;

class Ply 
{
    public var from:IntPoint;
    public var to:IntPoint;
    public var morphInto:Null<PieceType>;

    public static function construct(from:IntPoint, to:IntPoint, ?morphInto:PieceType) 
    {
        var ply:Ply = new Ply();
        ply.from = from;
        ply.to = to;
        ply.morphInto = morphInto;
        return ply;
    }

    public static function plySequenceToNotation(plys:Array<Ply>, startingSituation:Situation):Array<String>
    {
        var plyStrSeq = [];
        var situation = startingSituation.copy();

        for (ply in plys)
        {
            plyStrSeq.push(ply.toNotation(situation));
            situation = situation.makeMove(ply);
        }

        return plyStrSeq;
    }

    public static function fromNotation(plyStr:String, context:Situation):Ply
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

    public function toNotation(context:Situation):String
    {
        var hexFrom = context.get(from);
        var hexTo = context.get(to);

        var castle = hexFrom.color == hexTo.color;
        var capture = !castle && !hexTo.isEmpty();
        var mate = capture && hexTo.type == Intellector;

        if (castle)
            return Notation.hexNotation(from).toUpperCase() + ":" + Notation.hexNotation(to).toUpperCase();

        var str:String = "";

        str += Notation.pieceAbbreviation(hexFrom.type);

        var another = null;
        for (p => hex in context.collectOccupiedHexes())
            if (!p.equals(from))
                if (hex.type == hexFrom.type && hex.color == hexFrom.color)
                    if (Lambda.exists(Rules.possibleFields(p, context.get), to.equals))
                    {
                        another = p.copy();
                        break;
                    }

        if (another != null)
            str += Notation.hexNotation(from);

        if (capture)
            str += "X";
        else if (another != null)
            str += "~";

        str += Notation.hexNotation(to);

        if (morphInto != null)
            str += '=${Notation.pieceAbbreviation(morphInto, true)}';

        if (mate)
            str += "#";

        return str;
    }

    public function modifiedHexes():Array<IntPoint>
    {
        return [from.copy(), to.copy()];
    }

    public function copy():Ply
    {
        var ply:Ply = new Ply();
        ply.from = this.from;
        ply.to = this.to;
        ply.morphInto = this.morphInto;
        return ply;    
    }

    public function equals(p:Ply):Bool
    {
        return this.from == p.from && this.to == p.to && this.morphInto == p.morphInto;
    }

    public function toReversible(context:Situation):ReversiblePly
    {
        var reversible:ReversiblePly = [];

        var current:Situation = context.copy();
        var forecasted:Situation = context.makeMove(this);

        var formerFrom:Hex = current.get(from);
        var formerTo:Hex = current.get(to);
        var latterFrom:Hex = forecasted.get(from);
        var latterTo:Hex = forecasted.get(to);

        reversible.push(new HexTransform(from, formerFrom, latterFrom));
        reversible.push(new HexTransform(to, formerTo, latterTo));

        return reversible;
    }

    public function new() 
    {
        
    }
}