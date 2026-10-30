package engine.hxconda.search;

import engine.hxconda.board.Board;
import engine.hxconda.board.BoardGeometry;
import engine.hxconda.board.Move;
import engine.hxconda.board.MoveGenerator;
import engine.hxconda.board.Piece;
import engine.hxconda.board.PieceArray;
import engine.hxconda.board.PlayerColor;
import engine.hxconda.evaluation.Evaluation.BLACK_WIN_SCORE;
import engine.hxconda.evaluation.Evaluation.DECISIVE_THRESHOLD;
import engine.hxconda.evaluation.Evaluation.DRAW_SCORE;
import engine.hxconda.evaluation.Evaluation.WHITE_WIN_SCORE;
import engine.hxconda.evaluation.Evaluation;
import engine.hxconda.search.budget.SearchBudget;

/**
    Iterative deepening principal variation search with aspiration windows, a transposition table, null move pruning,
    extensions for captures and checks, history-based reductions and a capture-only quiescence search.
    Specialized per budget class `B`, which keeps the budget checks inlined.
**/
@:generic
class AlphaBetaSearch<B:SearchBudget>
{
    private final board:Board;
    private final budget:B;
    private final table:TranspositionTable = new TranspositionTable();
    private final history:SearchHistory = new SearchHistory();
    private final report:BestMoveReport = new BestMoveReport();
    /** Root moves in generation order **/
    private final rootMoves:Array<Move>;
    /** Evaluation offset for the lines starting with each of `rootMoves` **/
    private final rootMoveNoise:Array<Float>;
    /** How many captures on each square the current quiescence line has made **/
    private final quiescenceCaptureCounts:Array<Int> = [for (_ in 0...BoardGeometry.SQUARE_COUNT) 0];
    private var currentRootMoveIndex:Int = 0;

    // Outcome of the latest completed `search()` call, besides its returned score
    private var resultMove:Move = Move.NONE;
    private var resultMoveIsQuiet:Bool = false;
    private var resultLine:Null<Array<Move>> = null;
    /** Whether the score comes from a repetition draw, which depends on the line and is kept out of the table **/
    private var resultIsDraw:Bool = false;
    /** Whether a node ran out of budget, which leaves the scores of all unfinished nodes meaningless **/
    private var isAborted:Bool = false;

    public function run():BestMoveReport
    {
        var rootHash:Int = board.hash();
        var rootVerificationKey:Int = board.verificationKey();
        var expectedScore:Float = 0;
        var iteration:Int = 1;

        budget.start();

        while (budget.hasRemaining())
        {
            var lastMoveColor:PlayerColor = cast (board.turn + iteration + 1) % 2;
            var alpha:Float;
            var beta:Float;
            if (lastMoveColor == White)
            {
                alpha = expectedScore - SearchTuning.ASPIRATION_NEAR_MARGIN;
                beta = expectedScore + SearchTuning.ASPIRATION_FAR_MARGIN;
            }
            else
            {
                alpha = expectedScore - SearchTuning.ASPIRATION_FAR_MARGIN;
                beta = expectedScore + SearchTuning.ASPIRATION_NEAR_MARGIN;
            }

            var score:Float = search(alpha, beta, iteration, 0, iteration, rootHash, rootVerificationKey, true);
            if (score <= alpha)
                score = search(Math.NEGATIVE_INFINITY, alpha + 1, iteration, 0, iteration, rootHash, rootVerificationKey, true);
            else if (score >= beta)
                score = search(beta - 1, Math.POSITIVE_INFINITY, iteration, 0, iteration, rootHash, rootVerificationKey, true);

            expectedScore = score;
            if (resultMove == Move.NONE)
                score = search(Math.NEGATIVE_INFINITY, Math.POSITIVE_INFINITY, iteration, 0, iteration, rootHash, rootVerificationKey, true);

            if (budget.hasRemaining() || iteration == 1)
                report.record(resultMove, score, iteration, rootMoves.length);

            budget.onIterationCompleted(report);

            if (report.move == Move.NONE)
                throw "Anaconda found no move to play";

            iteration++;
        }

        return report;
    }

