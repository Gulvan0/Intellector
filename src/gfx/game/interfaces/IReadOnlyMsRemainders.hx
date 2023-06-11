package gfx.game.interfaces;

import net.shared.utils.UnixTimestamp;
import net.shared.dataobj.TimeReservesData;
import net.shared.PieceColor;

interface IReadOnlyMsRemainders
{
    public function getTimeLeftAt(movePointer:Int):TimeReservesData;
    public function getTimeLeftAtStart():TimeReservesData;    
    public function getTimeLeftWhenEnded():TimeReservesData;
    public function getActualReserves(nowTimestamp:UnixTimestamp):TimeReservesData;
}