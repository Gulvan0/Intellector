package gameboard.states;

import Networker.IncomingEvent;

class EnemyMoveState extends BaseState
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

    public override function handleNetEvent(event:IncomingEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.playerColor = playerColor;
    }
}