package gameboard.behaviors;

import net.shared.board.RawPly;
import net.shared.board.HexCoords;
import gfx.analysis.PeripheralEvent;
import net.shared.ServerEvent;

interface IBehavior
{
    public function init(board:GameBoard):Void;
    public function handleNetEvent(event:ServerEvent):Void;
    public function handleAnalysisPeripheralEvent(event:PeripheralEvent):Void;
    public function movePossible(from:HexCoords, to:HexCoords):Bool;
    public function allowedToMove(piece:Piece):Bool;
    public function returnToCurrentOnLMB():Bool;
    public function onMoveChosen(ply:RawPly):Void;
    public function onHexChosen(coords:HexCoords):Void;
    public function onAboutToScrollAway():Void;
    public function markersDisabled():Bool;
    public function hoverDisabled():Bool;
    public function onVoidClick():Void;
    public function onPremovePreferenceUpdated():Void;
}