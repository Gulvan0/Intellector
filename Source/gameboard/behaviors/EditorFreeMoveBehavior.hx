package gameboard.behaviors;

import net.ServerEvent;
import struct.ReversiblePly;
import struct.PieceColor;
import utils.AssetManager;
import gameboard.states.DraggingState;
import gameboard.states.NeutralState;

class EditorFreeMoveBehavior implements IBehavior 
{
    private var boardInstance:GameBoard;

    public function handleNetEvent(event:ServerEvent):Void
	{
        //* Do nothing
	}
    
    public function movePossible(from:IntPoint, to:IntPoint):Bool
	{
        return true;
    }
    
    public function allowedToMove(piece:Piece):Bool
	{
        return true;
    }
    
    public function returnToCurrentOnLMB():Bool
	{
        return false;
    }
    
    public function onMoveChosen(ply:Ply):Void
	{
        boardInstance.teleportPiece(ply.from, ply.to);
    }
    
    public function markersDisabled():Bool
    {
        return true;
    }

    public function hoverDisabled():Bool
    {
        return true;
    }
    
    public function new(board:GameBoard)
    {
        this.boardInstance = board;
    }
}