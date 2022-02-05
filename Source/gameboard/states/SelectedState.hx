package gameboard.states;

import struct.IntPoint;

class SelectedState extends BasePlayableState
{
    public var selectedDepartureLocation:IntPoint;

    private override function abortMove()
    {
        boardInstance.removeMarkers(selectedDepartureLocation);
        boardInstance.getHex(selectedDepartureLocation).hideLayer(LMB);
        boardInstance.state = new NeutralState(boardInstance, cursorLocation);
    }

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        var pressedDestinationPiece:Null<Piece> = boardInstance.getPiece(location);

        boardInstance.removeMarkers(selectedDepartureLocation);
        boardInstance.getHex(selectedDepartureLocation).hideLayer(LMB);

        var selectedDeparturePiece:Null<Piece> = boardInstance.getPiece(selectedDepartureLocation);
        if (location == null || location.equals(selectedDepartureLocation))
        {
            state = new NeutralState(boardInstance, cursorLocation);
        }
        else if (Rules.possible(selectedDepartureLocation, location, getHex))
        {
            if (cursorLocation != null)
                boardInstance.getHex(cursorLocation).hideLayer(Hover);
            askMoveDetails(dragStartLocation, location);
        }
        else if (alreadySelectedFigure.color == pressedFigure.color)
        {
            boardInstance.getHex(location).showLayer(LMB);
            if (!boardInstance.behavior.markersDisabled())
                boardInstance.addMarkers(location);
            boardInstance.startPieceDragging(location);
            boardInstance.state = new DraggingState(boardInstance, location, cursorLocation);
        }
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.behavior.movePossible(selectedDepartureLocation, location);
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, selectedDepartureLocation:IntPoint, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.selectedDepartureLocation = selectedDepartureLocation;
    }
}