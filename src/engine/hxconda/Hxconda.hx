package engine.hxconda;

import engine.hxconda.board.Board;
import engine.hxconda.board.Move;
import engine.hxconda.evaluation.Evaluation;
import engine.hxconda.evaluation.StyleBonuses;
import engine.hxconda.search.AlphaBetaSearch;
import engine.hxconda.search.BestMoveReport;
import engine.hxconda.search.SearchMemory;
import engine.hxconda.search.budget.DepthBudget;
import engine.hxconda.search.budget.NodeBudget;
import engine.hxconda.search.budget.TimeBudget;
import engine.hxconda.search.weakening.RootMoveScores;
import engine.hxconda.search.weakening.WeakenedMoveChoice;
import engine.hxconda.search.weakening.Weakening;

/**
    Runs searches on the calling thread, blocking it; the main thread should go through `HxcondaEngine` instead.
    Positions are given in the Anaconda notation (see `Board`); malformed ones are replaced by the default starting position.
    `history` lists the positions of the game before the searched one, oldest first: the search scores returning to any of them as a draw.
    Searches given the same `gameId` in a row, with the same style, share what they learn (see `SearchMemory`); a search without
    one starts from scratch and leaves the shared memory alone.
**/
class Hxconda
{
    private static var memory:Null<SearchMemory> = null;
    private static var memoryGameId:Null<String> = null;
    private static var memoryStyle:HxcondaStyle = Standard;

    /** Searches within the node budget of a difficulty `level` (0 to 10), reporting the percentage of the budget used up **/
    public static function bestMoveByLevel(notation:Null<String>, history:Null<Array<String>>, gameId:Null<String>, level:Int, onProgress:(percent:Int)->Void):BestMoveReport
    {
        var board:Board = createBoard(notation, history, Standard);
        var budget:NodeBudget = NodeBudget.forLevel(level, onProgress);
        return new AlphaBetaSearch<NodeBudget>(board, budget, budget.noiseAmplitude, 0, memoryFor(gameId, Standard)).run();
    }

    /** Searches within `nodeLimit` nodes, adding evaluation noise of up to `noiseAmplitude`, see `NodeBudget` **/
    public static function bestMoveByNodes(notation:Null<String>, history:Null<Array<String>>, gameId:Null<String>, nodeLimit:Int, noiseAmplitude:Float, onProgress:(percent:Int)->Void):BestMoveReport
    {
        var board:Board = createBoard(notation, history, Standard);
        var budget:NodeBudget = new NodeBudget(nodeLimit, noiseAmplitude, onProgress);
        return new AlphaBetaSearch<NodeBudget>(board, budget, budget.noiseAmplitude, 0, memoryFor(gameId, Standard)).run();
    }

    /** Searches for `durationMs` milliseconds, reporting the best move after every iteration **/
    public static function bestMoveByTime(notation:Null<String>, history:Null<Array<String>>, gameId:Null<String>, durationMs:Float, onIteration:BestMoveReport->Void):BestMoveReport
    {
        var board:Board = createBoard(notation, history, Standard);
        return new AlphaBetaSearch<TimeBudget>(board, new TimeBudget(durationMs, onIteration), 0, 0, memoryFor(gameId, Standard)).run();
    }

    /**
        Searches until the iteration of depth `maxDepth` (in plies) completes or, with a `timeCapMs`, until the cap runs out,
        abandoning the running iteration then. Reports the best move after every completed iteration.
        On the cap, the move comes from the latest completed even iteration (depth 1 if none), unless the abandoned iteration
        right after it has already found a move, which is played then.
        An iteration proving a side wins ends the search, see `DepthBudget`, and its move is played whatever its depth,
        unweakened unless the iteration scored the root moves.
        `style` sets the evaluation and the draw score. With a `weakening`, the move is picked among the scored root moves
        by `WeakenedMoveChoice`, with `style`'s `StyleBonuses`; its score is then exact or, without candidates, a bound.
    **/
    public static function bestMoveByDepth(notation:Null<String>, history:Null<Array<String>>, gameId:Null<String>, maxDepth:Int, timeCapMs:Null<Float>, weakening:Null<Weakening>, style:HxcondaStyle, onIteration:BestMoveReport->Void):BestMoveReport
    {
        var board:Board = createBoard(notation, history, style);
        var latestEvenReport:Null<BestMoveReport> = null;
        var latestReport:Null<BestMoveReport> = null;
        var budget:DepthBudget = new DepthBudget(maxDepth, timeCapMs, report -> {
            latestReport = report.copy();
            if (report.depth % 2 == 0)
                latestEvenReport = latestReport;
            onIteration(report);
        });
        var search:AlphaBetaSearch<DepthBudget> = new AlphaBetaSearch<DepthBudget>(board, budget, 0, Evaluation.drawScore(style, board.turn), memoryFor(gameId, style));

        var scores:Null<RootMoveScores> = weakening != null ? search.scoreRootMoves(weakening) : null;
        if (scores != null)
        {
            if (latestReport.depth > scores.depth && isDecisive(latestReport))
                return latestReport;
            return weakenedReport(board, scores, weakening, style);
        }

        var report:BestMoveReport = search.run();
        if (report.depth % 2 == 1 && latestEvenReport != null && !isDecisive(report))
            return latestEvenReport;
        return report;
    }

    /** The memory for a search of game `gameId` evaluating as `style`: the previous search's if it belongs to the same game, prepared for the next one **/
    private static function memoryFor(gameId:Null<String>, style:HxcondaStyle):SearchMemory
    {
        if (gameId == null)
            return new SearchMemory();

        if (memory != null && memoryGameId == gameId && memoryStyle == style)
            memory.startNextSearch();
        else
        {
            memory = new SearchMemory();
            memoryGameId = gameId;
            memoryStyle = style;
        }
        return memory;
    }

    private static function isDecisive(report:BestMoveReport):Bool
    {
        return Math.abs(report.score) > Evaluation.DECISIVE_THRESHOLD;
    }

    private static function weakenedReport(board:Board, scores:RootMoveScores, weakening:Weakening, style:HxcondaStyle):BestMoveReport
    {
        var bonuses:StyleBonuses = new StyleBonuses(board, style);
        var chosen:Int = WeakenedMoveChoice.choose(scores, weakening, bonuses.bonus);
        var move:Move = scores.moves[chosen];
        var score:Float = board.turn == White ? scores.values[chosen] : -scores.values[chosen];
        var report:BestMoveReport = new BestMoveReport();
        report.record(move, score, scores.depth, scores.exactCount(), scores.lines[chosen] ?? [move]);
        return report;
    }

    /** Sets the evaluation to `style`'s first, since an earlier search in this thread may have set another one **/
    private static function createBoard(notation:Null<String>, history:Null<Array<String>>, style:HxcondaStyle):Board
    {
        Evaluation.useStyle(style);
        var board:Board = new Board(notation);
        if (history != null)
            board.enterPastPositions(history);
        return board;
    }
}
