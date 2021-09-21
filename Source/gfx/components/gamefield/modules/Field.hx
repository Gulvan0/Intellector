package gfx.components.gamefield.modules;

import gfx.utils.Colors;
import utils.Notation;
import gfx.components.gamefield.subsystems.TimeMachine;
import gfx.components.gamefield.subsystems.Factory;
import gfx.utils.PlyScrollType;
import struct.Situation;
import struct.HexTransform;
import struct.ReversiblePly;
import struct.Ply;
import struct.Hex;
import js.lib.Math;
import openfl.display.JointStyle;
import openfl.display.CapsStyle;
import js.Cookie;
import openfl.text.TextFormat;
import openfl.text.TextField;
import Rules.Direction;
import struct.PieceType;
import openfl.Assets;
import openfl.events.Event;
import struct.PieceColor;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.display.Sprite;
import struct.IntPoint;
import gfx.components.gamefield.common.Figure;
import gfx.components.gamefield.common.Hexagon;
import openfl.display.Stage;
using Lambda;

enum Markup 
{
    None;
    Side;
    Over;
}

enum FieldState
{
    Neutral;
    Dragging(draggedFigureLocation:IntPoint, shadowLocation:IntPoint);
    Selected(selectedFigureLocation:IntPoint, shadowLocation:IntPoint);
}

class Field extends Sprite
{
    public static var a:Float = 40;
    public static var markup:Markup = Over;

    public var left(get, never):Float;
    public var top(get, never):Float;
    public var right(get, never):Float;
    public var bottom(get, never):Float;

    public var terminated:Bool = false;
    
    private var stageRef:Stage;

    public var hexes:Array<Array<Hexagon>>;
    public var figures:Array<Array<Null<Figure>>>;

    public var currentSituation:Situation;
    public var plyHistory:Array<ReversiblePly>;
    public var plyPointer:Int;

    private var state:FieldState = Neutral;
    public var orientationColor(default, null):PieceColor; 

    private var lastMoveSelectedHexes:Array<Hexagon>;
    private var redSelectedHexes:Array<Hexagon>;
    private var drawnArrows:Map<String, Sprite>;

    private var rmbStart:Null<IntPoint>;

    public var playersTurn:Bool = true;

    public function get_left():Float
    {
        return x - a;
    }

    public function get_top():Float
    {
        return y - a * Math.sqrt(3) / 2;
    }

    public function get_right():Float
    {
        return left + width;
    }

    public function get_bottom():Float
    {
        return top + height;
    }

