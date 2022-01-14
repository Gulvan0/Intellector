package gameboard.states;

import Networker.ServerEvent;

class PlayerMoveNeutralState extends BaseNeutralState
{
    private final playerColor:PieceColor;

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new PlayerMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.shownSituation.get(location).color == playerColor;
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.playerColor = playerColor;
    }
}