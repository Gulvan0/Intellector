package;

import js.lib.Math;
import openfl.display.JointStyle;
import openfl.display.CapsStyle;
import js.Cookie;
import openfl.text.TextFormat;
import openfl.text.TextField;
import Rules.Direction;
import Figure.FigureType;
import openfl.Assets;
import openfl.events.Event;
import Figure.FigureColor;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.display.Sprite;

enum Markup 
{
    None;
    Side;
    Over;
}

class Field extends Sprite
{
    public static var a:Float = 40;
    public static var markup:Markup = Over;

    public var hexes:Array<Array<Hexagon>>;
    public var figures:Array<Array<Null<Figure>>>;

    private var selected:Null<IntPoint>;
    private var selectedDest:Null<IntPoint>;
    private var lastMoveSelectedHexes:Array<Hexagon>;

    private var redSelectedHexes:Array<Hexagon>;
    private var drawnArrows:Map<String, Sprite>;

    private var rmbStart:Null<IntPoint>;

    public var playersTurn:Bool = true;

    public function new() 
    {
        super();
        lastMoveSelectedHexes = [];
        redSelectedHexes = [];
        drawnArrows = [];
        addEventListener(Event.ADDED_TO_STAGE, initRMB);
    }

    private function initRMB(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, initRMB);
        stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRMBPress);
        addEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
    }

    private function removeListeners(e) 
    {
        stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRMBPress);
        removeEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
    }

    public static function initConstants() 
    {
        if (Cookie.exists("markup"))
            markup = Markup.createByName(Cookie.get("markup"));
    }

    public function getHeight():Float
    {
        return Field.a * Math.sqrt(3) * 7;
    }

    //----------------------------------------------------------------------------------------------------------

    private function onPress(e) 
    {
        throw "To be overriden";
    }

    private function onMove(e) 
    {
        throw "To be overriden";
    }

    private function onRelease(e) 
    {
        throw "To be overriden";
    }

    private function makeMove(from:IntPoint, to:IntPoint, ?morphInto:FigureType) 
    {
        throw "To be overriden";
    }

    private function isOrientationNormal(?movingFigure:FigureColor):Bool
    {   
        throw "To be overriden";
    }

    //----------------------------------------------------------------------------------------------------------

    private function onRMBPress(e:MouseEvent) 
    {
        rmbStart = posToIndexes(e.stageX - x, e.stageY - y);
        if (rmbStart != null)
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRMBRelease);
    }

    private function onRMBRelease(e) 
    {
        stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRMBRelease);

        var rmbEnd = posToIndexes(e.stageX - x, e.stageY - y);
        if (rmbStart != null && rmbEnd != null)
            if (rmbStart.equals(rmbEnd))
            {
                var hexToSelect = hexes[rmbStart.j][rmbStart.i];
                if (hexToSelect.redSelected)
                {
                    hexToSelect.redDeselect();
                    redSelectedHexes.remove(hexToSelect);
                }
                else 
                {
                    hexToSelect.redSelect();
                    redSelectedHexes.push(hexToSelect);

                }
            }
            else
            {
                var code = '${rmbStart.i}${rmbStart.j}${rmbEnd.i}${rmbEnd.j}';
                if (drawnArrows.exists(code))
                {
                    removeChild(drawnArrows[code]);
                    drawnArrows.remove(code);
                }
                else 
                {
                    var arrow = drawArrow(rmbStart, rmbEnd);
                    drawnArrows.set(code, arrow);
                    addChild(arrow);
                }
            }

        rmbStart = null;
    }

    //----------------------------------------------------------------------------------------------------------

    private function departurePress(pressLocation:IntPoint, playerIsOwner:FigureColor->Bool) 
    {
        var figure = getFigure(pressLocation);
        if (figure == null || !playerIsOwner(figure.color))
            return;

        rmbSelectionBackToNormal();
        selectDeparture(pressLocation);
        drag(figure);

        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onRelease);
    }

    private function destinationPress(pressLocation:IntPoint) 
    {
        var from = new IntPoint(selected.i, selected.j);
        var movingFig = getFigure(selected);
        var moveOntoFig = getFigure(pressLocation);

        rmbSelectionBackToNormal();
        selectionBackToNormal();

        if (pressLocation != null)
        {
            var otherOwnClicked = moveOntoFig != null && moveOntoFig.color == movingFig.color && !isCastle(from, pressLocation, movingFig, moveOntoFig);
            if (otherOwnClicked)
                selectDeparture(pressLocation);
            else
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
                attemptMove(from, pressLocation);
            }
        }
    }

    //----------------------------------------------------------------------------------------------------------

    private function attemptMove(from:IntPoint, to:IntPoint) 
    {
        if (!ableToMove(from, to))
            return;

        var figure = getFigure(from);
        var moveOntoFigure = getFigure(to);
        var nearIntellector:Bool = nearOwnIntellector(from, figure.color);
        
        stage.removeEventListener(MouseEvent.MOUSE_DOWN, onPress); //To ignore clicking on dialogs

        if (nearIntellector && moveOntoFigure != null && moveOntoFigure.color != figure.color && moveOntoFigure.type != figure.type && figure.type != Progressor)
            Dialogs.chameleonConfirm(makeMove.bind(from, to, moveOntoFigure.type), makeMove.bind(from, to), ()->{stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);});
        else if (isFinalForPlayer(to) && figure.type == Progressor)
            Dialogs.promotionSelect(figure.color, makeMove.bind(from, to, _), ()->{stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);});
        else 
            makeMove(from, to);
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
            Factory.addFigure(figure, to, this);
        }
        else
            disposeFigure(figure, to);

        figures[to.j][to.i] = figure;
        figures[from.j][from.i] = null;

        for (hex in lastMoveSelectedHexes)
            hex.lastMoveDeselect();

        lastMoveSelectedHexes = [hexes[from.j][from.i], hexes[to.j][to.i]];

        for (hex in lastMoveSelectedHexes)
            hex.lastMoveSelect();

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

        playersTurn = !playersTurn;
    }

    private function isCastle(pos1:IntPoint, pos2:IntPoint, fig1:Figure, fig2:Figure)
    {
        return ((fig1.type == Intellector && fig2.type == Defensor) || (fig1.type == Defensor && fig2.type == Intellector)) && fig1.color == fig2.color;
    }

    private function nearOwnIntellector(loc:IntPoint, color:FigureColor):Bool
    {
        for (dir in [UL, UR, D, DR, DL, U])
        {
            var neighbour = getFigure(Rules.getCoordsInRelDirection(loc.i, loc.j, dir, true));
            if (neighbour != null && neighbour.color == color && neighbour.type == Intellector)
                return true;
        }
        return false;
    }

    //----------------------------------------------------------------------------------------------------------------------------------------

    private function posToIndexes(x:Float, y:Float):Null<IntPoint>
    {
        var closest:IntPoint = null;
        var distanceSqr:Float = a * a;
        for (j in 0...7)
            for (i in 0...9)
            {
                if (!Field.hexExists(i, j))
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
    
    private function ableToMove(from:IntPoint, to:IntPoint) 
    {
        var movingFigure = getFigure(from);
        if (movingFigure == null)
            return false;

        for (dest in Rules.possibleFields(from.i, from.j, getFigure, isOrientationNormal(movingFigure.color)))
            if (to.equals(dest))
                return true;
        return false;    
    }

    //----------------------------------------------------------------------------------------------------------------------------------------

    private function disposeFigure(figure:Figure, loc:IntPoint) 
    {
        var coords = hexCoords(loc.i, loc.j);
        figure.x = coords.x;
        figure.y = coords.y;
    }

    //----------------------------------------------------------------------------------------------------------------------------------------

    public function getFigure(coords:Null<IntPoint>):Null<Figure>
    {
        return (coords == null || !hexExists(coords.i, coords.j))? null : figures[coords.j][coords.i];
    }

    public static function hexExists(i:Int, j:Int):Bool
    {
        return i >= 0 && i < 9 && j >= 0 && j < 7 && (j != 6 || i % 2 == 0);
    }

    public static function hexCoords(i:Int, j:Int):Point
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
    
    //----------------------------------------------------------------------------------------------------------------------------------------------

    private function drag(figure:Figure) 
    {
        removeChild(figure);
        addChild(figure);
        figure.startDrag(true);
    }

    private function addMarkers(from:IntPoint) 
    {
        for (dest in Rules.possibleFields(from.i, from.j, getFigure, isOrientationNormal(getFigure(from).color)))
            if (getFigure(dest) != null)
                hexes[dest.j][dest.i].addRound();
            else
                hexes[dest.j][dest.i].addDot();
    }

    private function removeMarkers(from:IntPoint) 
    {
        for (dest in Rules.possibleFields(from.i, from.j, getFigure, isOrientationNormal(getFigure(from).color)))
            hexes[dest.j][dest.i].removeMarkers();
    }

    private function selectDeparture(dep:IntPoint) 
    {
        selected = dep;
        hexes[dep.j][dep.i].select();
        addMarkers(dep);
    }

    private function selectionBackToNormal() 
    {
        removeMarkers(selected);

        hexes[selected.j][selected.i].deselect();
        if (selectedDest != null)
            hexes[selectedDest.j][selectedDest.i].deselect();

        selected = null;
        selectedDest = null;
    }

    private function rmbSelectionBackToNormal() 
    {
        for (hex in redSelectedHexes)
            hex.redDeselect();
        for (arrow in drawnArrows)
            removeChild(arrow);
        drawnArrows = [];
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------------------

    public static function drawArrow(from:IntPoint, to:IntPoint):Sprite
    {
        var fromPos:Point = hexCoords(from.i, from.j);
        var toPos:Point = hexCoords(to.i, to.j);

        var thickness:Float = 10;
        var alpha:Float = Math.atan2(toPos.x - fromPos.x, toPos.y - fromPos.y);
        var lPos:Point = new Point(toPos.x - 3 * thickness * Math.sin(alpha + Math.PI / 6), toPos.y - 3 * thickness * Math.cos(alpha + Math.PI / 6));
        var rPos:Point = new Point(toPos.x - 3 * thickness * Math.sin(alpha - Math.PI / 6), toPos.y - 3 * thickness * Math.cos(alpha - Math.PI / 6));

        var arrow:Sprite = new Sprite();
        arrow.graphics.lineStyle(thickness, Colors.arrow, 0.7, null, null, CapsStyle.SQUARE, JointStyle.MITER);
        arrow.graphics.moveTo(fromPos.x, fromPos.y);
        arrow.graphics.lineTo(toPos.x - Math.sin(alpha) * thickness * Math.sqrt(3) * 1.75, toPos.y - Math.cos(alpha) * Math.sqrt(3) * thickness * 1.75);
        arrow.graphics.moveTo(toPos.x, toPos.y);
        arrow.graphics.lineStyle(1, Colors.arrow, 0.7, null, null, CapsStyle.SQUARE, JointStyle.MITER);
        arrow.graphics.beginFill(Colors.arrow, 0.7);
        arrow.graphics.lineTo(toPos.x, toPos.y);
        arrow.graphics.lineTo(lPos.x, lPos.y);
        arrow.graphics.lineTo(rPos.x, rPos.y);
        arrow.graphics.lineTo(toPos.x, toPos.y);
        arrow.graphics.endFill();
        return arrow;
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------------------

    private function disposeLetters() 
    {
        if (Field.markup == None)
            return;

        var bottomLocations = [for (i in 0...9) new IntPoint(i, (i % 2 == 0)? 6 : 5)];
        for (loc in bottomLocations)
        {
            var letter = createLetter(Position.notationI(loc.i, isOrientationNormal()));
            letter.x = hexes[loc.j][loc.i].x - letter.textWidth/2 - 5;
            letter.y = hexes[loc.j][loc.i].y + Field.a * Math.sqrt(3) / 2;
            addChild(letter); 
        }
    }

    private function createLetter(letter:String):TextField 
    {
        var tf = new TextField();
        tf.text = letter;
        tf.setTextFormat(new TextFormat(null, 28, Colors.border, true));
        tf.selectable = false;
        return tf;
    }
}