package gfx.components.gamefield.modules;

import utils.AssetManager;
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

enum MoveType
{
    Own;
    ByOpponent;
    Actualization;
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

    public var onOwnMoveMade:Ply->Void;
    
    private var stageRef:Stage;

    public var hexes:Array<Array<Hexagon>>;
    public var figures:Array<Array<Null<Figure>>>;

    public var currentSituation:Situation;
    public var plyHistory:Array<ReversiblePly>;
    public var plyPointer:Int;
    public var autoAppendHistory:Bool = true;

    private var state:FieldState = Neutral;
    private var dialogShown:Bool = false;
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

    private function onMove(e:MouseEvent) 
    {
        var newShadowLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        var oldShadowLocation:IntPoint;
        var selectedLocation:IntPoint;

        switch state 
        {
            case Neutral:
                return;
            case Dragging(draggedFigureLocation, shadowLocation):
                selectedLocation = draggedFigureLocation;
                oldShadowLocation = shadowLocation;
            case Selected(selectedFigureLocation, shadowLocation):
                selectedLocation = selectedFigureLocation;
                oldShadowLocation = shadowLocation;
        }

        if (newShadowLocation == oldShadowLocation)
            return;
        
        if (newShadowLocation != null && Rules.possible(selectedLocation, newShadowLocation, getHex))
            hexes[newShadowLocation.j][newShadowLocation.i].select();

        if (oldShadowLocation != null && oldShadowLocation != selectedLocation)
            hexes[oldShadowLocation.j][oldShadowLocation.i].deselect();

        switch state 
        {
            case Neutral:
            case Dragging(draggedFigureLocation, shadowLocation):
                state = Dragging(draggedFigureLocation, newShadowLocation);
            case Selected(selectedFigureLocation, shadowLocation):
                state = Selected(selectedFigureLocation, newShadowLocation);
        }
    }

    private function onRelease(e) 
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

    private function initiateMove(from:IntPoint, to:IntPoint) 
    {
        var figure = getFigure(from);
        var moveOntoFigure = getFigure(to);
        var nearIntellector:Bool = Rules.areNeighbours(from, currentSituation.intellectorPos[figure.color]);
        
        dialogShown = true;

        var onCanceled:Void->Void = onMoveCanceled.bind(from, figure);
        var simplePly:Ply = Ply.construct(from, to);

        if (nearIntellector && moveOntoFigure != null && moveOntoFigure.color != figure.color && moveOntoFigure.type != figure.type && figure.type != Progressor && moveOntoFigure.type != Intellector)
        {
            var chameleonPly:Ply = Ply.construct(from, to, moveOntoFigure.type);
            Dialogs.chameleonConfirm(move.bind(chameleonPly, Own), move.bind(simplePly, Own), onCanceled);
        }
        else if (to.isFinalForColor(figure.color) && figure.type == Progressor && moveOntoFigure.type != Intellector)
        {
            function onPromotionSelected(piece:PieceType)
            {
                var promotionPly:Ply = Ply.construct(from, to, piece);
                move(promotionPly, Own);
            }
            Dialogs.promotionSelect(figure.color, onPromotionSelected, onCanceled);
        }
        else 
            move(simplePly, Own);
    }

    private function onMoveCanceled(departureCoords:IntPoint, movingPiece:Figure) 
    {
        disposeFigure(movingPiece, departureCoords);
        dialogShown = false;
    }

    public function move(ply:Ply, type:MoveType) 
    {
        if (type != Actualization)
            TimeMachine.endPly(this);

        if (type != Actualization)
            AssetManager.playPlySound(ply, currentSituation);
        
        if (type == Own)
            onOwnMoveMade(ply);

        translateFigures(ply);
        highlightMove([ply.from, ply.to]);

        if (autoAppendHistory)
            appendToHistory(ply);

        playersTurn = !playersTurn;
    }

    public function appendToHistory(ply:Ply)
    {
        plyHistory.push(ply.toReversible(currentSituation));
        plyPointer++;
        currentSituation = currentSituation.makeMove(ply);
    }

    public function translateFigures(ply:Ply) 
    {
        var figure = getFigure(ply.from);
        var figMoveOnto = getFigure(ply.to);
        
        if (ply.morphInto != null)
        {
            var color = figure.color;
            removeChild(figure);
            figure = new Figure(ply.morphInto, color);
            Factory.addFigure(figure, ply.to, orientationColor == White, this);
        }
        else
            disposeFigure(figure, ply.to);

        figures[ply.to.j][ply.to.i] = figure;
        figures[ply.from.j][ply.from.i] = null;

        if (figMoveOnto != null)
            if (Rules.isCastle(ply, currentSituation))
            {
                disposeFigure(figMoveOnto, ply.from);
                figures[ply.from.j][ply.from.i] = figMoveOnto;
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

    private function toNeutralState() 
    {
        switch state 
        {
            case Neutral:
                return;
            case Dragging(draggedFigureLocation, shadowLocation):
                var draggedFigure = getFigure(draggedFigureLocation);
                if (draggedFigure != null)
                    draggedFigure.stopDrag();
                var shadowHexagon = hexes[shadowLocation.j][shadowLocation.i];
                if (shadowHexagon != null)
                    shadowHexagon.deselect();
            case Selected(selectedFigureLocation, shadowLocation):
                removeMarkers(selectedFigureLocation);
                var selectedHexagon = hexes[selectedFigureLocation.j][selectedFigureLocation.i];
                if (selectedHexagon != null)
                    selectedHexagon.deselect();
                var shadowHexagon = hexes[shadowLocation.j][shadowLocation.i];
                if (shadowHexagon != null)
                    shadowHexagon.deselect();
        }
        state = Neutral;
    }

    private function toDragState(draggedFigureLocation:IntPoint) 
    {
        var figure:Figure = getFigure(draggedFigureLocation);
        state = Dragging(draggedFigureLocation, draggedFigureLocation);
        removeChild(figure);
        addChild(figure);
        figure.startDrag(true);
    }

    private function toSelectedState(hexLocation:IntPoint) 
    {
        state = Selected(hexLocation, hexLocation);
        hexes[hexLocation.j][hexLocation.i].select();
        addMarkers(hexLocation);
    }

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