    public function new() 
    {
        super();
        lastMoveSelectedHexes = [];
        redSelectedHexes = [];
        drawnArrows = [];

        currentSituation = Situation.starting();
        plyHistory = [];
        plyPointer = 0;

        addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        stageRef = stage;
        stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRMBPress);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
        stage.addEventListener(MouseEvent.MOUSE_UP, onRelease);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
        addEventListener(Event.REMOVED_FROM_STAGE, terminate);
    }

    private function terminate(e) 
    {
        stageRef.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRMBPress);
        stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
        stageRef.removeEventListener(MouseEvent.MOUSE_UP, onRelease);
        stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
        removeEventListener(Event.REMOVED_FROM_STAGE, terminate);
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

    private function makeMove(from:IntPoint, to:IntPoint, ?morphInto:PieceType) 
    {
        throw "To be overriden";
    }

    //----------------------------------------------------------------------------------------------------------

    public function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        TimeMachine.endPly(this);

        var toRevert:Array<ReversiblePly> = plyHistory.splice(plyPointer - cnt, cnt);
        TimeMachine.undoSequence(this, toRevert, cnt < plyPointer? plyHistory[plyPointer - cnt - 1] : null);
        currentSituation = currentSituation.unmakeMoves(toRevert);
        plyPointer -= cnt;

        if (cnt % 2 == 1)
            playersTurn = !playersTurn;
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
                    drawArrow(rmbStart, rmbEnd);
            }

        rmbStart = null;
    }

    //----------------------------------------------------------------------------------------------------------

    ////Deprecated
    /*private function departurePress(pressLocation:IntPoint, isPlayerOwner:PieceColor->Bool) 
    {
        var figure = getFigure(pressLocation);
        if (figure == null || !isPlayerOwner(figure.color))
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
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);
                departurePress(pressLocation, c->true);
            }
            else
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
                attemptMove(from, pressLocation);
            }
        }
    }*/

    //----------------------------------------------------------------------------------------------------------

    public function applyScrolling(type:PlyScrollType) 
    {
        switch type 
        {
            case Home: TimeMachine.homePly(this);
            case Prev: TimeMachine.prevPly(this);
            case Next: TimeMachine.nextPly(this);
            case End: TimeMachine.endPly(this);
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
        
        stage.removeEventListener(MouseEvent.MOUSE_DOWN, onPress); //To ignore clicking on dialogs (TODO: just check dialogShown:Bool)

        var onCanceled:Void->Void = onMoveCanceled.bind(from, figure);

        if (nearIntellector && moveOntoFigure != null && moveOntoFigure.color != figure.color && moveOntoFigure.type != figure.type && figure.type != Progressor && moveOntoFigure.type != Intellector)
            Dialogs.chameleonConfirm(makeMove.bind(from, to, moveOntoFigure.type), makeMove.bind(from, to), onCanceled);
        else if (to.isFinalForColor(figure.color) && figure.type == Progressor && moveOntoFigure.type != Intellector)
            Dialogs.promotionSelect(figure.color, makeMove.bind(from, to, _), onCanceled);
        else 
            makeMove(from, to);
    }

    private function onMoveCanceled(departureCoords:IntPoint, movingPiece:Figure) 
    {
        disposeFigure(movingPiece, departureCoords);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    public function move(ply:Ply, ?ignoreHistory:Bool = false, ?noSound:Bool = false) 
    {
        if (!ignoreHistory)
        {
            TimeMachine.endPly(this);

            plyHistory.push(ply.toReversible(currentSituation));
            plyPointer++;
        }

        currentSituation = currentSituation.makeMove(ply);
        if (!noSound)
            playSound(ply);
        translateFigures(ply.from, ply.to, ply.morphInto);
        highlightMove([ply.from, ply.to]);

        playersTurn = !playersTurn;
    }

    public function translateFigures(from:IntPoint, to:IntPoint, ?morphInto:PieceType) 
    {
        var figure = getFigure(from);
        var figMoveOnto = getFigure(to);
        
        if (morphInto != null)
        {
            var color = figure.color;
            removeChild(figure);
            figure = new Figure(morphInto, color);
            Factory.addFigure(figure, to, orientationColor == White, this);
        }
        else
            disposeFigure(figure, to);

        figures[to.j][to.i] = figure;
        figures[from.j][from.i] = null;

        if (figMoveOnto != null)
            if (isCastle(from, to, figure, figMoveOnto))
            {
                disposeFigure(figMoveOnto, from);
                figures[from.j][from.i] = figMoveOnto;
            }
            else 
                removeChild(figMoveOnto);
    }

    public function highlightMove(hexesCoords:Array<IntPoint>) 
    {
        for (hex in lastMoveSelectedHexes)
            hex.lastMoveDeselect();

        lastMoveSelectedHexes = [for (coords in hexesCoords) hexes[coords.j][coords.i]];

        for (hex in lastMoveSelectedHexes)
            hex.lastMoveSelect();
    }

    public function playSound(ply:Ply)
    {
        var figure = getFigure(ply.from);
        var figMoveOnto = getFigure(ply.to);

        if (figMoveOnto == null || isCastle(ply.from, ply.to, figure, figMoveOnto))
            Assets.getSound("sounds/move.mp3").play();
        else 
            Assets.getSound("sounds/capture.mp3").play();
    }

    private function isCastle(pos1:IntPoint, pos2:IntPoint, fig1:Figure, fig2:Figure)
    {
        return ((fig1.type == Intellector && fig2.type == Defensor) || (fig1.type == Defensor && fig2.type == Intellector)) && fig1.color == fig2.color;
    }

    private function nearOwnIntellector(loc:IntPoint, color:PieceColor):Bool
    {
        for (dir in [UL, UR, D, DR, DL, U])
        {
            var neighbour = getFigure(Rules.getOneStepCoords(loc.i, loc.j, dir));
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

        for (dest in Rules.possibleFields(from, getHex))
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

    public function getHex(coords:Null<IntPoint>):Null<Hex>
    {
        if (coords == null || !hexExists(coords.i, coords.j))
            return null;
        else
        {
            var occupier:Null<Figure> = figures[coords.j][coords.i];
            if (occupier == null)
                return Hex.empty();
            else 
                return occupier.hex;
        }
    }
    
    public function getFigure(coords:Null<IntPoint>):Null<Figure>
    {
        return (coords == null || !hexExists(coords.i, coords.j))? null : figures[coords.j][coords.i];
    }

    public static function hexExists(i:Int, j:Int):Bool
    {
        return i >= 0 && i < 9 && j >= 0 && j < 7 - i % 2;
    }

    public function hexCoords(i:Int, j:Int):Point
    {
        return absHexCoords(i, j, orientationColor == White);
    }

    public static function absHexCoords(i:Int, j:Int, isOrientationNormal:Bool):Point
    {
        if (!isOrientationNormal)
        {
            j = 6 - j - i % 2;
            i = 8 - i;
        }
            

        var p:Point = new Point(0, 0);
        p.x = 3 * a * i / 2;
        p.y = Math.sqrt(3) * a * j;
        if (i % 2 == 1)
            p.y += Math.sqrt(3) * a / 2;
        return p;
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
        for (dest in Rules.possibleFields(from, getHex))
            if (getFigure(dest) != null)
                hexes[dest.j][dest.i].addRound();
            else
                hexes[dest.j][dest.i].addDot();
    }

    private function removeMarkers(from:IntPoint) 
    {
        for (dest in Rules.possibleFields(from, getHex))
            hexes[dest.j][dest.i].removeMarkers();
    }

    /*private function selectDeparture(dep:IntPoint) 
    {
        selected = dep;
        hexes[dep.j][dep.i].select();
        addMarkers(dep);
    }*/

    /*private function selectionBackToNormal() 
    {
        removeMarkers(selected);

        hexes[selected.j][selected.i].deselect();
        if (selectedDest != null)
            hexes[selectedDest.j][selectedDest.i].deselect();

        selected = null;
        selectedDest = null;
    }*/

    public function rmbSelectionBackToNormal() 
    {
        for (hex in redSelectedHexes)
            hex.redDeselect();
        for (arrow in drawnArrows)
            removeChild(arrow);
        drawnArrows = [];
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------------------

    public function drawArrow(from:IntPoint, to:IntPoint)
    {
        var fromPos:Point = hexCoords(from.i, from.j);
        var toPos:Point = hexCoords(to.i, to.j);

        var thickness:Float = Field.a / 6;
        var lrLength:Float = Field.a / 2;
        var dr = fromPos.subtract(toPos);
        var rotated1 = new Point(Math.sqrt(3)/2 * dr.x + 1/2 * dr.y, -1/2 * dr.x + Math.sqrt(3)/2 * dr.y);
        var rotated2 = new Point(Math.sqrt(3)/2 * dr.x - 1/2 * dr.y, 1/2 * dr.x + Math.sqrt(3)/2 * dr.y);
        rotated1.normalize(lrLength);
        rotated2.normalize(lrLength);
        var branch1 = toPos.add(rotated1);
        var branch2 = toPos.add(rotated2);

        var arrow:Sprite = new Sprite();
        arrow.graphics.lineStyle(thickness, Colors.arrow, 0.7, null, null, CapsStyle.SQUARE, JointStyle.MITER);
        arrow.graphics.moveTo(fromPos.x, fromPos.y);
        arrow.graphics.lineTo(toPos.x, toPos.y);
        arrow.graphics.lineTo(branch1.x, branch1.y);
        arrow.graphics.moveTo(toPos.x, toPos.y);
        arrow.graphics.lineTo(branch2.x, branch2.y);
        
        var code = '${from.i}${from.j}${to.i}${to.j}';
        drawnArrows.set(code, arrow);
        addChild(arrow);
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------------------

    private function disposeLetters() 
    {
        if (Field.markup == None)
            return;

        var bottomLocations = [for (i in 0...9) new IntPoint(i, orientationColor == White? 6 - i % 2 : 0)];
        for (loc in bottomLocations)
        {
            var letter = createLetter(Notation.getColumn(loc.i));
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