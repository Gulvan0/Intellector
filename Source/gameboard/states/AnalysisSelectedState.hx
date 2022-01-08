package gameboard.states;

import struct.IntPoint;
import Networker.IncomingEvent;

class AnalysisSelectedState extends BaseSelectedState
{
    private var colorToMove:PieceColor;

    private override function getStateAfterSuccessfulMove():BaseState
    {
        //TODO: Fill
    }

    private override function getStateAfterInvalidMove():BaseNeutralState
    {
        //TODO: Change | return new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
    }

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        //TODO: Change | return new PlayerMoveDraggingState(boardInstance, location, playerColor, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return Rules.possible(dragStartLocation, location, boardInstance.shownSituation.get);
    }

    public override function handleNetEvent(event:IncomingEvent)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, selectedDepartureLocation:IntPoint, colorToMove:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, selectedDepartureLocation, cursorLocation);
        this.colorToMove = colorToMove;
    }
}