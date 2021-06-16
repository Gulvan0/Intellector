package gameboards;

import Networker.OngoingBattleData;
import Networker.MoveData;
import struct.PieceType;
import openfl.events.Event;
import struct.PieceColor;
import openfl.events.MouseEvent;

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

        hexes = Factory.produceHexes(playerIsWhite, this);
        disposeLetters();
        if (sourceData != null)
            figures = Factory.produceFiguresFromSerialized(sourceData.position, playerColor, this);
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
        removeEventListener(Event.REMOVED_FROM_STAGE, terminate);
    }

    //---------------------------------------------------------------------------------------------------------

    private override function onPress(e:MouseEvent) 
    {
        rmbSelectionBackToNormal();
        if (!playersTurn)
            return;

        var pressLocation = posToIndexes(e.stageX - this.x, e.stageY - this.y);

        if (selected != null)
            destinationPress(pressLocation);
        else
            departurePress(pressLocation, c -> (c == playerColor));
    }

    private override function onMove(e:MouseEvent) 
    {
        if (!playersTurn)
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
        if (!playersTurn)
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
        onPlayerMadeMove({issuer_login: Networker.login, fromI: from.i, toI: to.i, fromJ: from.j, toJ: to.j, morphInto: morphInto == null? null : morphInto.getName()});
        move(from, to, morphInto);
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