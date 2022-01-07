package gfx.components.gamefield.modules.gameboards;

import gfx.components.gamefield.common.Figure;
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

        hexes = Factory.produceHexes(this, playerIsWhite);
        disposeLetters();
        figures = Factory.produceFiguresFromDefault(playerIsWhite, this);
    }

    //---------------------------------------------------------------------------------------------------------

    private override function onPress(e:MouseEvent) 
    {
        if (dialogShown)
            return;

        rmbSelectionBackToNormal();
        if (currentSituation.turnColor != playerColor || terminated)
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
                {
                    toSelectedState(pressLocation);
                    toDragState(pressLocation);
                }
                else 
                    return;
            default:
        }
    }

    private override function onRelease(e:MouseEvent) 
    {
        if (currentSituation.turnColor != playerColor || terminated)
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

        toNeutralState();

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