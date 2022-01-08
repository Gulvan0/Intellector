package gameboard.states;

import struct.PieceColor;
import Networker.IncomingEvent;

class AnalysisNeutralState extends BaseNeutralState
{
    private var colorToMove:PieceColor;

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        //TODO: Change to AnalysisDragging | return new PlayerMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.shownSituation.get(location).color == colorToMove;
    }

    public override function handleNetEvent(event:IncomingEvent)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, colorToMove:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.colorToMove = colorToMove;
    }
}