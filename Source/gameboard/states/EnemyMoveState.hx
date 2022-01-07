package gameboard.states;

class EnemyMoveState extends BaseState
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

    public override function handleNetEvent(event:NetEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}