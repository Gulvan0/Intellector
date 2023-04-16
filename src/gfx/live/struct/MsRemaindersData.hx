package gfx.live.struct;

import gfx.live.interfaces.IReadOnlyMsRemainders;
import net.shared.PieceColor;
import serialization.GameLogParser.GameLogParserOutput;

class MsRemaindersData implements IReadOnlyMsRemainders
{
    private var msLeftOnMove:Map<PieceColor, Array<Null<Int>>> = [White => [], Black => []];
    private var msLeftWhenEnded:Null<Map<PieceColor, Int>> = null;
    private var msPerMoveDataAvailable:Bool = true;
    private var initialSecs:Int;
    private var moveCount:Int;

    public function getSecsLeftAfterMove(side:PieceColor, plyNum:Int):Null<Float>
    {
        if (!msPerMoveDataAvailable)
            return null;

        if (plyNum == moveCount && msLeftWhenEnded != null)
            return msLeftWhenEnded[side] / 1000;

        var index:Int = plyNum - 1;
        while (index >= 0)
        {
            var msLeft:Null<Int> = msLeftOnMove[side][index];
            if (msLeft != null)
                return msLeft / 1000;
            else
                index--;
        }

        return initialSecs;
    }

    public function getSecsLeftAtStart(side:PieceColor):Float
    {
        return initialSecs;
    }

    public function getSecsLeftWhenEnded(side:PieceColor):Null<Float>
    {
        return msLeftWhenEnded == null? null : msLeftWhenEnded[side] / 1000;
    }

    public function appendRemainders(whiteSecs:Int, blackSecs:Int) 
    {
        msLeftOnMove[White].push(whiteSecs);
        msLeftOnMove[Black].push(blackSecs);
        moveCount++;
    }

    public function appendRemainder(side:PieceColor, secs:Int) 
    {
        var movedPlayerArray = msLeftOnMove[side];
        var opponentArray = msLeftOnMove[opposite(side)];

        movedPlayerArray.push(secs);
        opponentArray.push(opponentArray[opponentArray.length - 1]);
        moveCount++;
    }

    public function addTime(receivingSide:PieceColor, secs:Int) 
    {
        var receiverArray = msLeftOnMove[receivingSide];

        receiverArray[receiverArray.length - 1] += secs;
    }

    public function rollback(newPlayedMovesCnt:Int) 
    {
        msLeftOnMove[White] = msLeftOnMove[White].slice(0, newPlayedMovesCnt);
        msLeftOnMove[Black] = msLeftOnMove[Black].slice(0, newPlayedMovesCnt);
        moveCount = newPlayedMovesCnt;
    }

    public function recordTimeOnGameEnded(whiteSecs:Int, blackSecs:Int)
    {
        msLeftWhenEnded = [White => whiteSecs, Black => blackSecs];
    }

    public function new(parsedLog:GameLogParserOutput, newGame:Bool) 
    {
        this.msLeftOnMove = parsedLog.msLeftOnMove;
        this.msLeftWhenEnded = parsedLog.msLeftWhenEnded;
        this.msPerMoveDataAvailable = newGame? true : parsedLog.msPerMoveDataAvailable;
        this.initialSecs = parsedLog.timeControl.startSecs;
        this.moveCount = parsedLog.moveCount;
    }
}