    /** `verificationKey` is the position's `Board.verificationKey()`, needed only at depths that reach the table **/
    private function search(alpha:Float, beta:Float, depth:Int, extension:Float, maxDepth:Int, hash:Int, verificationKey:Int, isRoot:Bool):Float
    {
        if (depth > 0 && maxDepth > 1 && budget.isExhausted())
        {
            isAborted = true;
            return conclude(board.turn == White ? Math.POSITIVE_INFINITY : Math.NEGATIVE_INFINITY, Move.NONE, null);
        }

        budget.onNodeEntered();

        while (extension >= 1)
        {
            depth++;
            extension--;
        }
        while (extension <= -1)
        {
            depth = depth > 0 ? depth - 1 : 0;
            extension++;
        }

        if (depth >= SearchTuning.REPETITION_DEPTH && depth != maxDepth && board.visitCount(hash) >= SearchTuning.REPETITIONS_TO_DRAW)
            return conclude(DRAW_SCORE, Move.NONE, null, true);

        if (depth >= SearchTuning.HASHING_DEPTH)
            switch table.probe(hash, verificationKey, alpha, beta, depth)
            {
                case Cutoff:
                    return conclude(table.cutoffScore, table.cutoffMove, null);
                case WindowNarrowed if (budget.allowsWindowNarrowing(isRoot)):
                    alpha = table.narrowedAlpha;
                    beta = table.narrowedBeta;
                default:
            }

        if (alpha < -DECISIVE_THRESHOLD)
            alpha = BLACK_WIN_SCORE;
        if (beta > DECISIVE_THRESHOLD)
            beta = WHITE_WIN_SCORE;

        if (depth == SearchTuning.NULL_MOVE_DEPTH)
        {
            board.passTurn();
            var passedHash:Int = board.hashAfterPass(hash);
            var passedVerificationKey:Int = board.verificationKeyAfterPass(verificationKey);
            var isPruned:Bool = false;
            var nullMoveScore:Float = 0;
            var nullMoveScoreIsDraw:Bool = false;
            if (board.turn == Black && beta < Math.POSITIVE_INFINITY)
            {
                nullMoveScore = search(beta - 1, beta, depth - 1, extension, maxDepth, passedHash, passedVerificationKey, false);
                isPruned = nullMoveScore >= beta;
                nullMoveScoreIsDraw = resultIsDraw;
            }
            else if (board.turn == White && alpha > Math.NEGATIVE_INFINITY)
            {
                nullMoveScore = search(alpha, alpha + 1, depth - 1, extension, maxDepth, passedHash, passedVerificationKey, false);
                isPruned = nullMoveScore <= alpha;
                nullMoveScoreIsDraw = resultIsDraw;
            }
            board.passTurn();

            if (isPruned)
                return conclude(nullMoveScore, Move.NONE, null, nullMoveScoreIsDraw);
        }

        var decisiveScore:Null<Float> = board.decisiveScore();
        if (decisiveScore != null)
            return conclude(decisiveScore, Move.NONE, null);

        if (depth < 1)
            return conclude(quiesce(0, alpha, beta, evaluate()), Move.NONE, null);

        var score:Float = board.turn == White
            ? searchMovesAsMaximizer(alpha, beta, depth, extension, maxDepth, hash, verificationKey, isRoot)
            : searchMovesAsMinimizer(alpha, beta, depth, extension, maxDepth, hash, verificationKey, isRoot);

        if (resultMove != Move.NONE && resultMoveIsQuiet)
            history.recordQuietBest(resultMove);

        if (depth >= SearchTuning.HASHING_DEPTH && !resultIsDraw && !isAborted)
            table.store(hash, verificationKey, alpha, beta, resultMove, score, depth);

        return score;
    }

