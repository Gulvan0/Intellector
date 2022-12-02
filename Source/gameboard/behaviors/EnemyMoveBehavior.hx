package gameboard.behaviors;

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
    private var premoves:Array<Ply>;

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

    private function handleOpponentMove(ply:Ply)
    {
        if (Preferences.autoScrollOnMove.get() != Never || !Lambda.empty(premoves))
            boardInstance.applyScrolling(End);

        if (Lambda.empty(premoves))
        {
            boardInstance.makeMove(ply);
            AssetManager.playPlySound(ply, boardInstance.currentSituation);

            boardInstance.state.exitToNeutral();
            boardInstance.behavior = new PlayerMoveBehavior(playerColor);
        }
        else
        {
            var activatedPremove:Ply = premoves[0];
            var followingPremoves:Array<Ply> = premoves.slice(1);
    
            resetPremoves();
    
            boardInstance.makeMove(ply);
            AssetManager.playPlySound(ply, boardInstance.currentSituation);

            var premoveDeparture:Hex = boardInstance.currentSituation.get(activatedPremove.from);
    
            if (premoveDeparture.color != playerColor || !Rules.possible(activatedPremove.from, activatedPremove.to, boardInstance.currentSituation.get))
            {
                boardInstance.state.exitToNeutral();
                boardInstance.behavior = new PlayerMoveBehavior(playerColor);
            }
            else
            {
                if (premoveDeparture.type != Progressor && premoveDeparture.type != Intellector && activatedPremove.morphInto != null)
                    activatedPremove.morphInto = boardInstance.currentSituation.get(activatedPremove.to).type;

                AssetManager.playPlySound(activatedPremove, boardInstance.currentSituation);
                boardInstance.emit(ContinuationMove(activatedPremove, activatedPremove.toNotation(boardInstance.currentSituation), playerColor));
                boardInstance.makeMove(activatedPremove);
    
                for (premove in followingPremoves)
                    displayPlannedPremove(premove);
                premoves = followingPremoves;
    
                Networker.emitEvent(Move(activatedPremove.from.i, activatedPremove.to.i, activatedPremove.from.j, activatedPremove.to.j, activatedPremove.morphInto));
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

            case Move(fromI, toI, fromJ, toJ, morphInto, _):
                boardInstance.state.exitToNeutral();
                if (!Preferences.premoveEnabled.get())
                    boardInstance.state = new StubState();
                var ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto);
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
    
    public function movePossible(from:IntPoint, to:IntPoint):Bool
	{
        return Rules.premovePossible(from, to, boardInstance.shownSituation.get(from));
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
    
    public function onMoveChosen(ply:Ply):Void
	{
        //No premoveEnabled check because it is impossible to get here from the StubState
        displayPlannedPremove(ply);
        premoves.push(ply);
        boardInstance.state = new NeutralState();
    }
    
    public function onHexChosen(coords:IntPoint)
    {
        throw "onHexChosen() called while in EnemyMoveBehavior";
    }

    private function displayPlannedPremove(ply:Ply)
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