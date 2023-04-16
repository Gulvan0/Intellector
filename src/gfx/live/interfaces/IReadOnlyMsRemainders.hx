package gfx.live.interfaces;

import net.shared.PieceColor;

interface IReadOnlyMsRemainders
{
    public function getSecsLeftAfterMove(side:PieceColor, plyNum:Int):Null<Float>;
    public function getSecsLeftAtStart(side:PieceColor):Float;    
    public function getSecsLeftWhenEnded(side:PieceColor):Null<Float>;
}