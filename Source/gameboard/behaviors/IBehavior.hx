package gameboard.behaviors;

import gfx.analysis.PeripheralEvent;
import struct.Ply;
import struct.IntPoint;
import net.ServerEvent;

interface IBehavior
{
    public function init(board:GameBoard):Void;
    public function handleNetEvent(event:ServerEvent):Void;
    public function handleAnalysisPeripheralEvent(event:PeripheralEvent):Void;
    public function movePossible(from:IntPoint, to:IntPoint):Bool;
    public function allowedToMove(piece:Piece):Bool;
    public function returnToCurrentOnLMB():Bool;
    public function onMoveChosen(ply:Ply):Void;
    public function onHexChosen(coords:IntPoint):Void;
    public function onAboutToScrollAway():Void;
    public function markersDisabled():Bool;
    public function hoverDisabled():Bool;
    public function onVoidClick():Void;
    public function onPremovePreferenceUpdated():Void;
}