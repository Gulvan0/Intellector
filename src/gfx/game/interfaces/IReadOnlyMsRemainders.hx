package gfx.game.interfaces;

import net.shared.dataobj.TimeReservesData;
import net.shared.PieceColor;

interface IReadOnlyMsRemainders
{
    public function getTimeLeftAfterMove(plyNum:Int):TimeReservesData;
    public function getTimeLeftAtStart():TimeReservesData;    
    public function getTimeLeftWhenEnded():TimeReservesData;
}