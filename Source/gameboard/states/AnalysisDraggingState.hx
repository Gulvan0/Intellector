package gameboard.states;

import struct.Ply;
import struct.ReversiblePly;
import struct.PieceColor;
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
        var plyStr:String = ply.toNotation(boardInstance.shownSituation);
        var performedBy:PieceColor = boardInstance.shownSituation.turnColor;
        var revPly:ReversiblePly = ply.toReversible(boardInstance.shownSituation);

        AssetManager.playPlySound(ply, boardInstance.shownSituation);

        if (boardInstance.plyHistory.isAtEnd())
        {
            boardInstance.makeMove(ply);
            boardInstance.emit(ContinuationMove(plyStr, performedBy));
        }
        else if (boardInstance.plyHistory.equalsNextMove(revPly))
        {
            boardInstance.highlightMove(revPly.affectedCoords());
            boardInstance.emit(SubsequentMove(plyStr, performedBy));
        }
        else
        {
            boardInstance.revertToShown();
            boardInstance.makeMove(ply);
            boardInstance.emit(BranchingMove(plyStr, performedBy));
        }

        boardInstance.state = getNeutralState();
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