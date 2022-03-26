package gameboard.behaviors;

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
    }

    private function handleOpponentMove(ply:Ply)
    {
        AssetManager.playPlySound(ply, boardInstance.currentSituation);
        boardInstance.makeMove(ply);

        if (Lambda.empty(premoves))
        {
            boardInstance.state.abortMove();
            boardInstance.state = new NeutralState(boardInstance, boardInstance.state.cursorLocation);
            boardInstance.behavior = new PlayerMoveBehavior(boardInstance, playerColor);
        }
        else if (!Rules.possible(premoves[0].from, premoves[0].to, boardInstance.currentSituation.get))
        {
            resetPremoves();
            boardInstance.state.abortMove();
            boardInstance.state = new NeutralState(boardInstance, boardInstance.state.cursorLocation);
            boardInstance.behavior = new PlayerMoveBehavior(boardInstance, playerColor);
        }
        else
        {
            var premove:Ply = premoves[0];
            AssetManager.playPlySound(premove, boardInstance.currentSituation);
            boardInstance.emit(ContinuationMove(premove, premove.toNotation(boardInstance.currentSituation), playerColor));
            Networker.emitEvent(Move(premove.from.i, premove.to.i, premove.from.j, premove.to.j, premove.morphInto == null? null : premove.morphInto.getName()));
            boardInstance.makeMove(premove, true);

            boardInstance.getHex(premove.from).hideLayer(Premove);
            boardInstance.getHex(premove.to).hideLayer(Premove);

            premoves.splice(0, 1);

            for (premovePly in premoves)
            {
                //We reapply layers to the remaining premoves because they can also affect the same hexes that the just activated premove affects
                boardInstance.getHex(premovePly.from).showLayer(Premove);
                boardInstance.getHex(premovePly.to).showLayer(Premove);
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
    
    public function onMoveChosen(ply:Ply):Void
	{
        //No premoveEnabled check because it is impossible to get here from the StubState
        boardInstance.applyMoveTransposition(ply.toReversible(boardInstance.shownSituation));
        boardInstance.getHex(ply.from).showLayer(Premove);
        boardInstance.getHex(ply.to).showLayer(Premove);
        premoves.push(ply);
        boardInstance.state = new NeutralState(boardInstance, boardInstance.state.cursorLocation);
    }
    
    public function markersDisabled():Bool
    {
        return false;
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