package gameboard.behaviors;

import net.ServerEvent;
import struct.ReversiblePly;
import struct.PieceColor;
import utils.AssetManager;
import gameboard.states.StubState;
import gameboard.states.NeutralState;

class PlayerMoveBehavior implements IBehavior 
{
    private var boardInstance:GameBoard;
    private var playerColor:PieceColor;

    public function handleNetEvent(event:ServerEvent):Void
	{
        switch event 
        {
            case Rollback(plysToUndo):
                boardInstance.state.abortMove();
                boardInstance.revertPlys(plysToUndo);
                
            case GameEnded(winner_color, reason):
                boardInstance.state.abortMove();
                boardInstance.state = new StubState(boardInstance, boardInstance.state.cursorLocation);
        }
	}
    
    public function movePossible(from:IntPoint, to:IntPoint):Bool
	{
        return Rules.possible(from, to, boardInstance.currentSituation.get);
    }
    
    public function allowedToMove(piece:Piece):Bool
	{
        return piece.color == playerColor;
    }
    
    public function returnToCurrentOnLMB():Bool
	{
        return true;
    }
    
    public function onMoveChosen(ply:Ply):Void
	{
        AssetManager.playPlySound(ply, boardInstance.shownSituation);
        Networker.emitEvent(Move(ply.from.i, ply.to.i, ply.from.j, ply.to.j, ply.morphInto));
        boardInstance.makeMove(ply);
        if (Preferences.instance.premoveEnabled)
            boardInstance.state = new NeutralState(boardInstance, boardInstance.state.cursorLocation);
        else
            boardInstance.state = new StubState(boardInstance, boardInstance.state.cursorLocation);
    }
    
    public function markersDisabled():Bool
    {
        return false;
    }

    public function hoverDisabled():Bool
    {
        return false;
    }
    
    public function new(board:GameBoard, playerColor:PieceColor)
    {
        this.boardInstance = board;
        this.playerColor = playerColor;
    }
}