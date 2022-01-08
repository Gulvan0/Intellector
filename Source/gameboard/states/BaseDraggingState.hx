package gameboard.states;

import openfl.geom.Point;
import struct.IntPoint;

class BaseDraggingState extends BaseState
{
    private var dragStartLocation:IntPoint;

    private function getNeutralState():BaseNeutralState
    {
        throw "To be overriden";
    }

    private function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        throw "To be overriden";
    }

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        if (boardInstance.currentSituation.turnColor != playerColor)
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
            boardInstance.state = getSelectedState(location);
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
            boardInstance.state = getNeutralState();
        }
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.dragStartPosition = dragStartPosition;
    }
}