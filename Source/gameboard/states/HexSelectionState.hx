package gameboard.states;

import struct.IntPoint;
import struct.Hex;

class HexSelectionState extends BaseState
{
    public function onEntered()
    {
        //* Do nothing
    }

    public function exitToNeutral()
    {
        throw "Invalid transition";
    }

    public function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        if (location != null)
            boardInstance.behavior.onHexChosen(location);
    }

    public function reactsToHover(location:IntPoint):Bool
    {
        return true;
    }
    
    private function isHoverStrong():Bool
    {
        return true;
    }

    public function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function new()
    {
        
    }
}