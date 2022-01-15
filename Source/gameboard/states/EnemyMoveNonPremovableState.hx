package gameboard.states;

import struct.Ply;
import net.ServerEvent;

class EnemyMoveNonPremovableState extends BaseState
{
    private final playerColor:PieceColor;

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return false;
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        //* Do nothing
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
                AssetManager.playPlySound(ply, boardInstance.currentSituation);
                boardInstance.makeMove(ply);
                boardInstance.state = new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
        }
    }

    public function new(board:GameBoard, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.playerColor = playerColor;
    }
}