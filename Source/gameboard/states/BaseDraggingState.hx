package gameboard.states;

import openfl.geom.Point;
import struct.IntPoint;

class BaseDraggingState extends BasePlayableState
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

    private override function onMoveCanceled(departureCoords:IntPoint) 
    {
        boardInstance.returnPieceToOriginalPosition(departureCoords);
        boardInstance.state = getNeutralState();
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
            askMoveDetails(dragStartLocation, location);
        }
        else
        {
            boardInstance.removeMarkers(dragStartLocation);
            onMoveCanceled();
        }
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.dragStartPosition = dragStartPosition;
    }
}