    private function searchMovesAsMaximizer(alpha:Float, beta:Float, depth:Int, extension:Float, maxDepth:Int, hash:Int, verificationKey:Int, isRoot:Bool):Float
    {
        var value:Float = BLACK_WIN_SCORE;
        var valueIsDraw:Bool = false;
        var bestMove:Move = Move.NONE;
        var bestMoveIsQuiet:Bool = false;
        var bestLine:Null<Array<Move>> = budget.tracksLines() ? [] : null;
        var moves:Array<Move> = orderedMoves(depth, hash, verificationKey);
        var moveCount:Int = moves.length;
        var attacksIntellector:Bool = board.attacksIntellector(board.turn);

        for (i in 0...moveCount)
        {
            var move:Move = moves[i];
            if (isRoot)
                currentRootMoveIndex = rootMoves.indexOf(move);

            var isCapture:Bool = board.isCapture(move);
            var childHash:Int = board.hashAfter(hash, move);
            var childVerificationKey:Int = depth >= SearchTuning.HASHING_DEPTH ? board.verificationKeyAfter(verificationKey, move) : 0; // children of shallower nodes never reach the table
            var tracksRepetition:Bool = depth >= SearchTuning.REPETITION_DEPTH;
            makeSearchedMove(move, childHash, tracksRepetition);
            var isCheck:Bool = attacksIntellector ? board.isIntellectorAttacked() : board.isIntellectorAttackedAfter(move);
            var adjustment:Float = moveExtension(move, isCapture || isCheck, i, moveCount, depth, maxDepth, childHash, childVerificationKey);
            var isReduced:Bool = adjustment < 0;
            var childExtension:Float = extension + adjustment;
            var unreducedExtension:Float = isReduced ? extension : childExtension;

            var score:Float;
            var line:Null<Array<Move>>;
            if (i >= 1 && beta - alpha > 1)
            {
                score = search(alpha, alpha + 1, depth - 1, childExtension, maxDepth, childHash, childVerificationKey, false);
                line = lineThrough(move);
                if (score > alpha && isReduced)
                {
                    score = search(alpha, alpha + 1, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false);
                    line = lineThrough(move);
                }
                if (score >= alpha + 1 && score < beta)
                {
                    score = search(score - 1, beta, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false);
                    line = lineThrough(move);
                }
            }
            else
            {
                score = search(alpha, beta, depth - 1, childExtension, maxDepth, childHash, childVerificationKey, false);
                line = lineThrough(move);
                if (score > alpha && isReduced)
                {
                    score = search(alpha, beta, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false);
                    line = lineThrough(move);
                }
            }
            var scoreIsDraw:Bool = resultIsDraw;
            score = SearchTuning.decayDecisiveScore(score);
            unmakeSearchedMove(childHash, tracksRepetition);

            if (score > value)
            {
                value = score;
                valueIsDraw = scoreIsDraw;
                if (budget.tracksLines())
                    bestLine = line.copy();
            }

            var isQuiet:Bool = !isCapture && !isCheck;
            if (isQuiet)
                history.recordQuietVisit(move);

            if (value > alpha)
            {
                alpha = value;
                bestMove = move;
                bestMoveIsQuiet = isQuiet;
            }

            if (value >= beta)
            {
                if (!isCapture)
                    history.recordCutoff(move, depth);
                break;
            }

            if (bestMove != Move.NONE && budget.allowsRootProgress(isRoot, depth, maxDepth))
                report.recordRootProgress(moves, i + 1, bestMove, value, maxDepth, bestLine);
        }

        resultMoveIsQuiet = bestMoveIsQuiet;
        return conclude(value, bestMove, bestLine, valueIsDraw);
    }

