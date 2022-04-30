package gameboard.behaviors;

import gameboard.states.NeutralState;
import utils.exceptions.AlreadyInitializedException;
import struct.IntPoint;
import struct.Ply;
import net.ServerEvent;
import struct.ReversiblePly;
import struct.PieceColor;
import utils.AssetManager;

class AnalysisBehavior implements IBehavior 
{
    private var boardInstance:GameBoard;
    private var colorToMove:PieceColor;

    public function handleNetEvent(event:ServerEvent):Void
	{
        //* Do nothing
	}
    
    public function movePossible(from:IntPoint, to:IntPoint):Bool
	{
        return Rules.possible(from, to, boardInstance.shownSituation.get);
    }
    
    public function allowedToMove(piece:Piece):Bool
	{
        return piece.color == colorToMove;
    }
    
    public function returnToCurrentOnLMB():Bool
	{
        return false;
    }
    
    public function onVoidClick()
	{
        //* Do nothing
    }
    
    public function onMoveChosen(ply:Ply):Void
	{
        var plyStr:String = ply.toNotation(boardInstance.shownSituation);
        var performedBy:PieceColor = boardInstance.shownSituation.turnColor;
        var revPly:ReversiblePly = ply.toReversible(boardInstance.shownSituation);

        AssetManager.playPlySound(ply, boardInstance.shownSituation);

        if (boardInstance.plyHistory.isAtEnd())
        {
            boardInstance.makeMove(ply);
            boardInstance.emit(ContinuationMove(ply, plyStr, performedBy));
        }
        else if (boardInstance.plyHistory.equalsNextMove(revPly))
        {
            boardInstance.next();
            boardInstance.emit(SubsequentMove(plyStr, performedBy));
        }
        else
        {
            boardInstance.revertToShown();
            boardInstance.makeMove(ply);
            boardInstance.emit(BranchingMove(ply, plyStr, performedBy, boardInstance.plyHistory.pointer, boardInstance.plyHistory.length()));
        }

        colorToMove = opposite(colorToMove);
        boardInstance.state = new NeutralState();
    }
    
    public function markersDisabled():Bool
    {
        return false;
    }

    public function hoverDisabled():Bool
    {
        return false;
    }

    public function onAboutToScrollAway()
    {
        //* Do nothing
    }

    public function init(board:GameBoard)
    {
        if (this.boardInstance != null)
            throw new AlreadyInitializedException();
        this.boardInstance = board;
    }
    
    public function new(colorToMove:PieceColor)
    {
        this.colorToMove = colorToMove;
    }
}