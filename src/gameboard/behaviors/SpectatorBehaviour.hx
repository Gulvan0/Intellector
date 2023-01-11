package gameboard.behaviors;

import assets.Audio;
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
            case Move(rawPly, _):
                if (Preferences.autoScrollOnMove.get() == Always)
                    boardInstance.applyScrolling(End);

                Audio.playPlySound(rawPly.toMaterialized(boardInstance.currentSituation));
                boardInstance.makeMove(rawPly);
            case Rollback(plysToUndo, _):
                boardInstance.revertPlys(plysToUndo);
            default:
        }
    }
}