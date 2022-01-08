package gameboard.states;

import struct.IntPoint;
import Networker.IncomingEvent;

class PlayerMoveSelectedState extends BaseSelectedState
{
    private final playerColor:PieceColor;

    private override function getStateAfterSuccessfulMove():BaseState
    {
        //TODO: Fill
    }

    private override function getStateAfterInvalidMove():BaseNeutralState
    {
        return new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
    }

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new PlayerMoveDraggingState(boardInstance, location, playerColor, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return Rules.possible(dragStartLocation, location, boardInstance.shownSituation.get);
    }

    public override function handleNetEvent(event:IncomingEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, selectedDepartureLocation:IntPoint, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, selectedDepartureLocation, cursorLocation);
        this.playerColor = playerColor;
    }
}