    private function searchMovesAsMinimizer(alpha:Float, beta:Float, depth:Int, extension:Float, maxDepth:Int, hash:Int, verificationKey:Int, isRoot:Bool):Float
    {
        var value:Float = WHITE_WIN_SCORE;
        var valueIsDraw:Bool = false;
        var bestMove:Move = Move.NONE;
        var bestMoveIsQuiet:Bool = false;
        var bestLine:Null<Array<Move>> = budget.tracksLines() ? [] : null;
        var moves:Array<Move> = orderedMoves(depth, hash, verificationKey);
        var moveCount:Int = moves.length;
        var attacksIntellector:Bool = board.attacksIntellector(board.turn);

        for (i in 0...moveCount)
        {
            var move:Move = moves[i];
            if (isRoot)
                currentRootMoveIndex = rootMoves.indexOf(move);

            var isCapture:Bool = board.isCapture(move);
            var childHash:Int = board.hashAfter(hash, move);
            var childVerificationKey:Int = depth >= SearchTuning.HASHING_DEPTH ? board.verificationKeyAfter(verificationKey, move) : 0; // children of shallower nodes never reach the table
            var tracksRepetition:Bool = depth >= SearchTuning.REPETITION_DEPTH;
            makeSearchedMove(move, childHash, tracksRepetition);
            var isCheck:Bool = attacksIntellector ? board.isIntellectorAttacked() : board.isIntellectorAttackedAfter(move);
            var adjustment:Float = moveExtension(move, isCapture || isCheck, i, moveCount, depth, maxDepth, childHash, childVerificationKey);
            var isReduced:Bool = adjustment < 0;
            var childExtension:Float = extension + adjustment;
            var unreducedExtension:Float = isReduced ? extension : childExtension;

            var score:Float;
            var line:Null<Array<Move>>;
            if (i >= 1 && beta - alpha > 1)
            {
                score = search(beta - 1, beta, depth - 1, childExtension, maxDepth, childHash, childVerificationKey, false);
                line = lineThrough(move);
                if (score < beta && isReduced)
                {
                    score = search(beta - 1, beta, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false);
                    line = lineThrough(move);
                }
                if (score > alpha && score <= beta - 1)
                {
                    score = search(alpha, score + 1, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false);
                    line = lineThrough(move);
                }
            }
            else
            {
                score = search(alpha, beta, depth - 1, childExtension, maxDepth, childHash, childVerificationKey, false);
                line = lineThrough(move);
                if (score < beta && isReduced)
                {
                    score = search(alpha, beta, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false);
                    line = lineThrough(move);
                }
            }
            var scoreIsDraw:Bool = resultIsDraw;
            score = SearchTuning.decayDecisiveScore(score);
            unmakeSearchedMove(childHash, tracksRepetition);

            if (score < value)
            {
                value = score;
                valueIsDraw = scoreIsDraw;
                if (budget.tracksLines())
                    bestLine = line.copy();
            }

            var isQuiet:Bool = !isCapture && !isCheck;
            if (isQuiet)
                history.recordQuietVisit(move);

            if (value < beta)
            {
                beta = value;
                bestMove = move;
                bestMoveIsQuiet = isQuiet;
            }

            if (value <= alpha)
            {
                if (!isCapture)
                    history.recordCutoff(move, depth);
                break;
            }

            if (bestMove != Move.NONE && budget.allowsRootProgress(isRoot, depth, maxDepth))
                report.recordRootProgress(moves, i + 1, bestMove, value, maxDepth, bestLine);
        }

        resultMoveIsQuiet = bestMoveIsQuiet;
        return conclude(value, bestMove, bestLine, valueIsDraw);
    }

    private inline function makeSearchedMove(move:Move, childHash:Int, tracksRepetition:Bool):Void
    {
        board.makeMove(move);
        if (tracksRepetition)
            board.enterPosition(childHash);
    }

    private inline function unmakeSearchedMove(childHash:Int, tracksRepetition:Bool):Void
    {
        board.unmakeMove();
        if (tracksRepetition)
            board.leavePosition(childHash);
    }

