package gameboard.states;

import net.ServerEvent;
import struct.Hex;
import openfl.geom.Point;
import struct.IntPoint;

class AnalysisDraggingState extends BaseDraggingState
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

    private override function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        return new AnalysisSelectedState(boardInstance, selectedHexLocation, colorToMove, cursorLocation);
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, colorToMove:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, dragStartPosition, cursorLocation);
        this.colorToMove = colorToMove;
    }
}