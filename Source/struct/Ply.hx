package struct;

class Ply 
{
    public var from:IntPoint;
    public var to:IntPoint;
    public var morphInto:Null<PieceType>;

    public static function fromNotation(plyStr:String, context:Situation):Ply
    {
        var ply:Ply = new Ply();

        if (plyStr.substr(0, 3) == "O-O")
        {
            ply.morphInto = null;

            var addend:String = plyStr.substr(3);

            for (p => hex in context.collectOccupiedHexes())
                if (hex.color == context.turnColor && hex.type == Intellector)
                {
                    ply.from = p.copy();
                    break;
                }
            
            if (addend == "")
            {
                for (p in Rules.possibleFields(ply.from, context.get))
                    if (context.get(p).type == Defensor)
                    {
                        ply.to = p.copy();
                        break;
                    }
            }
            else
                ply.to = Notation.parseIntPoint(addend);
        }
        else
        {
            var movingPiece:PieceType;

            if (plyStr.charAt(0) == "P")
            {
                movingPiece = Progressor;
                plyStr = plyStr.substr(1);
            }
            else
            {
                movingPiece = Notation.pieceFromAbbreviation(plyStr.substr(0, 2));
                plyStr = plyStr.substr(2);
            }

            if (StringTools.contains(plyStr, ":") || (StringTools.contains(plyStr, "x") && plyStr.charAt(0) != "x"))
            {
                ply.from = Notation.parseIntPoint(plyStr.substr(0, 2));
                plyStr = plyStr.substr(2);
                if (plyStr.charAt(0) == "x" || plyStr.charAt(0) == ":")
                    plyStr = plyStr.substr(1);
                ply.to = Notation.parseIntPoint(plyStr.substr(0, 2));
                plyStr = plyStr.substr(2);
            }
            else
            {
                if (plyStr.charAt(0) == "x")
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
                if (plyStr.charAt(2) == "P")
                    ply.morphInto = Progressor;
                else
                    ply.morphInto = Notation.pieceFromAbbreviation(plyStr.substr(2, 2));
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
        {
            var intellectorLocation:IntPoint;
            var defensorLocation:IntPoint;
            if (hexTo.type == Intellector)
            {
                intellectorLocation = to;
                defensorLocation = from;
            }
            else 
            {
                intellectorLocation = from;
                defensorLocation = to;
            }

            var anotherDefensorLocation = null;
            for (p in Rules.possibleFields(intellectorLocation, context.get))
                if (!p.equals(defensorLocation))
                    if (!context.get(p).isEmpty())
                    {
                        anotherDefensorLocation = p.copy();
                        break;
                    }
            if (anotherDefensorLocation != null)
                return "O-O" + Notation.hexNotation(defensorLocation);
            else 
                return "O-O";
        }

        var str:String = "";

        var another = null;
        for (p => hex in context.collectOccupiedHexes())
            if (!p.equals(from))
                if (hex.type == hexFrom.type && hex.color == hexFrom.color)
                    if (Lambda.exists(Rules.possibleFields(p, context.get), to.equals))
                    {
                        another = p.copy();
                        break;
                    }

        str += Notation.pieceAbbreviation(hexFrom.type);
        if (another != null)
            str += Notation.hexNotation(from);

        if (capture)
            str += "x";
        else if (another != null)
            str += ":";

        str += Notation.hexNotation(to);

        if (morphInto != null)
            str += '=[${Notation.pieceAbbreviation(morphInto)}]';

        if (mate)
            str += "#";

        return str;
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