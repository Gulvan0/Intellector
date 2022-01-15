package gameboard.states;

import net.ServerEvent;
import struct.Ply;

class EnemyMoveNeutralState extends BaseNeutralState
{
    private final playerColor:PieceColor;
    private var premoves:Array<Ply>;

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new EnemyMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, premoves, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.shownSituation.get(location).color == playerColor;
    }

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
            boardInstance.state = new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
        }
        else if (!Rules.possible(premoves[0].from, premoves[0].to, boardInstance.currentSituation.get))
        {
            resetPremoves();
            boardInstance.state = new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
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

    public override function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Rollback(plysToUndo):
                boardInstance.revertPlys(plysToUndo);
                
            case GameEnded(winner_color, reason):
                boardInstance.state = new SpectatorState(boardInstance, cursorLocation);

            case Move(fromI, toI, fromJ, toJ, morphInto):
                var ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto);
                handleOpponentMove(ply);
        }
    }

    public function new(board:GameBoard, playerColor:PieceColor, premoves:Array<Ply> = [], ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.playerColor = playerColor;
        this.premoves = premoves;
    }
}