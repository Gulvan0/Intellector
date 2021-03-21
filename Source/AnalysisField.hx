  package;

import Field.Direction;
import openfl.events.Event;
import Figure.FigureColor;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.display.Sprite;

class AnalysisField extends Sprite
{
    public static var a:Float = 40;
    public var hexes:Array<Array<Hexagon>>;
    public var figures:Array<Array<Null<Figure>>>;

    private var selected:Null<IntPoint>;
    private var selectedDest:Null<IntPoint>;

    public function new() 
    {
        super();
        hexes = [];
        for (j in 0...7)
        {
            var row:Array<Hexagon> = [];
            for (i in 0...9)
                if (!hexExists(i, j))
                    row.push(null);
                else 
                {
                    var hex:Hexagon = new Hexagon(a, isDark(i, j));
                    var coords = hexCoords(i, j);
                    hex.x = coords.x;
                    hex.y = coords.y;
                    addChild(hex);
                    row.push(hex);
                }
            hexes.push(row);
        }
        figures = [for (j in 0...7) [for (i in 0...9) null]];
        figures[0][0] = new Figure(Dominator, Black);
        figures[0][1] = new Figure(Liberator, Black);
        figures[0][2] = new Figure(Aggressor, Black);
        figures[0][3] = new Figure(Defensor, Black);
        figures[0][4] = new Figure(Intellector, Black);
        figures[0][5] = new Figure(Defensor, Black);
        figures[0][6] = new Figure(Aggressor, Black);
        figures[0][7] = new Figure(Liberator, Black);
        figures[0][8] = new Figure(Dominator, Black);
        figures[1][0] = new Figure(Progressor, Black);
        figures[1][2] = new Figure(Progressor, Black);
        figures[1][4] = new Figure(Progressor, Black);
        figures[1][6] = new Figure(Progressor, Black);
        figures[1][8] = new Figure(Progressor, Black);

        figures[6][0] = new Figure(Dominator, White);
        figures[5][1] = new Figure(Liberator, White);
        figures[6][2] = new Figure(Aggressor, White);
        figures[5][3] = new Figure(Defensor, White);
        figures[6][4] = new Figure(Intellector, White);
        figures[5][5] = new Figure(Defensor, White);
        figures[6][6] = new Figure(Aggressor, White);
        figures[5][7] = new Figure(Liberator, White);
        figures[6][8] = new Figure(Dominator, White);
        figures[5][0] = new Figure(Progressor, White);
        figures[5][2] = new Figure(Progressor, White);
        figures[5][4] = new Figure(Progressor, White);
        figures[5][6] = new Figure(Progressor, White);
        figures[5][8] = new Figure(Progressor, White);

        placeFigures();
        addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    private function onPress(e:MouseEvent) 
    {
        var indexes = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        if (indexes == null)
        {
            if (selected != null)
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
                hexes[selected.j][selected.i].deselect();
                selected = null;
            }
            return;
        }

        if (selected != null)
        {
            var movingFig = getFigure(selected);
            var moveOntoFig = getFigure(indexes);

            for (dest in possibleFields(movingFig, selected.i, selected.j))
                hexes[dest.j][dest.i].removeMarkers();

            if (moveOntoFig != null && moveOntoFig.color == getFigure(selected).color && !isCastle(selected, indexes, movingFig, moveOntoFig))
            {
                hexes[selected.j][selected.i].deselect();
                selected = indexes;
                hexes[selected.j][selected.i].select();
                for (dest in possibleFields(moveOntoFig, indexes.i, indexes.j))
                    if (getFigure(dest) != null)
                        hexes[dest.j][dest.i].addRound();
                    else
                        hexes[dest.j][dest.i].addDot();
                return;
            }

            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
            if (ableToMove(selected, indexes))
                move(selected.i, selected.j, indexes.i, indexes.j);
            selectionBackToNormal();
        }
        else
        {
            var figure = figures[indexes.j][indexes.i];
            if (figure != null)
            {
                selected = indexes;
                hexes[indexes.j][indexes.i].select();
                removeChild(figure);
                addChild(figure);
                figure.startDrag(true);

                for (dest in possibleFields(figure, indexes.i, indexes.j))
                    if (getFigure(dest) != null)
                        hexes[dest.j][dest.i].addRound();
                    else
                        hexes[dest.j][dest.i].addDot();

                stage.removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
                stage.addEventListener(MouseEvent.MOUSE_UP, onRelease);
            }
        }
    }

    private function onMove(e:MouseEvent) 
    {
        var indexes = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (selectedDest != null)
            if (selectedDest.equals(indexes))
                return;
            else
            {
                hexes[selectedDest.j][selectedDest.i].deselect();
                selectedDest = null;
            }

        if (indexes != null && ableToMove(selected, indexes))
        {
            selectedDest = indexes;
            hexes[selectedDest.j][selectedDest.i].select();
        }
    }

