package gameboard.behaviors;

import net.shared.PieceType;
import gameboard.states.HexSelectionState;
import gameboard.states.NeutralState;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import utils.AssetManager;
import net.shared.board.RawPly;
import net.shared.board.Hex;
import net.shared.board.HexCoords;

class EditorSetBehavior extends EditorBehavior implements IBehavior 
{
    private var prototypeHex:Hex;

    public function onMoveChosen(ply:RawPly):Void
	{
        //* Do nothing
    }
    
    public function movePossible(from:HexCoords, to:HexCoords):Bool
	{
        return true;
    }
    
    public function onHexChosen(coords:HexCoords)
    {
        boardInstance.setHexDirectly(coords, prototypeHex);
    }
    
    public function new(type:PieceType, color:PieceColor)
    {
        prototypeHex = Hex.construct(type, color);
    }
}