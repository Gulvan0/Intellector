package struct;

import analysis.ZobristHashing;
import haxe.Int64;
import analysis.ConcreteHex;
import struct.PieceColor.letter;
import js.html.Window;
import analysis.PieceValues;
import struct.PieceColor.opposite;

class Situation 
{
    private var figureArray:Array<Hex>;
    public var turnColor(default, null):PieceColor;
    public var zobristHash(default, null):Int64;

    private var intellectorPos:Map<PieceColor, Null<IntPoint>>;

    public static function starting():Situation
    {
        var situation = new Situation();
        situation.turnColor = White;
        situation.intellectorPos = [White => new IntPoint(4, 6), Black => new IntPoint(4, 0)];
        situation.zobristHash = ZobristHashing.startPosHash.copy();
        situation.figureArray = [for (t in 0...63) Hex.empty()];

        situation.setC(0, 0, Hex.occupied(Dominator, Black));
        situation.setC(1, 0, Hex.occupied(Liberator, Black));
        situation.setC(2, 0, Hex.occupied(Aggressor, Black));
        situation.setC(3, 0, Hex.occupied(Defensor, Black));
        situation.setC(4, 0, Hex.occupied(Intellector, Black));
        situation.setC(5, 0, Hex.occupied(Defensor, Black));
        situation.setC(6, 0, Hex.occupied(Aggressor, Black));
        situation.setC(7, 0, Hex.occupied(Liberator, Black));
        situation.setC(8, 0, Hex.occupied(Dominator, Black));
        situation.setC(0, 1, Hex.occupied(Progressor, Black));
        situation.setC(2, 1, Hex.occupied(Progressor, Black));
        situation.setC(4, 1, Hex.occupied(Progressor, Black));
        situation.setC(6, 1, Hex.occupied(Progressor, Black));
        situation.setC(8, 1, Hex.occupied(Progressor, Black));

        situation.setC(0, 6, Hex.occupied(Dominator, White));
        situation.setC(1, 5, Hex.occupied(Liberator, White));
        situation.setC(2, 6, Hex.occupied(Aggressor, White));
        situation.setC(3, 5, Hex.occupied(Defensor, White));
        situation.setC(4, 6, Hex.occupied(Intellector, White));
        situation.setC(5, 5, Hex.occupied(Defensor, White));
        situation.setC(6, 6, Hex.occupied(Aggressor, White));
        situation.setC(7, 5, Hex.occupied(Liberator, White));
        situation.setC(8, 6, Hex.occupied(Dominator, White));
        situation.setC(0, 5, Hex.occupied(Progressor, White));
        situation.setC(2, 5, Hex.occupied(Progressor, White));
        situation.setC(4, 5, Hex.occupied(Progressor, White));
        situation.setC(6, 5, Hex.occupied(Progressor, White));
        situation.setC(8, 5, Hex.occupied(Progressor, White));

        return situation;
    }

    public static function empty():Situation
    {
        var situation = new Situation();
        situation.turnColor = White;
        situation.intellectorPos = [White => null, Black => null];
        situation.zobristHash = ZobristHashing.emptyHash;
        situation.figureArray = [for (t in 0...63) Hex.empty()];
        return situation;
    }

    public function makeMove(ply:Ply):Situation 
    {
        var next:Situation = this.copy();
        next.turnColor = opposite(turnColor);
        next.zobristHash ^= ZobristHashing.hashes[0];

        var fromHex = get(ply.from);
        var toHex = get(ply.to);

        if (ply.morphInto == null)
            next.setWithZobris(ply.to, fromHex.copy(), toHex);
        else
            next.setWithZobris(ply.to, Hex.occupied(ply.morphInto, fromHex.color), toHex); //Promotion or chameleon

        if (toHex.color == fromHex.color)
            next.setWithZobris(ply.from, toHex.copy(), fromHex); //Castle               
        else 
            next.setWithZobris(ply.from, Hex.empty(), fromHex);

        if (fromHex.type == Intellector)
            next.intellectorPos[fromHex.color] = ply.to.copy();

        return next;
    }

    public function unmakeMoves(plys:Array<ReversiblePly>):Situation 
    {
        var formerSituation:Situation = this.copy();
        var reversedPlys = plys.copy();
        reversedPlys.reverse();

        for (ply in reversedPlys)
            for (transform in ply)
            {
                formerSituation.setWithZobris(transform.coords, transform.former, transform.latter);
                if (transform.former.type == Intellector)
                    formerSituation.intellectorPos[transform.former.color] = transform.coords;
            }

        if (plys.length % 2 == 1)
        {
            formerSituation.turnColor = opposite(turnColor);
            formerSituation.zobristHash ^= ZobristHashing.hashes[0];
        }
            
        return formerSituation;
    }

