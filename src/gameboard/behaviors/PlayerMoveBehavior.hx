package gameboard.behaviors;

import gameboard.components.Piece;
import net.shared.board.Rules;
import net.shared.board.Hex;
import net.shared.board.HexCoords;
import net.shared.board.RawPly;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import assets.Audio;
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
            case Rollback(plysToUndo, _):
                boardInstance.state.exitToNeutral();
                boardInstance.revertPlys(plysToUndo);
                if (plysToUndo % 2 == 1)
                {
                    boardInstance.behavior = new EnemyMoveBehavior(playerColor);
                    if (!Preferences.premoveEnabled.get())
                        boardInstance.state = new StubState();
                }
                
            case GameEnded(_, _, _, _):
                boardInstance.state.exitToNeutral();
                boardInstance.state = new StubState();
            
            default:
        }
	}

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        //* Do nothing
    }

    public function onPremovePreferenceUpdated()
    {
        //* Do nothing
    }
    
    public function movePossible(from:HexCoords, to:HexCoords):Bool
	{
        return Rules.isMovementPossible(from, to, boardInstance.shownSituation.pieces);
    }
    
    public function allowedToMove(piece:Piece):Bool
	{
        return piece.pieceColor == playerColor;
    }
    
    public function returnToCurrentOnLMB():Bool
	{
        return true;
    }
    
    public function onVoidClick()
	{
        //* Do nothing
    }

    public function onAboutToScrollAway()
    {
        //* Do nothing
    }
    
    public function onMoveChosen(ply:RawPly):Void
	{
        Audio.playPlySound(ply.toMaterialized(boardInstance.shownSituation));
        boardInstance.emit(ContinuationMove(ply, ply.toNotation(boardInstance.shownSituation), playerColor));
        Networker.emitEvent(Move(ply));
        boardInstance.makeMove(ply);
        if (Preferences.premoveEnabled.get())
            boardInstance.state = new NeutralState();
        else
            boardInstance.state = new StubState();
        boardInstance.behavior = new EnemyMoveBehavior(playerColor);
    }
    
    public function onHexChosen(coords:HexCoords)
    {
        throw "onHexChosen() called while in PlayerMoveBehavior";
    }
    
    public function markersDisabled():Bool
    {
        return false;
    }

    public function hoverDisabled():Bool
    {
        return !boardInstance.plyHistory.isAtEnd();
    }

    public function init(board:GameBoard)
    {
        if (this.boardInstance != null)
            throw new AlreadyInitializedException();
        this.boardInstance = board;
    }

    public function new(playerColor:PieceColor)
    {
        this.playerColor = playerColor;
    }
}