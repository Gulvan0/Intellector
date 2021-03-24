package;

import Figure.FigureColor;

enum Direction
{
    U;
    UL;
    UR;
    D;
    DL;
    DR;
    A_UL;
    A_UR;
    A_R;
    A_DR;
    A_DL;
    A_L;
}

class Rules
{
    public static function isCastle(pos1:IntPoint, pos2:IntPoint, fig1:Figure, fig2:Figure)
    {
        if (fig1 == null || fig2 == null || fig1.color != fig2.color)
            return false;

        if (!((fig1.type == Intellector && fig2.type == Defensor) || (fig1.type == Defensor && fig2.type == Intellector)))
            return false;

        for (dir in [UL, UR, D, DR, DL, U])
            if (pos2.equals(getCoordsInAbsDirection(pos1.i, pos1.j, dir)))
                return true;

        return false;
    }

    public static function possibleFields(fromI:Int, fromJ:Int, getFigure:Null<IntPoint>->Figure):Array<IntPoint> 
    {
        var fields:Array<IntPoint> = [];
        var figure = getFigure(new IntPoint(fromI, fromJ));
        switch figure.type 
        {
            case Progressor:
                for (dir in [U, UL, UR])
                {
                    var destination = getCoordsInRelDirection(fromI, fromJ, dir, figure.color);
                    var occupier = getFigure(destination);
                    if (destination != null && (occupier == null || occupier.color != figure.color))
                        fields.push(destination);
                }
            case Aggressor:
                for (dir in [A_UL, A_UR, A_R, A_DR, A_DL, A_L])
                {
                    var destination = getCoordsInRelDirection(fromI, fromJ, dir, figure.color);
                    while (destination != null)
                    {
                        var occupier = getFigure(destination);
                        if (occupier != null)
                        {
                            if (occupier.color != figure.color)
                                fields.push(destination);
                            break;
                        }
                        else 
                        {
                            fields.push(destination);
                            destination = getCoordsInRelDirection(destination.i, destination.j, dir, figure.color);
                        }
                    }
                }
            case Dominator:
                for (dir in [UL, UR, D, DR, DL, U])
                {
                    var destination = getCoordsInRelDirection(fromI, fromJ, dir, figure.color);
                    while (destination != null)
                    {
                        var occupier = getFigure(destination);
                        if (occupier != null)
                        {
                            if (occupier.color != figure.color)
                                fields.push(destination);
                            break;
                        }
                        else 
                        {
                            fields.push(destination);
                            destination = getCoordsInRelDirection(destination.i, destination.j, dir, figure.color);
                        }
                    }
                }
            case Liberator:
                for (dir in [UL, UR, D, DR, DL, U])
                {
                    var destination = getCoordsInRelDirection(fromI, fromJ, dir, figure.color, 1);
                    var occupier = getFigure(destination);
                    if (destination != null && occupier == null)
                        fields.push(destination);

                    destination = getCoordsInRelDirection(fromI, fromJ, dir, figure.color, 2);
                    occupier = getFigure(destination);
                    if (destination != null && (occupier == null || occupier.color != figure.color))
                        fields.push(destination);
                }
            case Defensor:
                for (dir in [UL, UR, D, DR, DL, U])
                {
                    var destination = getCoordsInRelDirection(fromI, fromJ, dir, figure.color);
                    var occupier = getFigure(destination);
                    if (destination != null && (occupier == null || occupier.color != figure.color || occupier.type == Intellector))
                        fields.push(destination);
                }
            case Intellector:
                for (dir in [UL, UR, D, DR, DL, U])
                {
                    var destination = getCoordsInRelDirection(fromI, fromJ, dir, figure.color);
                    var occupier = getFigure(destination);
                    if (destination != null && (occupier == null || (occupier.color == figure.color && occupier.type == Defensor)))
                        fields.push(destination);
                }
        }
        return fields;
    }

    public static function getCoordsInRelDirection(fromI:Int, fromJ:Int, dir:Direction, col:FigureColor, ?steps:Int = 1):Null<IntPoint>
    {
        var trueDirection = col == White? dir : oppositeDir(dir);
        var nextCoords = getCoordsInAbsDirection(fromI, fromJ, trueDirection);
        steps--;
        while (steps > 0 && nextCoords != null)
        {
            nextCoords = getCoordsInAbsDirection(nextCoords.i, nextCoords.j, trueDirection);
            steps--;
        }
        return nextCoords;
    }

    public static function oppositeDir(dir:Direction):Direction 
    {
        return switch dir 
        {
            case U: D;
            case UL: DR;
            case UR: DL;
            case D: U;
            case DL: UR;
            case DR: UL;
            case A_UL: A_DR;
            case A_UR: A_DL;
            case A_DR: A_UL;
            case A_DL: A_UR;
            case A_R: A_L;
            case A_L: A_R;
        }    
    }

    public static function getCoordsInAbsDirection(fromI:Int, fromJ:Int, dir:Direction):Null<IntPoint>
    {
        var coords = switch dir 
        {
            case U: new IntPoint(fromI, fromJ - 1);
            case UL: new IntPoint(fromI - 1, (fromI % 2 == 0)? fromJ - 1 : fromJ);
            case UR: new IntPoint(fromI + 1, (fromI % 2 == 0)? fromJ - 1 : fromJ);
            case D: new IntPoint(fromI, fromJ + 1);
            case DL: new IntPoint(fromI - 1, (fromI % 2 == 0)? fromJ : fromJ + 1);
            case DR: new IntPoint(fromI + 1, (fromI % 2 == 0)? fromJ : fromJ + 1);
            case A_UL: new IntPoint(fromI - 1, (fromI % 2 == 0)? fromJ - 2 : fromJ - 1);
            case A_UR: new IntPoint(fromI + 1, (fromI % 2 == 0)? fromJ - 2 : fromJ - 1);
            case A_DR: new IntPoint(fromI + 1, (fromI % 2 == 0)? fromJ + 1 : fromJ + 2);
            case A_DL: new IntPoint(fromI - 1, (fromI % 2 == 0)? fromJ + 1 : fromJ + 2);
            case A_R: new IntPoint(fromI + 2, fromJ);
            case A_L: new IntPoint(fromI - 2, fromJ);
        }
        return Field.hexExists(coords.i, coords.j)? coords : null;
    }
}