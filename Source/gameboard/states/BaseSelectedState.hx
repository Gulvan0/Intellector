package gameboard.states;

import struct.IntPoint;

class BaseSelectedState extends BaseState
{
    public var selectedDepartureLocation:IntPoint;

    private function getStateAfterSuccessfulMove():BaseState
    {
        throw "To be overriden";
    }

    private function getStateAfterInvalidMove():BaseNeutralState
    {
        throw "To be overriden";
    }

    private function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        throw "To be overriden";
    }

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        var pressedDestinationPiece:Null<Piece> = boardInstance.getPiece(location);

        removeMarkers(selectedDepartureLocation);
        boardInstance.getHex(selectedDepartureLocation).hideLayer(LMB);

        var selectedDeparturePiece:Null<Piece> = boardInstance.getFigure(selectedDepartureLocation);
        if (location == null || location.equals(selectedDepartureLocation))
            return;
        else if (Rules.possible(selectedDepartureLocation, location, getHex))
        {
            if (cursorLocation != null)
                boardInstance.getHex(cursorLocation).hideLayer(Hover);
            //TODO: initiateMove(selectedDepartureLocation, location);
            //TODO: change state
        }
        else if (alreadySelectedFigure.color == pressedFigure.color)
        {
            boardInstance.getHex(location).showLayer(LMB);
            boardInstance.addMarkers(location);
            boardInstance.startPieceDragging(location);
            boardInstance.state = getDraggingState(location);
        }
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