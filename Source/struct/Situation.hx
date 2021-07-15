package struct;

import struct.PieceColor.opposite;

class Situation 
{
    public var figureArray:Array<Array<Hex>>;
    public var turnColor:PieceColor;

    public static function starting():Situation
    {
        var situation = new Situation();
        situation.figureArray = [for (j in 0...7) [for (i in 0...9) Hex.empty()]];
        situation.turnColor = White;

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

        return next;
    }

    public function unmakeMoves(plys:Array<ReversiblePly>):Situation 
    {
        var formerSituation:Situation = this.copy();
        var reversedPlys = plys.copy();
        reversedPlys.reverse();

        for (ply in reversedPlys)
            for (transform in ply)
                formerSituation.set(transform.coords, transform.former);

        if (plys.length % 2 == 1)
            formerSituation.turnColor = opposite(turnColor);
        return formerSituation;
    }

    public function isMating(ply:Ply):Bool
    {
        return get(ply.to).type == Intellector && get(ply.from).color != get(ply.to).color;
    }

    public function availablePlys():Array<Ply>
    {
        var result:Array<Ply> = [];

        for (p => hex in collectOccupiedHexes())
        {
            if (hex.color != turnColor)
                continue;

            var destCoords = Rules.possibleFields(p, get);
            for (coords in destCoords)
            {
                var ply:Ply = new Ply();
                ply.from = p.copy();
                ply.to = coords;
                result.push(ply);
                if (get(coords).color != turnColor)
                {
                    var chameleonPly:Ply = ply.copy();
                    ply.morphInto = get(coords).type;
                    result.push(chameleonPly);
                }
            }
        }
        
        return result;
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
        return s;
    }

    public function new() 
    {
        
    }
}