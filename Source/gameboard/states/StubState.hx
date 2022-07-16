package gameboard.states;

import struct.IntPoint;

class StubState extends BaseState
{
    public function onEntered()
    {
        //* Do nothing
    }
    
    public function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function exitToNeutral()
    {
        //* Do nothing
    }

    public function reactsToHover(location:IntPoint):Bool
    {
        return false;
    }

    public function new()
    {
        
    }
}