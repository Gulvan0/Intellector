package gfx.components.gamefield.modules.gameboards;

import gfx.components.gamefield.common.Figure;
import gfx.components.gamefield.subsystems.TimeMachine;
import gfx.components.gamefield.subsystems.Factory;
import openfl.display.Stage;
import serialization.PlyDeserializer;
import struct.Ply;
import Networker.OngoingBattleData;
import Networker.MoveData;
import struct.PieceType;
import struct.IntPoint;
import openfl.events.Event;
import struct.PieceColor;
import openfl.events.MouseEvent;
using StringTools;

class PlayingField extends Field
{
    public var playerColor:PieceColor;

    public function new(playerIsWhite:Bool) 
    {
        super();

        playerColor = playerIsWhite? White : Black;
        orientationColor = playerColor;
        playersTurn = playerIsWhite;

        hexes = Factory.produceHexes(this, playerIsWhite);
        disposeLetters();
        figures = Factory.produceFiguresFromDefault(playerIsWhite, this);
    }

    //---------------------------------------------------------------------------------------------------------

    private override function onPress(e:MouseEvent) 
    {
        rmbSelectionBackToNormal();
        if (!playersTurn || terminated)
            return;

        var pressLocation:Null<IntPoint> = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        var pressedFigure:Null<Figure> = getFigure(pressLocation);

        if (pressLocation != null && plyPointer < plyHistory.length)
            TimeMachine.endPly(this);

        switch state 
        {
            case Neutral:
                if (pressedFigure == null || pressedFigure.color != playerColor)
                    return;

                toSelectedState(pressLocation);
                toDragState(pressLocation);
            case Selected(selectedFigureLocation, shadowLocation):
                toNeutralState();
                var alreadySelectedFigure:Null<Figure> = getFigure(selectedFigureLocation);
                if (pressLocation == null || pressLocation.equals(selectedFigureLocation))
                    return;
                else if (Rules.possible(selectedFigureLocation, pressLocation, getHex))
                    initiateMove(selectedFigureLocation, pressLocation);
                else if (alreadySelectedFigure.color == pressedFigure.color)
                    toSelectedState(pressLocation);
                else 
                    return;
            default:
        }
    }

    private override function onMove(e:MouseEvent) 
    {
        if (!playersTurn || terminated)
            return;

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

    private override function onRelease(e:MouseEvent) 
    {
        if (!playersTurn || terminated)
            return;

        var pressLoc:IntPoint;
        var releaseLoc = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        switch state
        {
            case Neutral, Selected(_, _):
                return;
            case Dragging(draggedFigureLocation, shadowLocation):
                pressLoc = draggedFigureLocation;
        }

        if (releaseLoc == null)
            disposeFigure(figures[pressLoc.j][pressLoc.i], pressLoc);
        else if (pressLoc.equals(releaseLoc))
        {
            disposeFigure(figures[pressLoc.j][pressLoc.i], pressLoc);
            toSelectedState(releaseLoc);
        }
        else if (Rules.possible(pressLoc, releaseLoc, getHex))
            initiateMove(pressLoc, releaseLoc);
        else
            disposeFigure(figures[pressLoc.j][pressLoc.i], pressLoc);
    }
}