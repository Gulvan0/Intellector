package gameboard.behaviors;

import struct.Ply;
import struct.IntPoint;
import net.ServerEvent;

interface IBehavior
{
    public function handleNetEvent(event:ServerEvent):Void;
    public function movePossible(from:IntPoint, to:IntPoint):Bool;
    public function allowedToMove(piece:Piece):Bool;
    public function returnToCurrentOnLMB():Bool;
    public function onMoveChosen(ply:Ply):Void;
    public function markersDisabled():Bool;
    public function hoverDisabled():Bool;
    public function onVoidClick():Void;
}