    public function isMating(ply:Ply):Bool
    {
        var hexFrom = get(ply.from);
        var mate = ply.to == intellectorPos[opposite(hexFrom.color)];
        var breakthrough = hexFrom.type == Intellector && ply.to.isFinalForColor(hexFrom.color);
        return mate || breakthrough;
    }

    public function isMate():Bool
    {
        var lastMoveColor = opposite(turnColor);
        var playerEaten:Bool = get(intellectorPos[turnColor]).color != turnColor;
        var opponentOnFinal:Bool = intellectorPos[lastMoveColor].isFinalForColor(lastMoveColor);

        return playerEaten || opponentOnFinal;
    }

    public function availablePlys():Array<Ply>
    {
        var plys:Array<Ply> = [];
        var enemyColor = opposite(turnColor);

        for (p in IntPoint.allHexCoords)
        {
            var hex:Hex = get(p);
            if (hex.color != turnColor) //Also covers the case when hex is empty
                continue;

            var destCoords = Rules.possibleFields(p, get);
            for (coords in destCoords)
            {
                var hexOnto:Hex = get(coords);

                var ply:Ply = new Ply();
                ply.from = p.copy();
                ply.to = coords;

                if (hexOnto.isEmpty())
                    plys.push(ply);
                else 
                {
                    var ownIntPos = intellectorPos[turnColor];
                    var enemyIntPos = intellectorPos[enemyColor];
                    if (!ply.to.equals(ownIntPos)) //to avoid duplicates, we consider castling only if it starts from Intellector
                        if (ply.to.equals(enemyIntPos))
                            return [ply]; //If mate is found, do not consider any other move
                        else
                        {
                            plys.push(ply);

                            if (Rules.areNeighbours(ownIntPos, ply.from)) 
                            {
                                var chameleonPly:Ply = ply.copy();
                                ply.morphInto = hexOnto.type;
                                plys.push(chameleonPly);
                            }
                        }
                }
            }
        }
        
        return plys;
    }

    public function collectOccupiedHexes():Map<IntPoint, Hex>
    {
        var map:Map<IntPoint, Hex> = [];
        for (i in 0...9) 
            for (j in 0...(7 - i % 2))
            {
                var hex = getC(i, j);
                if (hex.type != null)
                    map.set(new IntPoint(i, j), hex);
            }
            
        return map;
    }

    public function collectOccupiedFast():Array<ConcreteHex>
    {
        var arr = [];
        for (i in 0...9) 
            for (j in 0...(7 - i % 2))
            {
                var hex = getC(i, j);
                if (hex.type != null)
                    arr.push(new ConcreteHex(i, j, hex.type, hex.color));
            }
            
        return arr;
    }

    public function replaceNullsWithEmpty()
    {
        for (t in 0...63)
            if (figureArray[t] == null)
                figureArray[t] = Hex.empty();
    }

    public function serialize():String
    {
        var s = PieceColor.letter(turnColor);
        for (t in 0...63)
        {
            var fig = figureArray[t];
            if (fig.type == null)
                s += '0';
            else
                s += '${PieceType.letter(fig.type)}${PieceColor.letter(fig.color)}';
        }
        return s;
    }

    public inline function get(coords:IntPoint):Hex
    {
        return getC(coords.i, coords.j);
    }

    private inline function getC(i:Int, j:Int):Hex
    {
        return figureArray[j * 9 + i];
    }

    public inline function set(coords:IntPoint, hex:Hex) 
    {
        setC(coords.i, coords.j, hex);
    }

    public inline function setWithZobris(coords:IntPoint, hex:Hex, formerHex:Hex) 
    {
        set(coords, hex);
        if (formerHex.type != null)
            zobristHash ^= ZobristHashing.getForPiece(coords.i, coords.j, formerHex.type, formerHex.color);
        if (hex.type != null)
        {
            zobristHash ^= ZobristHashing.getForPiece(coords.i, coords.j, hex.type, hex.color);
            if (hex.type == Intellector)
                intellectorPos[hex.color] = coords.copy();
        }
    }

    public function setTurnWithZobris(color:PieceColor) 
    {
        if (turnColor == null && color == Black)
            zobristHash ^= ZobristHashing.hashes[0];
        else if (turnColor != color)
            zobristHash ^= ZobristHashing.hashes[0];
        turnColor = color;
    }

    private inline function setC(i:Int, j:Int, hex:Hex)
    {
        figureArray[j * 9 + i] = hex;
        if (hex.type == Intellector)
            intellectorPos[hex.color] = new IntPoint(i, j);
    }

    public function copy():Situation 
    {
        var s = new Situation();
        s.figureArray = [for (t in 0...this.figureArray.length) this.figureArray[t].copy()];
        s.turnColor = this.turnColor;
        s.intellectorPos = [White => intellectorPos[PieceColor.White].copy(), Black => intellectorPos[PieceColor.Black].copy()];
        s.zobristHash = zobristHash.copy();
        return s;
    }

    public function new() 
    {
        
    }
}