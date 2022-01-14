package gameboard.states;

import openfl.geom.Point;
import struct.IntPoint;
import Networker.ServerEvent;

class PlayerMoveDraggingState extends BaseDraggingState
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

    private override function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        return new PlayerMoveSelectedState(boardInstance, selectedHexLocation, playerColor, cursorLocation);
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, dragStartPosition, cursorLocation);
        this.playerColor = playerColor;
    }
}