    /**
        Depth adjustment of the child node `move` leads to, `move` being the `index`-th of `moveCount` and already made.
        A negative one is a reduction, which a move improving on the best one so far gets re-searched without.
    **/
    private function moveExtension(move:Move, isTactical:Bool, index:Int, moveCount:Int, depth:Int, maxDepth:Int, childHash:Int, childVerificationKey:Int):Float
    {
        if (isTactical)
            return SearchTuning.TACTICAL_EXTENSION;

        var extension:Float = 0;
        if (history.quietVisitCount(move) >= maxDepth * maxDepth * 2)
            extension = -1 / (100 * history.quietBestRate(move) + 0.5);
        if (depth >= SearchTuning.SORTING_DEPTH && table.deepestDepth(childHash, childVerificationKey) >= SearchTuning.LATE_MOVE_REDUCTION_HASH_DEPTH)
            extension -= index / moveCount;
        return extension;
    }

    /** The line of the latest child search continued by `move` **/
    private inline function lineThrough(move:Move):Null<Array<Move>>
    {
        return budget.tracksLines() ? SearchTuning.extendLine(resultLine, move) : null;
    }

    private inline function conclude(score:Float, move:Move, line:Null<Array<Move>>, isDraw:Bool = false):Float
    {
        resultMove = move;
        resultLine = line;
        resultIsDraw = isDraw;
        return score;
    }

    private function quiesce(depth:Int, alpha:Float, beta:Float, standPatScore:Float):Float
    {
        if (Math.abs(standPatScore) > DECISIVE_THRESHOLD)
            return standPatScore;

        if (board.turn == White)
        {
            if (standPatScore >= beta)
                return standPatScore;
            if (alpha < standPatScore)
                alpha = standPatScore;

            for (move in orderedCaptures())
            {
                if (!isQuiescenceCandidate(move, depth))
                    continue;

                var score:Float = quiesceAfter(move, depth, alpha, beta, standPatScore);
                if (score >= beta)
                    return score;
                if (score > alpha)
                    alpha = score;
            }

            return alpha;
        }
        else
        {
            if (standPatScore <= alpha)
                return standPatScore;
            if (beta > standPatScore)
                beta = standPatScore;

            for (move in orderedCaptures())
            {
                if (!isQuiescenceCandidate(move, depth))
                    continue;

                var score:Float = quiesceAfter(move, depth, alpha, beta, standPatScore);
                if (score <= alpha)
                    return score;
                if (score < beta)
                    beta = score;
            }

            return beta;
        }
    }

    private inline function isQuiescenceCandidate(move:Move, depth:Int):Bool
    {
        var to:Int = move.to;
        return depth < SearchTuning.UNRESTRICTED_QUIESCENCE_DEPTH || quiescenceCaptureCounts[to] > 0 || board.pieces[to].isIntellector();
    }

    private inline function quiesceAfter(move:Move, depth:Int, alpha:Float, beta:Float, standPatScore:Float):Float
    {
        var to:Int = move.to;
        var scoreAfterCapture:Float = board.scoreAfterCapture(standPatScore, move);

        board.makeUnscoredMove(move);
        quiescenceCaptureCounts[to]++;
        var score:Float = quiesce(depth + 1, alpha, beta, scoreAfterCapture);
        quiescenceCaptureCounts[to]--;
        board.unmakeUnscoredMove();

        return score;
    }

    private function evaluate():Float
    {
        var score:Float = Evaluation.clampDecisive(board.materialScore);
        if (score < DECISIVE_THRESHOLD && score > -DECISIVE_THRESHOLD)
            score += rootMoveNoise[currentRootMoveIndex];
        return score;
    }

    private function orderedMoves(depth:Int, hash:Int, verificationKey:Int):Array<Move>
    {
        var moves:Array<Move> = MoveGenerator.generateMoves(board);
        if (depth >= SearchTuning.SORTING_DEPTH)
        {
            sortMoves(moves, hash, verificationKey);
            SearchTuning.putFirst(moves, table.bestMove(hash, verificationKey));
        }
        else
            putCapturesFirst(moves);
        return moves;
    }

    /** Captures ordered as by `orderedCaptures`, then the quiet moves in generation order **/
    private function putCapturesFirst(moves:Array<Move>):Void
    {
        var isWhite:Bool = board.turn == White;
        var quietKey:Float = isWhite ? Math.NEGATIVE_INFINITY : Math.POSITIVE_INFINITY;
        var keys:Array<Float> = [for (move in moves) board.isCapture(move) ? captureKey(move) : quietKey];
        SearchTuning.sortByKeys(moves, keys, isWhite);
    }

