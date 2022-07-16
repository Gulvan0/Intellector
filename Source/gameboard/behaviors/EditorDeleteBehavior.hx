package gameboard.behaviors;

import struct.Hex;
import struct.Situation;
import gameboard.states.HexSelectionState;
import gameboard.states.NeutralState;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import struct.Ply;
import struct.IntPoint;
import net.ServerEvent;
import struct.ReversiblePly;
import struct.PieceColor;
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
    
    public function new()
    {
        
    }
}