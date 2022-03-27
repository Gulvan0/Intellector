package gameboard.behaviors;

import struct.Hex;
import struct.Ply;
import struct.IntPoint;
import gameboard.states.StubState;
import net.ServerEvent;
import struct.ReversiblePly;
import struct.PieceColor;
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

        boardInstance.setSituation(boardInstance.currentSituation); //Resetting the shownSituation    
        premoves = [];
    }

    private function handleOpponentMove(ply:Ply)
    {
        if (Lambda.empty(premoves))
        {
            AssetManager.playPlySound(ply, boardInstance.currentSituation);
            boardInstance.makeMove(ply);

            boardInstance.state.abortMove();
            boardInstance.behavior = new PlayerMoveBehavior(boardInstance, playerColor);
        }
        else
        {
            var activatedPremove:Ply = premoves[0];
            var followingPremoves:Array<Ply> = premoves.slice(1);
    
            resetPremoves();
    
            AssetManager.playPlySound(ply, boardInstance.currentSituation);
            boardInstance.makeMove(ply);

            var premoveDeparture:Hex = boardInstance.currentSituation.get(activatedPremove.from);
    
            if (premoveDeparture.color != playerColor || !Rules.possible(activatedPremove.from, activatedPremove.to, boardInstance.currentSituation.get))
            {
                boardInstance.state.abortMove();
                boardInstance.behavior = new PlayerMoveBehavior(boardInstance, playerColor);
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
    
                Networker.emitEvent(Move(activatedPremove.from.i, activatedPremove.to.i, activatedPremove.from.j, activatedPremove.to.j, activatedPremove.morphInto == null? null : activatedPremove.morphInto.getName()));
            }
        }
    }

    public function handleNetEvent(event:ServerEvent):Void
	{
        switch event 
        {
            case Rollback(plysToUndo):
                boardInstance.state.abortMove();
                resetPremoves();
                boardInstance.revertPlys(plysToUndo);
                if (plysToUndo % 2 == 1)
                    boardInstance.behavior = new PlayerMoveBehavior(boardInstance, playerColor);
                
            case GameEnded(winner_color, reason):
                boardInstance.state.abortMove();
                resetPremoves();
                boardInstance.state = new StubState(boardInstance, boardInstance.state.cursorLocation);

            case Move(fromI, toI, fromJ, toJ, morphInto):
                boardInstance.state.abortMove();
                var ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto == null? null : PieceType.createByName(morphInto));
                handleOpponentMove(ply);

            default:
        }
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
        boardInstance.state = new NeutralState(boardInstance, boardInstance.state.cursorLocation);
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
        return !Preferences.instance.premoveEnabled;
    }
    
    public function new(board:GameBoard, playerColor:PieceColor)
    {
        this.boardInstance = board;
        this.playerColor = playerColor;
        this.premoves = [];
    }
}