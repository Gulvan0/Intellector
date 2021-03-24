package;

import Rules.Direction;
import Figure.FigureType;
import openfl.Assets;
import openfl.events.Event;
import Figure.FigureColor;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.display.Sprite;

class PlayingField extends Field
{
    public var playersTurn:Bool;
    public var playerColor:FigureColor;

    public function new(playerColourName:String) 
    {
        super();
        var playerIsWhite = playerColourName == 'white';

        playerColor = playerIsWhite? White : Black;
        playersTurn = playerIsWhite;

        figures = Factory.produceFiguresFromDefault(playerIsWhite, this);
        addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }

    //---------------------------------------------------------------------------------------------------------

    private override function onPress(e:MouseEvent) 
    {
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

    private override function makeMove(from:IntPoint, to:IntPoint, ?morphInto:FigureType) 
    {
        var movingFigure = getFigure(from);
        var figMoveOnto = getFigure(to);

        var capture = figMoveOnto != null && figMoveOnto.color != playerColor;
        var mate = capture && figMoveOnto.type == Intellector;

        Networker.move(from.i, from.j, to.i, to.j, morphInto);
        Main.sidebox.makeMove(playerColor, movingFigure.type, to, capture, mate, isCastle(from, to, movingFigure, figMoveOnto), morphInto);
        Main.infobox.makeMove(from.i, from.j, to.i, to.j, morphInto);
        move(from, to, morphInto);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }
}