package gfx.game.struct;

import net.shared.utils.UnixTimestamp;
import utils.TimeControl;
import net.shared.dataobj.TimeReservesData;
import net.shared.dataobj.GameModelData;
import gfx.game.interfaces.IReadOnlyMsRemainders;
import net.shared.PieceColor;

class MsRemaindersData implements IReadOnlyMsRemainders
{
    private var reservesAfterMove:Array<TimeReservesData> = [];
    private var reservesWhenEnded:TimeReservesData = null;
    private var initialReserves:TimeReservesData;

    public function getTimeLeftAfterMove(plyNum:Int):TimeReservesData
    {
        if (plyNum > 0)
            return reservesAfterMove[plyNum - 1];

        return initialReserves.copy();
    }

    public function getTimeLeftAtStart():TimeReservesData
    {
        return initialReserves.copy();
    }

    public function getTimeLeftWhenEnded():TimeReservesData
    {
        return reservesWhenEnded.copy();
    }

    public function append(timeData:TimeReservesData) 
    {
        reservesAfterMove.push(timeData.copy());
    }

    public function addTime(receivingSide:PieceColor, secs:Float) 
    {
        reservesAfterMove[reservesAfterMove.length - 1].addSecsLeftAtTimestamp(receivingSide, secs);
    }

    public function rollback(newPlayedMovesCnt:Int) 
    {
        reservesAfterMove = reservesAfterMove.slice(0, newPlayedMovesCnt);
    }

    public function recordTimeOnGameEnded(timeData:TimeReservesData)
    {
        reservesWhenEnded = timeData.copy();
    }

    public function new(timeControl:TimeControl, gameStartedAt:UnixTimestamp) 
    {
        this.initialReserves = new TimeReservesData(timeControl.startSecs, timeControl.startSecs, gameStartedAt);
    }
}