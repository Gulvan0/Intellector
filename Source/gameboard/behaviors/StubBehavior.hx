package gameboard.behaviors;

import gfx.analysis.PeripheralEvent;
import struct.Ply;
import net.ServerEvent;
import struct.IntPoint;

class StubBehavior implements IBehavior 
{
    public function init(board:GameBoard) {}
    public function handleNetEvent(event:ServerEvent) {}
    public function handleAnalysisPeripheralEvent(event:PeripheralEvent) {}
    public function onMoveChosen(ply:Ply) {}
    public function onHexChosen(coords:IntPoint) {}
    public function onAboutToScrollAway() {}
    public function onVoidClick() {}

    public function movePossible(from:IntPoint, to:IntPoint):Bool
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