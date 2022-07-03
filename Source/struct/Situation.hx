package struct;

import serialization.SituationSerializer;
import utils.MathUtils;
import struct.PieceColor.opposite;

class Situation 
{
    private var hexArray:Array<Hex>;
    public var turnColor:PieceColor;
    public var intellectorPos(default, null):Map<PieceColor, Null<IntPoint>>;

    public static function starting():Situation
    {
        var situation = new Situation();
        situation.turnColor = White;
        situation.intellectorPos = [White => new IntPoint(4, 6), Black => new IntPoint(4, 0)];
        situation.hexArray = [for (t in 0...IntPoint.hexCount) Hex.empty()];

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
        situation.hexArray = [for (t in 0...IntPoint.hexCount) Hex.empty()];
        return situation;
    }

    public static function randomPlay(plyCount:Int):Situation 
    {
        var sit:Situation = Situation.starting();
        for (i in 0...plyCount)
        {
            var allPlys = sit.availablePlys();
            sit.makeMove(MathUtils.randomElement(allPlys), true);
        }
        return sit;
    }

    public function randomContinuation(plyCount:Int):Array<{ply:Ply, plyStr:String}> 
    {
        var result:Array<{ply:Ply, plyStr:String}> = [];
        var sit:Situation = this.copy();
        for (i in 0...plyCount)
        {
            var allPlys = sit.availablePlys();
            var ply:Ply = MathUtils.randomElement(allPlys);
            result.push({ply: ply, plyStr: ply.toNotation(sit)});
            sit.makeMove(ply, true);
        }
        return result;
    }

    public function makeMove(ply:Ply, inPlace:Bool = false):Situation 
    {
        var next:Situation = inPlace? this : this.copy();
        next.turnColor = opposite(turnColor);

        var fromHex = get(ply.from);
        var toHex = get(ply.to);

        if (ply.morphInto == null)
            next.set(ply.to, fromHex.copy());
        else
            next.set(ply.to, Hex.occupied(ply.morphInto, fromHex.color)); //Promotion or chameleon

        if (toHex.color == fromHex.color)
            next.set(ply.from, toHex.copy()); //Castle               
        else 
            next.set(ply.from, Hex.empty());

        if (fromHex.type == Intellector)
            next.intellectorPos[fromHex.color] = ply.to.copy();

        return next;
    }

    public function makeMoves(plys:Array<ReversiblePly>):Situation 
    {
        var nextSituation:Situation = this.copy();

        for (ply in plys)
            for (transform in ply)
            {
                nextSituation.set(transform.coords, transform.latter);
                if (transform.latter.type == Intellector)
                    nextSituation.intellectorPos[transform.latter.color] = transform.coords;
            }

        if (plys.length % 2 == 1)
            nextSituation.turnColor = opposite(turnColor);
            
        return nextSituation;
    }

    public function unmakeMoves(plys:Array<ReversiblePly>):Situation 
    {
        var formerSituation:Situation = this.copy();
        var reversedPlys = plys.copy();
        reversedPlys.reverse();

        for (ply in reversedPlys)
            for (transform in ply)
            {
                formerSituation.set(transform.coords, transform.former);
                if (transform.former.type == Intellector)
                    formerSituation.intellectorPos[transform.former.color] = transform.coords;
            }

        if (plys.length % 2 == 1)
            formerSituation.turnColor = opposite(turnColor);
            
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

        for (t in 0...IntPoint.hexCount)
        {
            var hex = hexArray[t];
            if (!hex.isEmpty())
                map.set(IntPoint.fromScalar(t), hex);
        }
            
        return map;
    }

    public function serialize():String
    {
        return SituationSerializer.serialize(this);
    }

    public inline function getS(scalarCoord:Int):Hex
    {
        return hexArray[scalarCoord];
    }

    public inline function get(coords:IntPoint):Hex
    {
        return getS(coords.toScalar());
    }

    private inline function getC(i:Int, j:Int):Hex
    {
        return get(new IntPoint(i, j));
    }

    public inline function set(coords:IntPoint, hex:Hex, ?adjustToConsistency:Bool = true) 
    {
        hexArray[coords.toScalar()] = hex;
        if (adjustToConsistency)
            if (hex.type == Intellector)
                intellectorPos[hex.color] = coords;
            else if (hex.isEmpty() && get(coords).type == Intellector)
                intellectorPos[get(coords).color] = null;
    }

    private inline function setC(i:Int, j:Int, hex:Hex)
    {
        set(new IntPoint(i, j), hex);
    }

    public function copy():Situation 
    {
        var s = new Situation();
        s.hexArray = [for (t in 0...IntPoint.hexCount) this.hexArray[t].copy()];
        s.turnColor = this.turnColor;
        s.intellectorPos = [
            White => (intellectorPos.get(White) != null? intellectorPos[PieceColor.White].copy() : null), 
            Black => (intellectorPos.get(Black) != null? intellectorPos[PieceColor.Black].copy() : null)
        ];
        return s;
    }

    public static function fromSIP(sip:String):Situation 
    {
        return SituationSerializer.deserialize(sip);
    }

    public function new() 
    {
        
    }
}