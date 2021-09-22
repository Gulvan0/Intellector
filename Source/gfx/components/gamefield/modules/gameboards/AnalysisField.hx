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
        orientationColor = White;

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

    private override function onPress(e:MouseEvent) 
    {
        var pressLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        switch editMode 
        {
            case null:
                //TODO: Rewrite
                /*if (selected != null)
                    destinationPress(pressLocation);
                else
                    departurePress(pressLocation, c->true);*/
            case Move:
                //TODO: Fill
            case Delete:
                deleteFigure(pressLocation);
            case Set(type, color):
                setFigure(pressLocation, new Figure(type, color));
        }
    }

    private override function onMove(e:MouseEvent) 
    {
        //TODO: Fill
    }

    private override function onRelease(e:MouseEvent) 
    {
        //TODO: Fill
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