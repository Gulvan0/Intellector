package engine.hxconda;

import engine.hxconda.board.Board;
import engine.hxconda.search.AlphaBetaSearch;
import engine.hxconda.search.BestMoveReport;
import engine.hxconda.search.budget.DepthBudget;
import engine.hxconda.search.budget.NodeBudget;
import engine.hxconda.search.budget.TimeBudget;

/**
    Runs searches on the calling thread, blocking it; the main thread should go through `HxcondaEngine` instead.
    Positions are given in the Anaconda notation (see `Board`); malformed ones are replaced by the default starting position.
    `history` lists the positions of the game before the searched one, oldest first: the search scores returning to any of them as a draw.
**/
class Hxconda
{
    /** Searches within the node budget of a difficulty `level` (0 to 10), reporting the percentage of the budget used up **/
    public static function bestMoveByLevel(notation:Null<String>, history:Null<Array<String>>, level:Int, onProgress:(percent:Int)->Void):BestMoveReport
    {
        var board:Board = createBoard(notation, history);
        var budget:NodeBudget = NodeBudget.forLevel(level, onProgress);
        return new AlphaBetaSearch<NodeBudget>(board, budget, budget.noiseAmplitude).run();
    }

    /** Searches within `nodeLimit` nodes, adding evaluation noise of up to `noiseAmplitude`, see `NodeBudget` **/
    public static function bestMoveByNodes(notation:Null<String>, history:Null<Array<String>>, nodeLimit:Int, noiseAmplitude:Float, onProgress:(percent:Int)->Void):BestMoveReport
    {
        var board:Board = createBoard(notation, history);
        var budget:NodeBudget = new NodeBudget(nodeLimit, noiseAmplitude, onProgress);
        return new AlphaBetaSearch<NodeBudget>(board, budget, budget.noiseAmplitude).run();
    }

    /** Searches for `durationMs` milliseconds, reporting the best move after every iteration **/
    public static function bestMoveByTime(notation:Null<String>, history:Null<Array<String>>, durationMs:Float, onIteration:BestMoveReport->Void):BestMoveReport
    {
        var board:Board = createBoard(notation, history);
        return new AlphaBetaSearch<TimeBudget>(board, new TimeBudget(durationMs, onIteration), 0).run();
    }

    /**
        Searches until the iteration of depth `maxDepth` (in plies) completes or, with a `timeCapMs`, until the cap runs out,
        abandoning the running iteration then. Reports the best move after every completed iteration.
    **/
    public static function bestMoveByDepth(notation:Null<String>, history:Null<Array<String>>, maxDepth:Int, timeCapMs:Null<Float>, onIteration:BestMoveReport->Void):BestMoveReport
    {
        var board:Board = createBoard(notation, history);
        return new AlphaBetaSearch<DepthBudget>(board, new DepthBudget(maxDepth, timeCapMs, onIteration), 0).run();
    }

    private static function createBoard(notation:Null<String>, history:Null<Array<String>>):Board
    {
        var board:Board = new Board(notation);
        if (history != null)
            board.enterPastPositions(history);
        return board;
    }
}
