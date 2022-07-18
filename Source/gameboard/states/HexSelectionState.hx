package gameboard.states;

import struct.IntPoint;
import struct.Hex;

class HexSelectionState extends BaseState
{
    public final occupiedOnly:Bool;

    private function possibleLocation(location:Null<IntPoint>):Bool
    {
        return (location != null) && (!occupiedOnly || !boardInstance.shownSituation.get(location).isEmpty());
    }

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
        if (possibleLocation(location))
            boardInstance.behavior.onHexChosen(location);
    }

    public function reactsToHover(location:IntPoint):Bool
    {
        return possibleLocation(location);
    }
    
    private function isHoverStrong():Bool
    {
        return true;
    }

    public function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function new(occupiedOnly:Bool)
    {
        this.occupiedOnly = occupiedOnly;
    }
}