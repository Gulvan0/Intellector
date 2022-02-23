package gameboard.states;

import struct.IntPoint;

class StubState extends BaseState
{
    public override function abortMove()
    {
        //* Do nothing
    }
    
    public override function onLMBPressed(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return false;
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}