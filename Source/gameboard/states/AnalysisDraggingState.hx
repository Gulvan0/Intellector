package gameboard.states;

import Networker.ServerEvent;
import openfl.geom.Point;
import struct.IntPoint;

class AnalysisDraggingState extends BaseDraggingState
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

    private override function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        //TODO: Change | return new PlayerMoveSelectedState(boardInstance, selectedHexLocation, playerColor, cursorLocation);
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