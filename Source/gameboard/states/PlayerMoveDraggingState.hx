package gameboard.states;

import openfl.geom.Point;
import struct.IntPoint;

class PlayerMoveDraggingState extends BaseState
{
    private var dragStartLocation:IntPoint;

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return Rules.possible(dragStartLocation, location, boardInstance.shownSituation.get);
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        if (boardInstance.currentSituation.turnColor != boardInstance.playerColor)
            return;

        var draggedPiece:Piece = boardInstance.getPiece(dragStartLocation);
        draggedPiece.stopDrag();
        boardInstance.getHex(dragStartLocation).hideLayer(LMB);
        if (cursorLocation != null)
            boardInstance.getHex(cursorLocation).hideLayer(Hover);

        if (location != null && location.equals(dragStartLocation))
        {
            var newPosition:Point = boardInstance.hexCoords(location);
            draggedPiece.x = newPosition.x;
            draggedPiece.y = newPosition.y;
            boardInstance.getHex(location).showLayer(LMB);
            boardInstance.state = new PlayerMoveSelectedState(boardInstance, location, cursorLocation);
        }
        else if (location != null && Rules.possible(dragStartLocation, location, boardInstance.shownSituation.get))
        {
            boardInstance.removeMarkers(dragStartLocation);
            //TODO: initiateMove(pressLoc, releaseLoc);
            //TODO: To ??? (enemymove?)
        }
        else
        {
            boardInstance.removeMarkers(dragStartLocation);
            var originalPosition:Point = boardInstance.hexCoords(dragStartLocation);
            draggedPiece.x = originalPosition.x;
            draggedPiece.y = originalPosition.y;
            boardInstance.state = new PlayerMoveNeutralState(boardInstance, cursorLocation);
        }
    }

    public override function handleNetEvent(event:NetEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.dragStartPosition = dragStartPosition;
    }
}