package gameboard.states;

import struct.IntPoint;
import Networker.ServerEvent;

class PlayerMoveSelectedState extends BaseSelectedState
{
    private final playerColor:PieceColor;

    private override function getNeutralState():BaseNeutralState
    {
        return new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
    }

    private override function onMoveChosen(ply:Ply)
    {
        //TODO: Fill
    }

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new PlayerMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, cursorLocation);
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, selectedDepartureLocation:IntPoint, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, selectedDepartureLocation, cursorLocation);
        this.playerColor = playerColor;
    }
}