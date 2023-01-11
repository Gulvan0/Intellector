package gameboard.states;

import net.shared.board.HexCoords;

class StubState extends BaseState
{
    public function onEntered()
    {
        //* Do nothing
    }
    
    public function onLMBPressed(location:Null<HexCoords>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function onLMBReleased(location:Null<HexCoords>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function exitToNeutral()
    {
        //* Do nothing
    }

    public function reactsToHover(location:HexCoords):Bool
    {
        return false;
    }
    
    private function isHoverStrong():Bool
    {
        return false;
    }

    public function new()
    {
        
    }
}