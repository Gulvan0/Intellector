package gameboard.states;

import struct.IntPoint;
import Networker.IncomingEvent;

class AnalysisSelectedState extends BaseSelectedState
{
    private var colorToMove:PieceColor;

    private override function getNeutralState():BaseNeutralState
    {
        return new AnalysisNeutralState(boardInstance, colorToMove, cursorLocation);
    }

    private override function onMoveChosen(ply:Ply)
    {
        //TODO: Fill
    }

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        //TODO: Change | return new PlayerMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, cursorLocation);
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