package gameboard.states;

import haxe.ui.geom.Point;
import net.shared.board.HexCoords;

class StubState extends BaseState
{
    public function onEntered()
    {
        //* Do nothing
    }
    
    public function onLMBPressed(location:Null<HexCoords>, screenCoords:Point, shiftPressed:Bool, ctrlPressed:Bool)
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