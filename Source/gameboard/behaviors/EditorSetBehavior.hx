package gameboard.behaviors;

import net.shared.PieceType;
import struct.Hex;
import struct.Situation;
import gameboard.states.HexSelectionState;
import gameboard.states.NeutralState;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import struct.Ply;
import struct.IntPoint;
import net.shared.ServerEvent;
import struct.ReversiblePly;
import net.shared.PieceColor;
import utils.AssetManager;

class EditorSetBehavior extends EditorBehavior implements IBehavior 
{
    private var prototypeHex:Hex;

    public function onMoveChosen(ply:Ply):Void
	{
        //* Do nothing
    }
    
    public function movePossible(from:IntPoint, to:IntPoint):Bool
	{
        return true;
    }
    
    public function onHexChosen(coords:IntPoint)
    {
        boardInstance.setHexDirectly(coords, prototypeHex);
    }
    
    public function new(type:PieceType, color:PieceColor)
    {
        prototypeHex = Hex.occupied(type, color);
    }
}