    private function onRelease(e:MouseEvent) 
    {
        stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);

        var indexes = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        figures[selected.j][selected.i].stopDrag();
        if (indexes != null && ableToMove(selected, indexes) && !indexes.equals(selected))
        {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
            for (dest in possibleFields(figures[selected.j][selected.i], selected.i, selected.j))
                hexes[dest.j][dest.i].removeMarkers();
            move(selected.i, selected.j, indexes.i, indexes.j);
            selectionBackToNormal();
        }
        else
            disposeFigure(figures[selected.j][selected.i], selected.i, selected.j);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    private function selectionBackToNormal() 
    {
        hexes[selected.j][selected.i].deselect();
        if (selectedDest != null)
            hexes[selectedDest.j][selectedDest.i].deselect();

        selected = null;
        selectedDest = null;
    }

    private function ableToMove(from:IntPoint, to:IntPoint) 
    {
        for (dest in possibleFields(getFigure(from), from.i, from.j))
            if (to.equals(dest))
                return true;
        return false;    
    }

    private function isCastle(pos1:IntPoint, pos2:IntPoint, fig1:Figure, fig2:Figure)
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

    private function possibleFields(figure:Figure, fromI:Int, fromJ:Int):Array<IntPoint> 
    {
        var fields:Array<IntPoint> = [];
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
                    var destination = getCoordsInRelDirection(fromI, fromJ, dir, figure.color, 2);
                    var occupier = getFigure(destination);
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

    private function getFigure(coords:Null<IntPoint>):Null<Figure>
    {
        return (coords == null || !hexExists(coords.i, coords.j) || figures[coords.j] == null)? null : figures[coords.j][coords.i];
    }

    private function getCoordsInRelDirection(fromI:Int, fromJ:Int, dir:Direction, col:FigureColor, ?steps:Int = 1):Null<IntPoint>
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

    private function oppositeDir(dir:Direction):Direction 
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

    private function getCoordsInAbsDirection(fromI:Int, fromJ:Int, dir:Direction):Null<IntPoint>
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
        return hexExists(coords.i, coords.j)? coords : null;
    }

    private function hexExists(i:Int, j:Int):Bool
    {
        return i >= 0 && i < 9 && j >= 0 && j < 7 && (j != 6 || i % 2 == 0);
    }

    private function move(fromI:Int, fromJ:Int, toI:Int, toJ:Int) 
    {
        var figure = figures[fromJ][fromI];
        var figMoveOnto = getFigure(new IntPoint(toI, toJ));
        
        disposeFigure(figure, toI, toJ);
        figures[toJ][toI] = figure;
        figures[fromJ][fromI] = null;

        if (figMoveOnto != null)
            if (figMoveOnto.color == figure.color)
                if (isCastle(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), figure, figMoveOnto))
                {
                    disposeFigure(figMoveOnto, fromI, fromJ);
                    figures[fromJ][fromI] = figMoveOnto;
                }
                else 
                    throw "Trying to eat own figure";
            else 
                removeChild(figMoveOnto);
    }

    private function posToIndexes(x:Float, y:Float):Null<IntPoint>
    {
        var closest:IntPoint = null;
        var distanceSqr:Float = a * a;
        for (j in 0...7)
            for (i in 0...9)
            {
                if (!hexExists(i, j))
                    continue;
                var coords:Point = hexCoords(i, j);
                var currDistSqr = (coords.x - x) * (coords.x - x) + (coords.y - y) * (coords.y - y);
                if (distanceSqr > currDistSqr)
                {
                    closest = new IntPoint(i, j);
                    distanceSqr = currDistSqr;
                }
            }
        return closest;
    }

    private function hexCoords(i:Int, j:Int):Point
    {
        var p:Point = new Point(0, 0);
        p.x = 3 * a * i / 2;
        p.y = Math.sqrt(3) * a * j;
        if (i % 2 == 1)
            p.y += Math.sqrt(3) * a / 2;
        return p;
    }

    private function placeFigures() 
    {
        for (j in 0...7)
            for (i in 0...9)
            {
                var figure = figures[j][i];
                if (figure != null)
                {
                    var scale = Math.sqrt(3) * a * 0.85 / figure.height;
                    if (figure.type == Progressor)
                        scale *= 0.7;
                    else if (figure.type == Liberator || figure.type == Defensor)
                        scale *= 0.9;
                    figure.scaleX = scale;
                    figure.scaleY = scale;
                    disposeFigure(figure, i, j);
                    addChild(figure);
                }
            }
    }

    private function disposeFigure(figure:Figure, i:Int, j:Int) 
    {
        var coords = hexCoords(i, j);
        figure.x = coords.x;
        figure.y = coords.y;
    }

    private function isDark(i:Int, j:Int) 
    {
        if (j % 3 == 2)
            return false;
        else if (j % 3 == 0)
            return i % 2 == 0;
        else 
            return i % 2 == 1;
    }
}