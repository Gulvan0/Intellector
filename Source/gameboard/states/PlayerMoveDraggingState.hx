package gameboard.states;

import openfl.geom.Point;
import struct.IntPoint;
import Networker.IncomingEvent;

class PlayerMoveDraggingState extends BaseDraggingState
{
    private final playerColor:PieceColor;

    private override function getNeutralState():BaseNeutralState
    {
        return new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
    }

    private override function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        return new PlayerMoveSelectedState(boardInstance, selectedHexLocation, playerColor, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return Rules.possible(dragStartLocation, location, boardInstance.shownSituation.get);
    }

    public override function handleNetEvent(event:IncomingEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, dragStartPosition, cursorLocation);
        this.playerColor = playerColor;
    }
}