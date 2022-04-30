package gameboard.states;

import struct.IntPoint;

class StubState extends BaseState
{
    public override function abortMove()
    {
        //* Do nothing
    }
    
    public override function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public override function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return false;
    }

    public function new()
    {
        super();
    }
}