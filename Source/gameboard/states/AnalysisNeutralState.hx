package gameboard.states;

import struct.PieceColor;
import net.ServerEvent;

class AnalysisNeutralState extends BaseNeutralState
{
    private var colorToMove:PieceColor;

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new AnalysisDraggingState(boardInstance, dragDepartureLocation, colorToMove, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.shownSituation.get(location).color == colorToMove;
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, colorToMove:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.colorToMove = colorToMove;
    }
}