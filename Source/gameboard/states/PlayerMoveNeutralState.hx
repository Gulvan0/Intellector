package gameboard.states;

import net.ServerEvent;

class PlayerMoveNeutralState extends BaseNeutralState
{
    private final playerColor:PieceColor;

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new PlayerMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.shownSituation.get(location).color == playerColor;
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Rollback(plysToUndo):
                boardInstance.revertPlys(plysToUndo);
                
            case GameEnded(winner_color, reason):
                boardInstance.state = new SpectatorState(boardInstance, cursorLocation);
        }
    }

    public function new(board:GameBoard, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.playerColor = playerColor;
    }
}