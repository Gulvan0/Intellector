  package;

import openfl.Assets;
import Figure.FigureType;
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
        drawHexes();
        arrangeDefault();
        addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    //---------------------------------------------------------------------------------------------------------

    public function reset() 
    {
        clearBoard();
        arrangeDefault();
    }
    
    public function clearBoard() 
    {
        for (row in figures)
            for (figure in row)
                if (figure != null)
                    removeChild(figure);
        figures = [for (j in 0...7) [for (i in 0...9) null]];
    }

    private function arrangeDefault() 
    {
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
    }

    //---------------------------------------------------------------------------------------------------------

    private function departurePress(pressLocation:IntPoint) 
    {
        var figure = getFigure(pressLocation);
        if (figure == null)
            return;

        selectDeparture(pressLocation, figure);
        drag(figure);

        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onRelease);
    }

    private function destinationPress(pressLocation:IntPoint) 
    {
        var from = new IntPoint(selected.i, selected.j);
        var movingFig = getFigure(selected);
        var moveOntoFig = getFigure(pressLocation);

        selectionBackToNormal();

        if (pressLocation != null)
        {
            var otherOwnClicked = moveOntoFig != null && moveOntoFig.color == movingFig.color && !isCastle(from, pressLocation, movingFig, moveOntoFig);
            if (otherOwnClicked)
                selectDeparture(pressLocation, moveOntoFig);
            else
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
                attemptMove(from, pressLocation);
            }
        }
    }

    private function onPress(e:MouseEvent) 
    {
        var pressLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (selected != null)
            destinationPress(pressLocation);
        else
            departurePress(pressLocation);
    }

    private function onMove(e:MouseEvent) 
    {
        var shadowLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (shadowLocation != null && ableToMove(selected, shadowLocation))
            hexes[shadowLocation.j][shadowLocation.i].select();

        if (selectedDest != null && !selectedDest.equals(shadowLocation))
            hexes[selectedDest.j][selectedDest.i].deselect();

        selectedDest = shadowLocation;
    }

    private function onRelease(e:MouseEvent) 
    {
        stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);

        var pressedAt = new IntPoint(selected.i, selected.j);
        var releasedAt = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        figures[pressedAt.j][pressedAt.i].stopDrag();
        if (releasedAt != null && ableToMove(pressedAt, releasedAt) && !releasedAt.equals(pressedAt))
        {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
            selectionBackToNormal();
            attemptMove(pressedAt, releasedAt);
        }
        else
            disposeFigure(figures[pressedAt.j][pressedAt.i], pressedAt);
    }

    //---------------------------------------------------------------------------------------------------------

    private function ableToMove(from:IntPoint, to:IntPoint) 
    {
        var movingFigure = getFigure(from);
        if (movingFigure == null)
            return false;

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

    //------------------------------------------------------------------------------------------------------------------------------------

    private function attemptMove(from:IntPoint, to:IntPoint) 
    {
        if (!ableToMove(from, to))
            return;

        var figure = getFigure(from);
        var moveOntoFigure = getFigure(to);
        var nearIntellector:Bool = nearOwnIntellector(from, figure.color);
        
        stage.removeEventListener(MouseEvent.MOUSE_DOWN, onPress); //To ignore clicking on dialogs

        if (nearIntellector && moveOntoFigure != null && moveOntoFigure.color != figure.color && moveOntoFigure.type != figure.type)
            Dialogs.chameleonConfirm(makeMove.bind(from, to, moveOntoFigure.type), makeMove.bind(from, to), ()->{stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);});
        else if (isFinalForPlayer(to) && figure.type == Progressor)
            Dialogs.promotionSelect(figure.color, makeMove.bind(from, to, _), ()->{stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);});
        else 
            makeMove(from, to);
    }

    private function makeMove(from:IntPoint, to:IntPoint, ?morphInto:FigureType) 
    {
        move(from, to, morphInto);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    public function move(from:IntPoint, to:IntPoint, ?morphInto:FigureType) 
    {
        var figure = getFigure(from);
        var figMoveOnto = getFigure(to);
        
        if (morphInto != null)
        {
            var color = figure.color;
            removeChild(figure);
            figure = new Figure(morphInto, color);
            scaleFigure(figure);
            addChild(figure);
        }

        disposeFigure(figure, to);
        figures[to.j][to.i] = figure;
        figures[from.j][from.i] = null;

        if (figMoveOnto != null)
            if (isCastle(from, to, figure, figMoveOnto))
            {
                disposeFigure(figMoveOnto, from);
                figures[from.j][from.i] = figMoveOnto;
                Assets.getSound("sounds/move.mp3").play();
            }
            else 
            {
                removeChild(figMoveOnto);
                Assets.getSound("sounds/capture.mp3").play();
            }
        else 
            Assets.getSound("sounds/move.mp3").play();
    }

    //-------------------------------------------------------------------------------------------------------------------------------

    private function nearOwnIntellector(loc:IntPoint, color:FigureColor):Bool
    {
        for (dir in [UL, UR, D, DR, DL, U])
        {
            var neighbour = getFigure(getCoordsInRelDirection(loc.i, loc.j, dir, color));
            if (neighbour != null && neighbour.color == color && neighbour.type == Intellector)
                return true;
        }
        return false;
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

    private function getFigure(coords:Null<IntPoint>):Null<Figure>
    {
        return (coords == null || !hexExists(coords.i, coords.j) || figures[coords.j] == null)? null : figures[coords.j][coords.i];
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

    private function isFinalForPlayer(p:IntPoint):Bool
    {
        return p.j == 0 && p.i % 2 == 0;
    }

    private function hexExists(i:Int, j:Int):Bool
    {
        return i >= 0 && i < 9 && j >= 0 && j < 7 && (j != 6 || i % 2 == 0);
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

    //----------------------------------------------------------------------------------------------------------------------------------------------

    private function placeFigures() 
    {
        for (j in 0...7)
            for (i in 0...9)
            {
                var figure = figures[j][i];
                if (figure != null)
                {
                    scaleFigure(figure);
                    disposeFigure(figure, new IntPoint(i, j));
                    addChild(figure);
                }
            }
    }

    private function scaleFigure(figure:Figure) 
    {
        var scale = Math.sqrt(3) * a * 0.85 / figure.height;
        if (figure.type == Progressor)
            scale *= 0.7;
        else if (figure.type == Liberator || figure.type == Defensor)
            scale *= 0.9;
        figure.scaleX = scale;
        figure.scaleY = scale;
    }

    private function disposeFigure(figure:Figure, loc:IntPoint) 
    {
        var coords = hexCoords(loc.i, loc.j);
        figure.x = coords.x;
        figure.y = coords.y;
    }

    //----------------------------------------------------------------------------------------------------------------------------------------------

    private function drag(figure:Figure) 
    {
        removeChild(figure);
        addChild(figure);
        figure.startDrag(true);
    }

    private function addMarkers(from:IntPoint, figure:Figure) 
    {
        for (dest in possibleFields(figure, from.i, from.j))
            if (getFigure(dest) != null)
                hexes[dest.j][dest.i].addRound();
            else
                hexes[dest.j][dest.i].addDot();
    }

    private function removeMarkers(from:IntPoint, figure:Figure) 
    {
        for (dest in possibleFields(figure, from.i, from.j))
            hexes[dest.j][dest.i].removeMarkers();
    }

    private function selectDeparture(dep:IntPoint, depFigure:Figure) 
    {
        selected = dep;
        hexes[dep.j][dep.i].select();
        addMarkers(dep, depFigure);
    }

    private function selectionBackToNormal() 
    {
        removeMarkers(selected, getFigure(selected));

        hexes[selected.j][selected.i].deselect();
        if (selectedDest != null)
            hexes[selectedDest.j][selectedDest.i].deselect();

        selected = null;
        selectedDest = null;
    }

    //----------------------------------------------------------------------------------------------------------------------------------------------

    private function drawHexes() 
    {
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
    }
}