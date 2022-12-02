package gameboard.behaviors;

import gameboard.states.HexSelectionState;
import gameboard.states.NeutralState;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import utils.AssetManager;

class EditorDeleteBehavior extends EditorBehavior implements IBehavior 
{
    public function onMoveChosen(ply:Ply):Void
	{
        //* Do nothing
    }
    
    public function onHexChosen(coords:IntPoint)
    {
        boardInstance.setHexDirectly(coords, Hex.empty());
    }
    
    public function movePossible(from:IntPoint, to:IntPoint):Bool
	{
        return true;
    }
    
    public function new()
    {
        
    }
}