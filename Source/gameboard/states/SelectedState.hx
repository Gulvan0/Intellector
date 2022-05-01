package gameboard.states;

import struct.IntPoint;

class SelectedState extends BasePlayableState
{
    public var selectedDepartureLocation:IntPoint;

    public override function abortMove()
    {
        boardInstance.removeMarkers(selectedDepartureLocation);
        boardInstance.getHex(selectedDepartureLocation).hideLayer(LMB);
        boardInstance.state = new NeutralState();
    }

    public override function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        var pressedDestinationPiece:Null<Piece> = boardInstance.getPiece(location);
        var selectedDeparturePiece:Null<Piece> = boardInstance.getPiece(selectedDepartureLocation);

        boardInstance.removeMarkers(selectedDepartureLocation);
        boardInstance.getHex(selectedDepartureLocation).hideLayer(LMB);

        if (location == null || location.equals(selectedDepartureLocation))
        {
            boardInstance.state = new NeutralState();
        }
        else if (boardInstance.behavior.movePossible(selectedDepartureLocation, location))
        {
            if (cursorLocation != null)
                boardInstance.getHex(cursorLocation).hideLayer(Hover);
            askMoveDetails(selectedDepartureLocation, location, shiftPressed, ctrlPressed);
        }
        else if (pressedDestinationPiece.color == selectedDeparturePiece.color)
        {
            boardInstance.getHex(location).showLayer(LMB);
            if (!boardInstance.behavior.markersDisabled())
                boardInstance.addMarkers(location);
            boardInstance.startPieceDragging(location);
            boardInstance.state = new DraggingState(location);
        }
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.behavior.movePossible(selectedDepartureLocation, location);
    }

    public override function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function new(selectedDepartureLocation:IntPoint)
    {
        super();
        this.selectedDepartureLocation = selectedDepartureLocation;
    }
}