    /**
        Puts the most promising moves for the side to move first: immediate wins and losses,
        then moves leading to positions known from the table, then quiet moves by history, then captures.
    **/
    private function sortMoves(moves:Array<Move>, hash:Int, verificationKey:Int):Void
    {
        var isWhite:Bool = board.turn == White;
        var pieces:PieceArray = board.pieces;
        var worstScore:Float = isWhite ? BLACK_WIN_SCORE : WHITE_WIN_SCORE;
        var depthWeight:Float = isWhite ? SearchTuning.DEPTH_ORDERING_WEIGHT : -SearchTuning.DEPTH_ORDERING_WEIGHT;
        var keys:Array<Float> = [];

        for (move in moves)
        {
            var key:Float = 0;
            var hasKey:Bool = false;
            var childHash:Int = board.hashAfter(hash, move);
            var childVerificationKey:Int = board.verificationKeyAfter(verificationKey, move);

            board.makeMove(move);
            var decisiveScore:Null<Float> = board.decisiveScore();
            if (decisiveScore != null)
            {
                key = decisiveScore;
                hasKey = true;
            }
            else
            {
                var entries:Null<Array<TranspositionEntry>> = table.entriesAt(childHash, childVerificationKey);
                if (entries != null)
                {
                    var deepestDepth:Int = -1;
                    for (entry in entries)
                    {
                        if (entry.depth <= deepestDepth)
                            continue;

                        if (entry.score > entry.alpha && entry.score < entry.beta)
                        {
                            key = entry.score + entry.depth * depthWeight;
                            hasKey = true;
                        }
                        else if (isWhite && entry.score >= entry.beta)
                        {
                            key = entry.beta + entry.depth * depthWeight;
                            hasKey = true;
                        }
                        else if (!isWhite && entry.score <= entry.alpha)
                        {
                            key = entry.alpha + entry.depth * depthWeight;
                            hasKey = true;
                        }
                        deepestDepth = entry.depth;
                    }
                }
            }
            board.unmakeMove();

            if (!hasKey)
            {
                if (pieces[move.to] == Empty)
                {
                    var historyBonus:Float = history.cutoffWeight(move) / SearchTuning.HISTORY_ORDERING_DIVISOR;
                    key = isWhite ? worstScore + historyBonus : worstScore - historyBonus;
                }
                else
                    key = worstScore + (-Evaluation.PIECE_VALUES[pieces[move.to]] - Evaluation.PIECE_VALUES[pieces[move.from]]);
            }

            keys.push(key);
        }

        SearchTuning.sortByKeys(moves, keys, isWhite);
    }

    /** Captures sorted by the value of the captured piece, then by the cheapness of the capturing one **/
    private function orderedCaptures():Array<Move>
    {
        var captures:Array<Move> = MoveGenerator.generateCaptures(board);
        var keys:Array<Float> = [for (move in captures) captureKey(move)];
        SearchTuning.sortByKeys(captures, keys, board.turn == White);
        return captures;
    }

    /** Higher for white, lower for black, the more valuable the captured piece and then the cheaper the capturing one **/
    private inline function captureKey(move:Move):Float
    {
        var pieces:PieceArray = board.pieces;
        return -Evaluation.PIECE_VALUES[pieces[move.to]] - Evaluation.PIECE_VALUES[pieces[move.from]];
    }

    /** `noiseAmplitude` bounds the random offset each root move's line gets added to its evaluation **/
    public function new(board:Board, budget:B, noiseAmplitude:Float)
    {
        this.board = board;
        this.budget = budget;
        rootMoves = MoveGenerator.generateMoves(board);
        rootMoveNoise = [for (_ in rootMoves) Math.round((Math.random() - 0.5) * 2 * noiseAmplitude)];
    }
}
