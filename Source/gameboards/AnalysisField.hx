package gameboards;

import serialization.SituationDeserializer;
import gfx.components.analysis.PosEditMode;
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
    private var stageRef:Stage;

    private var editMode:Null<PosEditMode>;
    private var lastApprovedSituationSIP:String;
    
    public function new() 
    {
        super();

        hexes = Factory.produceHexes(this, true);
        disposeLetters();
        arrangeDefault();
        addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);

        stageRef = stage;
        stageRef.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
        addEventListener(Event.REMOVED_FROM_STAGE, terminate);
    }

    private function terminate(e) 
    {
        removeEventListener(Event.REMOVED_FROM_STAGE, terminate);
        stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
        stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
        stageRef.removeEventListener(MouseEvent.MOUSE_UP, onRelease);
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
    //TODO: Change behaviour depending on edit mode (current is for 'move' mode)

    private override function onPress(e:MouseEvent) 
    {
        var pressLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (selected != null)
            destinationPress(pressLocation);
        else
            departurePress(pressLocation, c->true);
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

    private override function isOrientationNormal(?movingFigure:PieceColor):Bool
    {   
        if (movingFigure == null)
            return true;
        else
            return movingFigure == White;
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