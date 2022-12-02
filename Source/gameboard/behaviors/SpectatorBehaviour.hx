package gameboard.behaviors;

import utils.AssetManager;
import net.shared.ServerEvent;
import utils.exceptions.AlreadyInitializedException;

class SpectatorBehavior extends StubBehavior
{
    private var boardInstance:GameBoard;

    public override function init(board:GameBoard)
    {
        if (this.boardInstance != null)
            throw new AlreadyInitializedException();
        this.boardInstance = board;
    }

    public override function handleNetEvent(event:ServerEvent) 
    {
        switch event 
        {
            case Move(fromI, toI, fromJ, toJ, morphInto, _):
                if (Preferences.autoScrollOnMove.get() == Always)
                    boardInstance.applyScrolling(End);

                var ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto);
                boardInstance.makeMove(ply);
                AssetManager.playPlySound(ply, boardInstance.currentSituation);
            case Rollback(plysToUndo, _):
                boardInstance.revertPlys(plysToUndo);
            default:
        }
    }
}