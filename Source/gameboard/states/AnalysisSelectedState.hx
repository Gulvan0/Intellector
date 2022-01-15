package gameboard.states;

import struct.IntPoint;
import struct.Hex;
import net.ServerEvent;

class AnalysisSelectedState extends BaseSelectedState
{
    private var colorToMove:PieceColor;

    private override function getNeutralState():BaseNeutralState
    {
        return new AnalysisNeutralState(boardInstance, colorToMove, cursorLocation);
    }

    public override function movePossible(from:IntPoint, to:IntPoint):Bool
    {
        return Rules.possible(from, to, boardInstance.shownSituation.get);
    }

    private override function onMoveChosen(ply:Ply)
    {
        AssetManager.playPlySound(ply, boardInstance.shownSituation);
        boardInstance.makeMove(ply);
        boardInstance.state = new AnalysisNeutralState(boardInstance, colorToMove, cursorLocation);
    }

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new AnalysisDraggingState(boardInstance, dragDepartureLocation, colorToMove, cursorLocation);
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, selectedDepartureLocation:IntPoint, colorToMove:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, selectedDepartureLocation, cursorLocation);
        this.colorToMove = colorToMove;
    }
}