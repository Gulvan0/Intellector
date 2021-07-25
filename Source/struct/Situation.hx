package struct;

import js.html.Window;
import analysis.PieceValues;
import struct.PieceColor.opposite;

class Situation 
{
    public var figureArray:Array<Array<Hex>>;
    public var turnColor:PieceColor;

    private var intellectorPos:Map<PieceColor, IntPoint>;

    public static function starting():Situation
    {
        var situation = new Situation();
        situation.figureArray = [for (j in 0...7) [for (i in 0...9) Hex.empty()]];
        situation.turnColor = White;
        situation.intellectorPos = [White => new IntPoint(4, 6), Black => new IntPoint(4, 0)];

        situation.figureArray[0][0] = Hex.occupied(Dominator, Black);
        situation.figureArray[0][1] = Hex.occupied(Liberator, Black);
        situation.figureArray[0][2] = Hex.occupied(Aggressor, Black);
        situation.figureArray[0][3] = Hex.occupied(Defensor, Black);
        situation.figureArray[0][4] = Hex.occupied(Intellector, Black);
        situation.figureArray[0][5] = Hex.occupied(Defensor, Black);
        situation.figureArray[0][6] = Hex.occupied(Aggressor, Black);
        situation.figureArray[0][7] = Hex.occupied(Liberator, Black);
        situation.figureArray[0][8] = Hex.occupied(Dominator, Black);
        situation.figureArray[1][0] = Hex.occupied(Progressor, Black);
        situation.figureArray[1][2] = Hex.occupied(Progressor, Black);
        situation.figureArray[1][4] = Hex.occupied(Progressor, Black);
        situation.figureArray[1][6] = Hex.occupied(Progressor, Black);
        situation.figureArray[1][8] = Hex.occupied(Progressor, Black);

        situation.figureArray[6][0] = Hex.occupied(Dominator, White);
        situation.figureArray[5][1] = Hex.occupied(Liberator, White);
        situation.figureArray[6][2] = Hex.occupied(Aggressor, White);
        situation.figureArray[5][3] = Hex.occupied(Defensor, White);
        situation.figureArray[6][4] = Hex.occupied(Intellector, White);
        situation.figureArray[5][5] = Hex.occupied(Defensor, White);
        situation.figureArray[6][6] = Hex.occupied(Aggressor, White);
        situation.figureArray[5][7] = Hex.occupied(Liberator, White);
        situation.figureArray[6][8] = Hex.occupied(Dominator, White);
        situation.figureArray[5][0] = Hex.occupied(Progressor, White);
        situation.figureArray[5][2] = Hex.occupied(Progressor, White);
        situation.figureArray[5][4] = Hex.occupied(Progressor, White);
        situation.figureArray[5][6] = Hex.occupied(Progressor, White);
        situation.figureArray[5][8] = Hex.occupied(Progressor, White);

        return situation;
    }

    public function makeMove(ply:Ply):Situation 
    {
        var next:Situation = this.copy();
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
        var captures:Array<Ply> = [];
        //var checks:Array<Ply> = [];
        var normalPlys:Array<Ply> = [];
        var intellectorMovements:Array<Ply> = [];

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
                {
                    if (ply.from.equals(intellectorPos[turnColor])) //Intellector moves are considered last
                        intellectorMovements.push(ply);
                    else
                        normalPlys.push(ply);
                }
                else 
                {
                    if (!ply.from.equals(intellectorPos[turnColor])) //Intellector moves onto piece => castle => ignore as duplicate for castle from defensor pos
                        if (ply.to.equals(intellectorPos[enemyColor]))
                            return [ply]; //If mate is found, do not consider any other move
                        else
                        {
                            captures.push(ply);

                            if (Rules.areNeighbours(intellectorPos[turnColor], ply.from)) 
                            {
                                var chameleonPly:Ply = ply.copy();
                                ply.morphInto = hexOnto.type;
                                
                                if (PieceValues.firstHasHigherPriority(hexOnto.type, hex.type))
                                    captures.insert(0, chameleonPly);
                                else
                                    captures.push(chameleonPly);
                            }
                        }
                }
            }
        }
        
        return captures.concat(normalPlys).concat(intellectorMovements);
    }

    public function collectOccupiedHexes():Map<IntPoint, Hex>
    {
        return [for (p in IntPoint.allHexCoords) if (!get(p).isEmpty()) p.copy() => get(p)];
    }

    public function get(coords:IntPoint):Hex
    {
        return getC(coords.i, coords.j);
    }

    public function getC(i:Int, j:Int):Hex
    {
        return figureArray[j][i];
    }

    public function set(coords:IntPoint, hex:Hex) 
    {
        setC(coords.i, coords.j, hex);
    }

    public function setC(i:Int, j:Int, hex:Hex)
    {
        figureArray[j][i] = hex;
    }

    public function copy():Situation 
    {
        var s = new Situation();
        s.figureArray = [for (i in 0...this.figureArray.length) [for (j in 0...this.figureArray[i].length) this.figureArray[i][j].copy()]];
        s.turnColor = this.turnColor;
        s.intellectorPos = [White => intellectorPos[PieceColor.White].copy(), Black => intellectorPos[PieceColor.Black].copy()];
        return s;
    }

    public function new() 
    {
        
    }
}