package gameboard.behaviors;

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
            boardInstance.behavior = new PlayerMoveBehavior(boardInstance, playerColor);
        }
        else if (!Rules.possible(premoves[0].from, premoves[0].to, boardInstance.currentSituation.get))
        {
            resetPremoves();
            boardInstance.behavior = new PlayerMoveBehavior(boardInstance, playerColor);
        }
        else
        {
            AssetManager.playPlySound(ply, boardInstance.currentSituation);
            Networker.emitEvent(Move(ply.from.i, ply.to.i, ply.from.j, ply.to.j, ply.morphInto));
            boardInstance.makeMove(ply, true);

            boardInstance.getHex(ply.from).hideLayer(Premove);
            boardInstance.getHex(ply.to).hideLayer(Premove);

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
                boardInstance.revertPlys(plysToUndo);
                
            case GameEnded(winner_color, reason):
                boardInstance.state.abortMove();
                boardInstance.state = new StubState(boardInstance, boardInstance.state.cursorLocation);

            case Move(fromI, toI, fromJ, toJ, morphInto):
                boardInstance.state.abortMove();
                var ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto);
                handleOpponentMove(ply);
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
    
    public function onMoveChosen(ply:Ply):Void
	{
        //No premoveEnabled check because it is impossible to get here from the StubState
        boardInstance.applyMoveTransposition(ply.toReversible());
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