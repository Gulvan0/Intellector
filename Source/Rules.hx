package;

import struct.Hex;
import struct.PieceType;
import struct.PieceColor;

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

    public static function possibleFields(from:IntPoint, getHex:Null<IntPoint>->Hex):Array<IntPoint> 
    {
        var fields:Array<IntPoint> = [];
        var figure:Hex = getHex(from);

        switch figure.type 
        {
            case Progressor:
                var directions:Array<Direction> = figure.color == White? [U, UL, UR] : [D, DL, DR];
                for (dir in directions)
                {
                    var destination = getOneStepCoords(from.i, from.j, dir);
                    if (destination != null)
                    {
                        var hex = getHex(destination);
                        if (hex != null && (hex.isEmpty() || hex.color != figure.color))
                            fields.push(destination);
                    }
                }
            case Aggressor:
                for (dir in [A_UL, A_UR, A_R, A_DR, A_DL, A_L])
                    fields = fields.concat(avalanche(from, dir, figure.color, getHex));
            case Dominator:
                for (dir in [UL, UR, D, DR, DL, U])
                    fields = fields.concat(avalanche(from, dir, figure.color, getHex));
            case Liberator:
                for (dir in [UL, UR, D, DR, DL, U])
                {
                    var destination = getOneStepCoords(from.i, from.j, dir);
                    if (destination != null)
                    {
                        var hex1 = getHex(destination);
                        if (hex1 != null && hex1.isEmpty())
                            fields.push(destination);
                    }

                    destination = getCoordsInDirection(from.i, from.j, dir, 2);
                    if (destination != null)
                    {
                        var hex2 = getHex(destination);
                        if (hex2 != null && (hex2.isEmpty() || hex2.color != figure.color))
                            fields.push(destination);
                    }
                }
            case Defensor:
                for (dir in [UL, UR, D, DR, DL, U])
                {
                    var destination = getOneStepCoords(from.i, from.j, dir);
                    if (destination != null)
                    {
                        var hex = getHex(destination);
                        if (hex != null && (hex.isEmpty() || hex.color != figure.color || hex.type == Intellector))
                            fields.push(destination);
                    }
                }
            case Intellector:
                for (dir in [UL, UR, D, DR, DL, U])
                {
                    var destination = getOneStepCoords(from.i, from.j, dir);
                    if (destination != null)
                    {
                        var hex = getHex(destination);
                        if (hex != null && (hex.isEmpty() || (hex.color == figure.color && hex.type == Defensor)))
                            fields.push(destination);
                    }
                }
        }
        return fields;
    }

    private static function avalanche(start:IntPoint, dir:Direction, color:PieceColor, getHex:Null<IntPoint>->Hex):Array<IntPoint>
    {
        var hexesCollected:Array<IntPoint> = [];
        var destination = getOneStepCoords(start.i, start.j, dir);
        while (destination != null)
        {
            var hex = getHex(destination);
            if (hex != null && hex.isEmpty())
            {
                hexesCollected.push(destination);
                destination = getOneStepCoords(destination.i, destination.j, dir);
            }
            else
            {
                if (hex != null && hex.color != color)
                    hexesCollected.push(destination);
                break;
            }
        }
        return hexesCollected;
    }

    public static function getCoordsInDirection(fromI:Int, fromJ:Int, dir:Direction, ?steps:Int = 1):Null<IntPoint>
    {
        var nextCoords = getOneStepCoords(fromI, fromJ, dir);
        steps--;
        while (steps > 0 && nextCoords != null)
        {
            nextCoords = getOneStepCoords(nextCoords.i, nextCoords.j, dir);
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

    public static function getOneStepCoords(fromI:Int, fromJ:Int, dir:Direction):Null<IntPoint>
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

    public static function areNeighbours(coords1:IntPoint, coords2:IntPoint):Bool
    {
        for (dir in [UL, UR, D, DR, DL, U])
            if (coords2.equals(getOneStepCoords(coords1.i, coords1.j, dir)))
                return true;
        return false;
    }
}