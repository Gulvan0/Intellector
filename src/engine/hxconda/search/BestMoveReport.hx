package engine.hxconda.search;

import engine.hxconda.board.Move;

/**
    The search result known so far.
**/
class BestMoveReport
{
    /** Whether anything has been recorded yet **/
    public var isSet(default, null):Bool = false;
    public var move(default, null):Move = Move.NONE;
    public var score(default, null):Float = 0;
    /** Depth of the iteration that found `move` **/
    public var depth(default, null):Int = 0;
    /** How many root moves had been searched when `move` was found **/
    public var searchedRootMoveCount(default, null):Int = 0;
    /**
        Line behind the best score of the root, starting with a root move.
        Tracked by time- and depth-limited searches only. Mostly updated mid-iteration, so it can disagree with `move`.
    **/
    public var principalLine(default, null):Null<Array<Move>> = null;

    /**
        Records the best root move of a running iteration. Ignored once something is recorded,
        unless the previously recorded move is among the first `searchedCount` of `rootMoves`.
        `line` is listed backwards, from the deepest move to the root move.
    **/
    public function recordRootProgress(rootMoves:Array<Move>, searchedCount:Int, move:Move, score:Float, depth:Int, line:Null<Array<Move>>):Void
    {
        if (isSet && !rootMoves.slice(0, searchedCount).contains(this.move))
            return;

        record(move, score, depth, searchedCount);
        if (line != null)
        {
            principalLine = line.copy();
            principalLine.reverse();
        }
    }

    /** `line` starts with `move`; the previous principal line stays if it is absent **/
    public function record(move:Move, score:Float, depth:Int, searchedRootMoveCount:Int, ?line:Array<Move>):Void
    {
        isSet = true;
        this.move = move;
        this.score = score;
        this.depth = depth;
        this.searchedRootMoveCount = searchedRootMoveCount;
        if (line != null)
            principalLine = line;
    }

    public function copy():BestMoveReport
    {
        var report:BestMoveReport = new BestMoveReport();
        if (isSet)
            report.record(move, score, depth, searchedRootMoveCount, principalLine?.copy());
        return report;
    }

    public function new() {}
}
