package gameboard.behaviors;

import gameboard.states.HexSelectionState;
import gameboard.states.NeutralState;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import net.shared.board.RawPly;
import net.shared.board.Hex;
import net.shared.board.HexCoords;

class EditorDeleteBehavior extends EditorBehavior implements IBehavior 
{
    public function onMoveChosen(ply:RawPly):Void
	{
        //* Do nothing
    }
    
    public function onHexChosen(coords:HexCoords)
    {
        boardInstance.setHexDirectly(coords, Empty);
    }
    
    public function movePossible(from:HexCoords, to:HexCoords):Bool
	{
        return true;
    }
    
    public function new()
    {
        
    }
}