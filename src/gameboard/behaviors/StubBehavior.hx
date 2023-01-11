package gameboard.behaviors;

import gameboard.components.Piece;
import net.shared.board.HexCoords;
import net.shared.board.RawPly;
import gfx.analysis.PeripheralEvent;
import net.shared.ServerEvent;

class StubBehavior implements IBehavior 
{
    public function init(board:GameBoard) {}
    public function handleNetEvent(event:ServerEvent) {}
    public function handleAnalysisPeripheralEvent(event:PeripheralEvent) {}
    public function onPremovePreferenceUpdated() {}
    public function onMoveChosen(ply:RawPly) {}
    public function onHexChosen(coords:HexCoords) {}
    public function onAboutToScrollAway() {}
    public function onVoidClick() {}

    public function movePossible(from:HexCoords, to:HexCoords):Bool
    {
        return false;
    }

    public function allowedToMove(piece:Piece):Bool
    {
        return false;
    }
    
    public function returnToCurrentOnLMB():Bool
    {
        return false;
    }
    
    public function markersDisabled():Bool
    {
        return true;
    }
    
    public function hoverDisabled():Bool
    {
        return true;
    }

    public function new()
    {
        
    }
}