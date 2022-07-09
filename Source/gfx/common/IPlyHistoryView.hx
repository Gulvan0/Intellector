package gfx.common;

import struct.PieceColor;

interface IPlyHistoryView
{
    public function clear(?updatedFirstColorToMove:PieceColor):Void;
    public function writePlyStr(plyStr:String, selected:Bool):Void;
    public function revertPlys(cnt:Int):Void;
    public function rewrite(newPlyStrSequence:Array<String>, newPointerPos:Int):Void;
}