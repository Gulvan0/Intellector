package gfx.components.gamefield.modules.gameboards;

import gfx.components.gamefield.subsystems.TimeMachine;
import gfx.components.gamefield.common.Figure;
import struct.IntPoint;
import gfx.components.gamefield.subsystems.Factory;
import struct.Hex;
import serialization.SituationDeserializer;
import gfx.components.gamefield.analysis.PosEditMode;
import openfl.display.Stage;
import struct.Situation;
import struct.Ply;
import struct.PieceColor;
import struct.PieceType;
import openfl.Assets;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.display.Sprite;

class AnalysisField extends Field
{
    public var onMadeMove:Void->Void;

    private var editMode:Null<PosEditMode>;
    private var lastApprovedSituationSIP:String;
    
    public function new() 
    {
        super();
        orientationColor = White;
        autoAppendHistory = false;

        hexes = Factory.produceHexes(this, true);
        disposeLetters();
        arrangeStarting();
    }

    //---------------------------------------------------------------------------------------------------------

    public function reset() 
    {
        removePiecesClearSelections();
        constructFromSIP(lastApprovedSituationSIP);
    }
    
    public function clearBoard() 
    {
        removePiecesClearSelections();
        figures = [for (j in 0...7) [for (i in 0...9) null]];
        currentSituation = Situation.empty();
    }

    private function removePiecesClearSelections()
    {
        rmbSelectionBackToNormal();
        
        for (row in figures)
            for (figure in row)
                if (figure != null)
                    removeChild(figure);

        for (hex in lastMoveSelectedHexes)
            hex.lastMoveDeselect();
        lastMoveSelectedHexes = [];
    }

    private function arrangeStarting() 
    {
        figures = Factory.produceFiguresFromDefault(true, this);
        currentSituation = Situation.starting();
        lastApprovedSituationSIP = currentSituation.serialize();
    }

    //---------------------------------------------------------------------------------------------------------

    private override function onPress(e:MouseEvent) 
    {
        if (dialogShown)
            return;

        rmbSelectionBackToNormal();

        var pressLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        switch editMode 
        {
            case null, Move:
                pressHandler(pressLocation);
            case Delete:
                deleteFigure(pressLocation);
            case Set(type, color):
                setFigure(pressLocation, new Figure(type, color));
        }
    }

    private override function onRelease(e:MouseEvent) 
    {
        trace('release handler triggered');
        var pressLoc:IntPoint;
        var releaseLoc = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        switch state
        {
            case Neutral, Selected(_, _):
                return;
            case Dragging(draggedFigureLocation, shadowLocation):
                pressLoc = draggedFigureLocation;
        }

        toNeutralState();

        if (releaseLoc == null)
            disposeFigure(figures[pressLoc.j][pressLoc.i], pressLoc);
        else if (pressLoc.equals(releaseLoc))
        {
            disposeFigure(figures[pressLoc.j][pressLoc.i], pressLoc);
            toSelectedState(releaseLoc);
        }
        else if (Rules.possible(pressLoc, releaseLoc, getHex) || editMode == Move)
            actionOnFigureMoved(pressLoc, releaseLoc);
        else
            disposeFigure(figures[pressLoc.j][pressLoc.i], pressLoc);
    }

    private function pressHandler(pressLocation:Null<IntPoint>) 
    {
        trace('press handler triggered');
        var pressedFigure:Null<Figure> = getFigure(pressLocation);

        switch state 
        {
            case Neutral:
                var shownTurnColor = (plyHistory.length - plyPointer) % 2 == 0? currentSituation.turnColor : opposite(currentSituation.turnColor);
                if (pressedFigure == null || pressedFigure.color != shownTurnColor)
                    return;

                toSelectedState(pressLocation);
                toDragState(pressLocation);
            case Selected(selectedFigureLocation, shadowLocation):
                toNeutralState();
                var alreadySelectedFigure:Null<Figure> = getFigure(selectedFigureLocation);
                if (pressLocation == null || pressLocation.equals(selectedFigureLocation))
                    return;
                else if (Rules.possible(selectedFigureLocation, pressLocation, getHex) || editMode == Move)
                    actionOnFigureMoved(selectedFigureLocation, pressLocation);
                else if (alreadySelectedFigure.color == pressedFigure.color)
                {
                    toSelectedState(pressLocation);
                    toDragState(pressLocation);
                }
                else 
                    return;
            default:
        }
    }

    private function actionOnFigureMoved(from:IntPoint, to:IntPoint) 
    {
        trace('action on figure moved called');
        var movingFigure:Null<Figure> = getFigure(from);
        if (editMode == Move)
        {
            removeChild(movingFigure);
            setFigure(to, movingFigure);
        }
        else if (editMode == null)
            initiateMove(from, to);
    }

    private function deleteFigure(location:IntPoint) 
    {
        var currentOccupier:Figure = getFigure(location);
        if (currentOccupier != null)
        {
            removeChild(currentOccupier);
            figures[location.j][location.i] = null;
            currentSituation.setWithZobris(location, currentOccupier.hex, Hex.empty());
        }
    }

    private function setFigure(location:IntPoint, figure:Figure) 
    {
        var currentOccupier:Figure = getFigure(location);
        if (currentOccupier != null)
            removeChild(currentOccupier);
        
        figures[location.j][location.i] = figure;
        Factory.addFigure(figure, location, orientationColor == White, this);
        currentSituation.setWithZobris(location, currentOccupier.hex, figure.hex);
    }

    //------------------------------------------------------------------------------------------------------------------------------------

    private function dropHistory() 
    {
        plyHistory = [];
        plyPointer = 0;    
    }

    public function changeEditMode(mode:PosEditMode) 
    {
        if (editMode == null)
            lastApprovedSituationSIP = currentSituation.serialize();
        editMode = mode;
    }

    public function constructFromSIP(sip:String) 
    {
        removePiecesClearSelections();
        dropHistory();
        currentSituation = SituationDeserializer.deserialize(sip);
        figures = Factory.produceFiguresFromSituation(currentSituation, true, this);
    }

    public function applyChanges() 
    {
        lastApprovedSituationSIP = currentSituation.serialize();
        dropHistory();
        editMode = null;
    }

    public function discardChanges()
    {
        constructFromSIP(lastApprovedSituationSIP);
        editMode = null;
    }
}