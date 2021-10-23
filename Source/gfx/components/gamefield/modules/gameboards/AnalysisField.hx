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

    public var editMode(default, null):Null<PosEditMode>;
    public var lastApprovedSituationSIP(default, null):String;
    
    public function new() 
    {
        super();
        orientationColor = White;
        autoAppendHistory = false;
        branchingAllowed = true;

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
        shownSituation = currentSituation.copy();
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
        shownSituation = currentSituation.copy();
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

    private override function onMove(e:MouseEvent) 
    {
        if (editMode == null)
            super.onMove(e);
    }

    private override function onRelease(e:MouseEvent) 
    {
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
            toSelectedState(releaseLoc, editMode != null);
        }
        else if (Rules.possible(pressLoc, releaseLoc, getHex) || editMode == Move)
            actionOnFigureMoved(pressLoc, releaseLoc);
        else
            disposeFigure(figures[pressLoc.j][pressLoc.i], pressLoc);
    }

    private function pressHandler(pressLocation:Null<IntPoint>) 
    {
        var pressedFigure:Null<Figure> = getFigure(pressLocation);

        switch state 
        {
            case Neutral:
                if (pressedFigure == null || (editMode == null && pressedFigure.color != shownSituation.turnColor))
                    return;

                toSelectedState(pressLocation, editMode != null);
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
                    toSelectedState(pressLocation, editMode != null);
                    toDragState(pressLocation);
                }
                else 
                    return;
            default:
        }
    }

    private function actionOnFigureMoved(from:IntPoint, to:IntPoint) 
    {
        var movingFigure:Null<Figure> = getFigure(from);
        if (editMode == Move)
        {
            if (movingFigure.type != Intellector) //Intellector will be removed anyway during setFigure()
                deleteFigureUnsafe(from, movingFigure);
            setFigure(to, new Figure(movingFigure.type, movingFigure.color));
        }
        else if (editMode == null)
            initiateMove(from, to);
    }

    private function deleteFigure(location:Null<IntPoint>) 
    {
        var currentOccupier:Figure = getFigure(location);
        if (currentOccupier != null)
            deleteFigureUnsafe(location, currentOccupier);
    }

    private function deleteFigureUnsafe(location:Null<IntPoint>, figure:Figure) 
    {
        removeChild(figure);
        figures[location.j][location.i] = null;
        currentSituation.setWithZobris(location, Hex.empty(), figure.hex);
    }

    private function setFigure(location:Null<IntPoint>, figure:Figure) 
    {
        if (location == null)
            return;

        if (figure.type == Intellector)
        {
            var intPos = currentSituation.intellectorPos.get(figure.color);
            if (intPos != null)
                deleteFigure(intPos);
        }  

        var currentOccupier:Figure = getFigure(location);
        if (currentOccupier != null)
        {
            removeChild(currentOccupier);
            currentSituation.setWithZobris(location, figure.hex, currentOccupier.hex);
        }
        else
            currentSituation.setWithZobris(location, figure.hex, Hex.empty());
        
        figures[location.j][location.i] = figure;
        Factory.addFigure(figure, location, orientationColor == White, this);
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
            lastApprovedSituationSIP = shownSituation.serialize();
        editMode = mode;
    }

    public function constructFromSIP(sip:String) 
    {
        removePiecesClearSelections();
        dropHistory();
        currentSituation = SituationDeserializer.deserialize(sip);
        shownSituation = currentSituation.copy();
        figures = Factory.produceFiguresFromSituation(currentSituation, true, this);
    }

    public function applyChanges() 
    {
        lastApprovedSituationSIP = currentSituation.serialize();
        shownSituation = currentSituation.copy();
        dropHistory();
        editMode = null;
    }

    public function discardChanges()
    {
        constructFromSIP(lastApprovedSituationSIP);
        editMode = null;
    }
}