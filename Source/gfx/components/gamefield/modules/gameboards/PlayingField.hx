package gfx.components.gamefield.modules.gameboards;

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

    public var onPlayerMadeMove:MoveData->Void;

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
        /*rmbSelectionBackToNormal();
        if (!playersTurn || terminated)
            return;

        var pressLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        
        if (pressLocation != null && plyPointer < plyHistory.length)
            endPly();

        if (selected != null)
            destinationPress(pressLocation);
        else
            departurePress(pressLocation, c -> (c == playerColor));*/
    }

    private override function onMove(e:MouseEvent) 
    {
        /*if (!playersTurn || terminated)
            return;
        
        var shadowLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (shadowLocation != null && ableToMove(selected, shadowLocation))
            hexes[shadowLocation.j][shadowLocation.i].select();

        if (selectedDest != null && !selectedDest.equals(shadowLocation))
            hexes[selectedDest.j][selectedDest.i].deselect();

        selectedDest = shadowLocation;*/
    }

    private override function onRelease(e:MouseEvent) 
    {
        /*if (!playersTurn || terminated)
            return;
        
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
            disposeFigure(figures[pressedAt.j][pressedAt.i], pressedAt);*/
    }

    //----------------------------------------------------------------------------------------------------------

    private override function makeMove(from:IntPoint, to:IntPoint, ?morphInto:PieceType) 
    {
        var ply:Ply = new Ply();
        ply.from = from;
        ply.to = to;
        ply.morphInto = morphInto;

        onPlayerMadeMove(ply.toMoveData());
        move(ply);
        stageRef.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }
}