package gameboard.behaviors;

import net.shared.board.Rules;
import net.shared.board.Hex;
import net.shared.board.HexCoords;
import net.shared.board.RawPly;
import gfx.Dialogs;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import gameboard.states.StubState;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import utils.AssetManager;
import gameboard.states.DraggingState;
import gameboard.states.NeutralState;

class EnemyMoveBehavior implements IBehavior 
{
    private var boardInstance:GameBoard;
    private var playerColor:PieceColor;
    private var premoves:Array<RawPly>;

    private function resetPremoves()
    {
        for (premovePly in premoves)
        {
            boardInstance.getHex(premovePly.from).hideLayer(Premove);
            boardInstance.getHex(premovePly.to).hideLayer(Premove);
        }

        boardInstance.setShownSituation(boardInstance.currentSituation); //Resetting the shownSituation    
        premoves = [];
    }

    private function handleOpponentMove(ply:RawPly)
    {
        if (Preferences.autoScrollOnMove.get() != Never || !Lambda.empty(premoves))
            boardInstance.applyScrolling(End);

        if (Lambda.empty(premoves))
        {
            AssetManager.playPlySound(ply.toMaterialized(boardInstance.currentSituation));
            boardInstance.makeMove(ply);

            boardInstance.behavior = new PlayerMoveBehavior(playerColor);
            boardInstance.state = new NeutralState();
        }
        else
        {
            var activatedPremove:RawPly = premoves[0];
            var followingPremoves:Array<RawPly> = premoves.slice(1);
    
            resetPremoves();
    
            AssetManager.playPlySound(ply.toMaterialized(boardInstance.currentSituation));
            boardInstance.makeMove(ply);

            var premoveDeparture:Hex = boardInstance.currentSituation.get(activatedPremove.from);

            if (premoveDeparture.type() != Progressor && premoveDeparture.type() != Intellector && activatedPremove.morphInto != null)
                activatedPremove.morphInto = boardInstance.currentSituation.get(activatedPremove.to).type();
    
            if (premoveDeparture.color() != playerColor || !Rules.isPossible(activatedPremove, boardInstance.currentSituation))
            {
                boardInstance.behavior = new PlayerMoveBehavior(playerColor);
                boardInstance.state = new NeutralState();
            }
            else
            {
                AssetManager.playPlySound(activatedPremove.toMaterialized(boardInstance.currentSituation));
                boardInstance.emit(ContinuationMove(activatedPremove, activatedPremove.toNotation(boardInstance.currentSituation), playerColor));
                boardInstance.makeMove(activatedPremove);
    
                for (premove in followingPremoves)
                    displayPlannedPremove(premove);
                premoves = followingPremoves;
    
                Networker.emitEvent(Move(activatedPremove));
                
                boardInstance.state = new NeutralState();
            }
        }
    }

    public function handleNetEvent(event:ServerEvent):Void
	{
        switch event 
        {
            case InvalidMove:
                Dialogs.alert(INVALID_MOVE_DIALOG_MESSAGE, INVALID_MOVE_DIALOG_TITLE);

            case Rollback(plysToUndo, _):
                boardInstance.state.exitToNeutral();
                resetPremoves();
                boardInstance.revertPlys(plysToUndo);
                if (plysToUndo % 2 == 1)
                    boardInstance.behavior = new PlayerMoveBehavior(playerColor);

                if (!Preferences.premoveEnabled.get() && plysToUndo % 2 == 0)
                    boardInstance.state = new StubState();
                
            case GameEnded(_, _, _, _):
                boardInstance.state.exitToNeutral();
                resetPremoves();
                boardInstance.state = new StubState();

            case Move(ply, _):
                boardInstance.state.exitToNeutral();
                boardInstance.state = new StubState();
                handleOpponentMove(ply);

            default:
        }
    }

    public function onPremovePreferenceUpdated()
    {
        if (Preferences.premoveEnabled.get())
            boardInstance.state = new NeutralState();
        else
        {
            resetPremoves();
            boardInstance.state = new StubState();
        }
    }

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        //* Do nothing
    }
    
    public function movePossible(from:HexCoords, to:HexCoords):Bool
	{
        return Rules.isPremovePossible(from, to, boardInstance.shownSituation.pieces);
    }
    
    public function allowedToMove(piece:Piece):Bool
	{
        return piece.color == playerColor;
    }
    
    public function returnToCurrentOnLMB():Bool
	{
        return true;
    }
    
    public function onVoidClick()
	{
        resetPremoves();
    }

    public function onAboutToScrollAway()
    {
        resetPremoves();
    }
    
    public function onMoveChosen(ply:RawPly):Void
	{
        //No premoveEnabled check because it is impossible to get here from the StubState
        displayPlannedPremove(ply);
        premoves.push(ply);
        boardInstance.state = new NeutralState();
    }
    
    public function onHexChosen(coords:HexCoords)
    {
        throw "onHexChosen() called while in EnemyMoveBehavior";
    }

    private function displayPlannedPremove(ply:RawPly)
    {
        boardInstance.applyPremoveTransposition(ply);
        boardInstance.getHex(ply.from).showLayer(Premove);
        boardInstance.getHex(ply.to).showLayer(Premove);
    }
    
    public function markersDisabled():Bool
    {
        return true;
    }

    public function hoverDisabled():Bool
    {
        return !Preferences.premoveEnabled.get() || !boardInstance.plyHistory.isAtEnd();
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
        this.premoves = [];
    }
}