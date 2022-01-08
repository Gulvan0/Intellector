package gameboard.states;

import Networker.IncomingEvent;
import openfl.geom.Point;
import struct.IntPoint;

class AnalysisDraggingState extends BaseDraggingState
{
    private var colorToMove:PieceColor;

    private override function getNeutralState():BaseNeutralState
    {
        //TODO: Change | return new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
    }

    private override function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        //TODO: Change | return new PlayerMoveSelectedState(boardInstance, selectedHexLocation, playerColor, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return Rules.possible(dragStartLocation, location, boardInstance.shownSituation.get);
    }

    public override function handleNetEvent(event:IncomingEvent)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, colorToMove:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, dragStartPosition, cursorLocation);
        this.colorToMove = colorToMove;
    }
}