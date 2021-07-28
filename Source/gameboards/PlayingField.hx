package gameboards;

import serialization.PlyDeserializer;
import struct.Ply;
import Networker.OngoingBattleData;
import Networker.MoveData;
import struct.PieceType;
import openfl.events.Event;
import struct.PieceColor;
import openfl.events.MouseEvent;
using StringTools;

class PlayingField extends Field
{
    public var playerColor:PieceColor;

    public var onPlayerMadeMove:MoveData->Void;

    public function new(playerColourName:String, ?sourceData:OngoingBattleData) 
    {
        super();
        var playerIsWhite = sourceData != null? sourceData.whiteLogin == Networker.login : playerColourName == 'white';

        playerColor = playerIsWhite? White : Black;
        if (sourceData != null)
            playersTurn = sourceData.position.charAt(0) == "w"? playerIsWhite : !playerIsWhite;
        else
            playersTurn = playerIsWhite;

        hexes = Factory.produceHexes(this, playerIsWhite);
        disposeLetters();
        if (sourceData != null)
        {
            var logLines:Array<String> = sourceData.currentLog.split(";");
            if (logLines.length > 2)
            {
                var lastMoveStr:String = logLines[logLines.length - 2].trim();
                var lastMove:Ply = PlyDeserializer.deserialize(lastMoveStr);
                highlightMove(lastMove.modifiedHexes());
            }

            figures = Factory.produceFiguresFromSerialized(sourceData.position, playerIsWhite, this);
        }
        else
            figures = Factory.produceFiguresFromDefault(playerIsWhite, this);
        addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
        addEventListener(Event.REMOVED_FROM_STAGE, terminate);
    }

    private function terminate(e) 
    {
        stage.removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);
        removeEventListener(Event.REMOVED_FROM_STAGE, terminate);
    }

    //---------------------------------------------------------------------------------------------------------

    private override function onPress(e:MouseEvent) 
    {
        rmbSelectionBackToNormal();
        if (!playersTurn || terminated)
            return;

        var pressLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        
        if (pressLocation != null && plyPointer < plyHistory.length)
            endPly();

        if (selected != null)
            destinationPress(pressLocation);
        else
            departurePress(pressLocation, c -> (c == playerColor));
    }

    private override function onMove(e:MouseEvent) 
    {
        if (!playersTurn || terminated)
            return;
        
        var shadowLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (shadowLocation != null && ableToMove(selected, shadowLocation))
            hexes[shadowLocation.j][shadowLocation.i].select();

        if (selectedDest != null && !selectedDest.equals(shadowLocation))
            hexes[selectedDest.j][selectedDest.i].deselect();

        selectedDest = shadowLocation;
    }

    private override function onRelease(e:MouseEvent) 
    {
        if (!playersTurn || terminated)
            return;
        
        stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);

        var pressedAt = new IntPoint(selected.i, selected.j);
        var releasedAt = posToIndexes(e.stageX - this.x, e.stageY - this.y);
        figures[pressedAt.j][pressedAt.i].stopDrag();
        if (releasedAt != null && ableToMove(pressedAt, releasedAt) && !releasedAt.equals(pressedAt))
        {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
            selectionBackToNormal();
            attemptMove(pressedAt, releasedAt);
        }
        else
            disposeFigure(figures[pressedAt.j][pressedAt.i], pressedAt);
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
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    private override function isOrientationNormal(?movingFigure:PieceColor):Bool
    {   
        if (movingFigure == null)
            return playerColor == White;
        else
            return playerColor == movingFigure;
    }
}