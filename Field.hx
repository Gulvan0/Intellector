import utils.AssetManager;
import gfx.utils.Colors;
import utils.Notation;
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
import openfl.display.Stage;
using Lambda;

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

    public function new() 
    {
        super();
        lastMoveSelectedHexes = [];
        redSelectedHexes = [];
        drawnArrows = [];

        currentSituation = Situation.starting();
        shownSituation = currentSituation.copy();
        plyHistory = [];
        plyPointer = 0;

        addEventListener(Event.ADDED_TO_STAGE, init);
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

        var newShadowLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (equal(newShadowLocation, oldShadowLocation))
            return;
        
        if (newShadowLocation != null && Rules.possible(selectedLocation, newShadowLocation, getHex))
            hexes[newShadowLocation.j][newShadowLocation.i].select();

        if (oldShadowLocation != null && !oldShadowLocation.equals(selectedLocation))
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

        var toRevert:Array<ReversiblePly> = plyHistory.splice(plyHistory.length - cnt, cnt);

        TimeMachine.undoSequence(this, toRevert, cnt < plyPointer? plyHistory[plyPointer - cnt - 1] : null);
        
        currentSituation = currentSituation.unmakeMoves(toRevert);
        shownSituation = currentSituation.copy();
        plyPointer = Math.min(plyPointer, plyHistory.length);
    }

    public function revertToShown() 
    {
        var revertCnt:Int = plyHistory.length - plyPointer;
        if (revertCnt < 1)
            return;

        plyHistory.splice(plyPointer, revertCnt);
        currentSituation = shownSituation.copy();
    }

    //----------------------------------------------------------------------------------------------------------

    private function initiateMove(from:IntPoint, to:IntPoint) 
    {
        var figure = getFigure(from);
        var moveOntoFigure = getFigure(to);
        var nearIntellector:Bool = Rules.areNeighbours(from, shownSituation.intellectorPos[figure.color]);

        var onCanceled:Void->Void = onMoveCanceled.bind(from, figure);
        var simplePly:Ply = Ply.construct(from, to);

        if (nearIntellector && moveOntoFigure != null && moveOntoFigure.color != figure.color && moveOntoFigure.type != figure.type && figure.type != Progressor && moveOntoFigure.type != Intellector)
        {
            function onChameleonDecisionMade(morph:Bool)
            {
                dialogShown = false;

                if (morph)
                {
                    var chameleonPly:Ply = Ply.construct(from, to, moveOntoFigure.type);
                    move(chameleonPly, Own);
                }
                else
                    move(simplePly, Own);
            }

            dialogShown = true;
            Dialogs.chameleonConfirm(onChameleonDecisionMade, onCanceled);
        }
        else if (to.isFinalForColor(figure.color) && figure.type == Progressor && (moveOntoFigure == null || moveOntoFigure.type != Intellector))
        {
            function onPromotionSelected(piece:PieceType)
            {
                dialogShown = false;
                
                var promotionPly:Ply = Ply.construct(from, to, piece);
                move(promotionPly, Own);
            }

            dialogShown = true;
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
        if (type != Actualization && !branchingAllowed)
            TimeMachine.endPly(this);

        if (type != Actualization)
            AssetManager.playPlySound(ply, shownSituation);
        
        if (type == Own)
            onOwnMoveMade(ply);

        translateFigures(ply);
        highlightMove([ply.from, ply.to]);

        if (autoAppendHistory)
            appendToHistory(ply);
    }

    public function appendToHistory(ply:Ply, ?updateShownSituation:Bool = true)
    {
        if (plyPointer != plyHistory.length && updateShownSituation)
            throw "Field.appendToHistory() called with pointer not being at the end of a line";
        plyHistory.push(ply.toReversible(currentSituation));
        currentSituation = currentSituation.makeMove(ply);
        if (updateShownSituation)
        {
            shownSituation = currentSituation.copy();
            plyPointer++;
        }
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
            if (Rules.isCastle(ply, shownSituation))
            {
                disposeFigure(figMoveOnto, ply.from);
                figures[ply.from.j][ply.from.i] = figMoveOnto;
            }
            else 
                removeChild(figMoveOnto);
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------------------

    private function toNeutralState() 
    {
        switch state 
        {
            case Neutral:
                return;
            case Dragging(draggedFigureLocation, shadowLocation):
                if (draggedFigureLocation != null)
                {
                    removeMarkers(draggedFigureLocation);
                    var departureHexagon = hexes[draggedFigureLocation.j][draggedFigureLocation.i];
                    if (departureHexagon != null)
                        departureHexagon.deselect();
                    var draggedFigure = getFigure(draggedFigureLocation);
                    if (draggedFigure != null)
                        draggedFigure.stopDrag();
                }
                if (shadowLocation != null)
                {
                    var shadowHexagon = hexes[shadowLocation.j][shadowLocation.i];
                    if (shadowHexagon != null)
                        shadowHexagon.deselect();
                }
            case Selected(selectedFigureLocation, shadowLocation):
                if (selectedFigureLocation != null)
                {
                    removeMarkers(selectedFigureLocation);
                    var selectedHexagon = hexes[selectedFigureLocation.j][selectedFigureLocation.i];
                    if (selectedHexagon != null)
                        selectedHexagon.deselect();
                }
                if (shadowLocation != null)
                {
                    var shadowHexagon = hexes[shadowLocation.j][shadowLocation.i];
                    if (shadowHexagon != null)
                        shadowHexagon.deselect();
                }
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

    private function toSelectedState(hexLocation:IntPoint, ?noMarkers:Bool = false) 
    {
        state = Selected(hexLocation, hexLocation);
        hexes[hexLocation.j][hexLocation.i].select();
        if (!noMarkers)
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
}