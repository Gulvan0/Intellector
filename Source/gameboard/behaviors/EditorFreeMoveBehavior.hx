package gameboard.behaviors;

import net.shared.board.RawPly;
import net.shared.board.Hex;
import net.shared.board.HexCoords;

class EditorFreeMoveBehavior extends EditorBehavior implements IBehavior 
{
    public function onMoveChosen(ply:RawPly):Void
	{
        var situation = boardInstance.shownSituation.copy();
        situation.set(ply.to, situation.get(ply.from));
        situation.set(ply.from, Empty);
        boardInstance.setShownSituation(situation);
    }
    
    public function movePossible(from:HexCoords, to:HexCoords):Bool
	{
        return !equal(from, to);
    }
    
    public function onHexChosen(coords:HexCoords)
    {
        //* Do nothing
    }
    
    public function new()
    {
        
    }
}