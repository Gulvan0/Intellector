package gameboard.states;

import openfl.geom.Point;
import struct.IntPoint;

class DraggingState extends BasePlayableState
{
    private var dragStartLocation:IntPoint;

    public override function abortMove()
    {
        boardInstance.getPiece(dragStartLocation).stopDrag();
        boardInstance.returnPieceToOriginalPosition(dragStartLocation);

        boardInstance.getHex(dragStartLocation).hideLayer(LMB);
        if (cursorLocation != null)
            boardInstance.getHex(cursorLocation).hideLayer(Hover);

        boardInstance.removeMarkers(dragStartLocation);
        boardInstance.state = new NeutralState();
    }

    public override function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public override function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
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
            boardInstance.state = new SelectedState(location);
        }
        else if (location != null && boardInstance.behavior.movePossible(dragStartLocation, location))
        {
            boardInstance.removeMarkers(dragStartLocation);
            askMoveDetails(dragStartLocation, location, shiftPressed, ctrlPressed);
        }
        else
        {
            boardInstance.removeMarkers(dragStartLocation);
            abortMove();
        }
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.behavior.movePossible(dragStartLocation, location);
    }

    public function new(dragStartLocation:IntPoint)
    {
        super();
        this.dragStartLocation = dragStartLocation;
    }
}