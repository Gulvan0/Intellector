package gameboard.behaviors;

class EditorFreeMoveBehavior extends EditorBehavior implements IBehavior 
{
    public function onMoveChosen(ply:Ply):Void
	{
        var situation = boardInstance.shownSituation.copy();
        situation.set(ply.to, situation.get(ply.from));
        situation.set(ply.from, Hex.empty());
        boardInstance.setShownSituation(situation);
    }
    
    public function movePossible(from:IntPoint, to:IntPoint):Bool
	{
        return !equal(from, to);
    }
    
    public function onHexChosen(coords:IntPoint)
    {
        //* Do nothing
    }
    
    public function new()
    {
        
    }
}