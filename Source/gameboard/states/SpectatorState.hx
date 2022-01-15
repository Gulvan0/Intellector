package gameboard.states;

import net.ServerEvent;

class SpectatorState extends BaseState
{
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

            case Move(fromI, toI, fromJ, toJ, morphInto):
                var ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto);
                AssetManager.playPlySound(ply, boardInstance.currentSituation);
                boardInstance.makeMove(ply);
        }
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}