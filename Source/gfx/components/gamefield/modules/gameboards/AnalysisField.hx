package gfx.components.gamefield.modules.gameboards;

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

        hexes = Factory.produceHexes(this, true);
        disposeLetters();
        arrangeDefault();
    }

    //---------------------------------------------------------------------------------------------------------

    public function reset() 
    {
        removePiecesClearSelections();
        arrangeDefault();
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

    private function arrangeDefault() 
    {
        figures = Factory.produceFiguresFromDefault(true, this);
        currentSituation = Situation.starting();
    }

    //---------------------------------------------------------------------------------------------------------
    //TODO: Fill for Move, replace isOwner() for null

    /*private override function onPress(e:MouseEvent) 
    {
        var pressLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        switch editMode 
        {
            case null, Move:
                if (selected != null)
                    destinationPress(pressLocation);
                else
                    departurePress(pressLocation, c->true);
            case Delete:
                deleteFigure(pressLocation);
            case Set(type, color):
                setFigure(pressLocation, new Figure(type, color));
        }
    }

    private override function onMove(e:MouseEvent) 
    {
        var shadowLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (shadowLocation != null && ableToMove(selected, shadowLocation))
            hexes[shadowLocation.j][shadowLocation.i].select();

        if (selectedDest != null && !selectedDest.equals(shadowLocation))
            hexes[selectedDest.j][selectedDest.i].deselect();

        selectedDest = shadowLocation;
    }

    private override function onRelease(e:MouseEvent) 
    {
        stageRef.removeEventListener(MouseEvent.MOUSE_UP, onRelease);

        var pressedAt = new IntPoint(selected.i, selected.j);
        var releasedAt = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        figures[pressedAt.j][pressedAt.i].stopDrag();
        if (releasedAt != null && ableToMove(pressedAt, releasedAt) && !releasedAt.equals(pressedAt))
        {
            stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
            selectionBackToNormal();
            attemptMove(pressedAt, releasedAt);
        }
        else
            disposeFigure(figures[pressedAt.j][pressedAt.i], pressedAt);
    }*/

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

    private override function makeMove(from:IntPoint, to:IntPoint, ?morphInto:PieceType) 
    {
        var ply:Ply = new Ply();
        ply.from = from;
        ply.to = to;
        ply.morphInto = morphInto;

        move(ply, true);
        onMadeMove();
        stageRef.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
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
        currentSituation = SituationDeserializer.deserialize(sip);
        figures = Factory.produceFiguresFromSituation(currentSituation, true, this);
    }

    public function applyChanges() 
    {
        editMode = null;
        lastApprovedSituationSIP = currentSituation.serialize();
    }

    public function discardChanges()
    {
        constructFromSIP(lastApprovedSituationSIP);
        editMode = null;
    }
}