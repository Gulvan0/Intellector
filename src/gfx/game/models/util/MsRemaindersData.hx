package gfx.game.models.util;

import net.shared.board.Rules;
import net.shared.Constants;
import net.shared.utils.UnixTimestamp;
import net.shared.TimeControl;
import net.shared.dataobj.TimeReservesData;
import net.shared.dataobj.GameModelData;
import gfx.game.interfaces.IReadOnlyMsRemainders;
import net.shared.PieceColor;

class MsRemaindersData implements IReadOnlyMsRemainders
{
    private final firstColorToMove:PieceColor;
    private final secsIncrement:Float;

    private var reservesByPointer:Array<TimeReservesData>;
    private var reservesWhenEnded:TimeReservesData;
    private var secsAddedAfterLastMove:Map<PieceColor, Float>;

    private function getCurrentPointer() 
    {
        return reservesByPointer.length - 1;    
    }

    public function getTimeLeftAt(movePointer:Int):TimeReservesData
    {
        return reservesByPointer[movePointer].copy();
    }

    public function getTimeLeftAtStart():TimeReservesData
    {
        return getTimeLeftAt(0);
    }

    public function getTimeLeftWhenEnded():TimeReservesData
    {
        return reservesWhenEnded.copy();
    }

    private function clearSecsAddedData() 
    {
        secsAddedAfterLastMove = [for (color in PieceColor.createAll()) color => 0.0];
    }

    public function getActualReserves(nowTimestamp:UnixTimestamp):TimeReservesData
    {
        if (reservesWhenEnded != null)
            return reservesWhenEnded;

        var currentPointer:Int = getCurrentPointer();
        var activeTimerColor:Null<PieceColor> = Rules.getActiveTimerColorAt(currentPointer, firstColorToMove);
        var lastMoveReserves:TimeReservesData = reservesByPointer[currentPointer].copy();

        if (activeTimerColor != null)
        {
            var secsThen:Float = lastMoveReserves.getSecsLeftAtTimestamp(activeTimerColor);
            var secsPassed:Float = lastMoveReserves.timestamp.getIntervalSecsTo(nowTimestamp);
            var secsNow:Float = Math.max(secsThen - secsPassed, 0);
            lastMoveReserves.setSecsLeftAtTimestamp(activeTimerColor, secsNow);
        }

        for (color => addition in secsAddedAfterLastMove.keyValueIterator())
            lastMoveReserves.addSecsLeftAtTimestamp(color, addition);
        
        lastMoveReserves.timestamp = nowTimestamp;

        return lastMoveReserves;
    }

    public function onMoveMade(timestamp:UnixTimestamp) 
    {
        var activeTimerColorPriorToEvent:Null<PieceColor> = Rules.getActiveTimerColorAt(getCurrentPointer(), firstColorToMove);
        var reservesWithoutIncrement:TimeReservesData = getActualReserves(timestamp);
        if (activeTimerColorPriorToEvent != null)
            reservesWithoutIncrement.addSecsLeftAtTimestamp(activeTimerColorPriorToEvent, secsIncrement);
        reservesByPointer.push(reservesWithoutIncrement);
        clearSecsAddedData();
    }

    public function onTimeAdded(receivingSide:PieceColor) 
    {
        secsAddedAfterLastMove[receivingSide] += Constants.msAddedByOpponent / 1000;
    }

    public function correctLastMoveTimestamp(timestamp:UnixTimestamp) 
    {
        var activeTimerColorDuringLastMove:Null<PieceColor> = Rules.getActiveTimerColorAt(getCurrentPointer() - 1, firstColorToMove);
        var lastMoveReserves:TimeReservesData = reservesByPointer[getCurrentPointer()];
        var oldTimestamp:UnixTimestamp = lastMoveReserves.timestamp;
        var secsPassedSinceOld:Float = oldTimestamp.getIntervalSecsTo(timestamp);

        if (activeTimerColorDuringLastMove != null)
            lastMoveReserves.addSecsLeftAtTimestamp(activeTimerColorDuringLastMove, -secsPassedSinceOld);
        lastMoveReserves.timestamp = timestamp;
    }

    /**
        timestampForTimeReset is null only for client-side rollbacks (such as when the move wasn't accepted by the server)
    **/
    public function onRollback(cancelledMovesCount:Int, timestampForTimeReset:Null<UnixTimestamp>) 
    {
        reservesByPointer = reservesByPointer.slice(0, -cancelledMovesCount);
        if (timestampForTimeReset != null)
            reservesByPointer[getCurrentPointer()].timestamp = timestampForTimeReset;
    }

    public function recordTimeOnGameEnded(timestamp:UnixTimestamp)
    {
        reservesWhenEnded = getActualReserves(timestamp);
    }

    public function new(timeControl:TimeControl, gameStartedAt:UnixTimestamp, firstColorToMove:PieceColor) 
    {
        this.firstColorToMove = firstColorToMove;
        this.secsIncrement = timeControl.incrementSecs;

        this.reservesByPointer = [new TimeReservesData(timeControl.startSecs, timeControl.startSecs, gameStartedAt)];
        this.reservesWhenEnded = null;
        clearSecsAddedData();
    }
}