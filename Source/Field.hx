package;

import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.display.Sprite;

class Field extends Sprite
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
                if (j == 6 && i % 2 == 1)
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
        addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    private function onPress(e:MouseEvent) 
    {
        var indexes = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        if (indexes == null)
            return;

        if (selected != null)
        {
            if (ableToMove())
                move(selected.i, selected.j, indexes.i, indexes.j);
            hexes[selected.j][selected.i].deselect();
            if (selectedDest != null)
                hexes[selectedDest.j][selectedDest.i].deselect();
            selected = null;
            selectedDest = null;
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
            }
            removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
            addEventListener(MouseEvent.MOUSE_MOVE, onMove);
            addEventListener(MouseEvent.MOUSE_UP, onRelease);
        }
    }

    private function onMove(e:MouseEvent) 
    {
        var indexes = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        if (indexes == null && selectedDest != null)
        {
            hexes[selectedDest.j][selectedDest.i].deselect();
            selectedDest = null;
        }
        if (indexes != null && !indexes.equals(selected) && !indexes.equals(selectedDest))
        {
            if (selectedDest != null)
                hexes[selectedDest.j][selectedDest.i].deselect();
            selectedDest = indexes;
            if (selectedDest != null)
                hexes[selectedDest.j][selectedDest.i].select();
        }
    }

    private function onRelease(e:MouseEvent) 
    {
        removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
        removeEventListener(MouseEvent.MOUSE_UP, onRelease);
        var indexes = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        figures[selected.j][selected.i].stopDrag();
        if (indexes != null && ableToMove() && !indexes.equals(selected))
        {
            move(selected.i, selected.j, indexes.i, indexes.j);
            hexes[selected.j][selected.i].deselect();
            if (selectedDest != null)
                hexes[selectedDest.j][selectedDest.i].deselect();
            selected = null;
            selectedDest = null;
        }
        else
            disposeFigure(figures[selected.j][selected.i], selected.i, selected.j);
        addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    private function ableToMove():Bool 
    {
        return true;    
    }

    private function move(fromI:Int, fromJ:Int, toI:Int, toJ:Int) 
    {
        var figure = figures[fromJ][fromI];
        disposeFigure(figure, toI, toJ);
        figures[toJ][toI] = figure;
        figures[fromJ][fromI] = null;
    }

    private function posToIndexes(x:Float, y:Float):Null<IntPoint>
    {
        var closest:IntPoint = null;
        var distanceSqr:Float = a * a;
        for (j in 0...7)
            for (i in 0...9)
            {
                if (j == 6 && i % 2 == 1)
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