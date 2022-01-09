package gameboard.states;

import struct.IntPoint;

class BaseSelectedState extends BasePlayableState
{
    public var selectedDepartureLocation:IntPoint;

    private function getNeutralState():BaseNeutralState
    {
        throw "To be overriden";
    }

    private function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        throw "To be overriden";
    }

    private override function onMoveCanceled(departureCoords:IntPoint) 
    {
        boardInstance.state = getNeutralState();
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return Rules.possible(selectedDepartureLocation, location, boardInstance.shownSituation.get);
    }

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        var pressedDestinationPiece:Null<Piece> = boardInstance.getPiece(location);

        removeMarkers(selectedDepartureLocation);
        boardInstance.getHex(selectedDepartureLocation).hideLayer(LMB);

        var selectedDeparturePiece:Null<Piece> = boardInstance.getPiece(selectedDepartureLocation);
        if (location == null || location.equals(selectedDepartureLocation))
        {
            state = getNeutralState();
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