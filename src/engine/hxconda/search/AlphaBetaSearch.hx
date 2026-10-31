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
    extensions for captures and checks, history-based reductions and a quiescence search of captures, and of evasions at leaves in check.
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
    /** Per ply from the root, the two latest distinct quiet moves that caused a cutoff there, the latest first **/
    private final killers:Array<Move> = [for (_ in 0...2 * SearchTuning.KILLER_PLY_COUNT) Move.NONE];
    /** Distance of the current node from the root, in moves made by the main search **/
    private var ply:Int = 0;

    // Outcome of the latest completed `search()` call, besides its returned score
    private var resultMove:Move = Move.NONE;
    private var resultMoveIsQuiet:Bool = false;
    private var resultLine:Null<Array<Move>> = null;
    /** Whether the score comes from a repetition draw, which depends on the line and is kept out of the table **/
    private var resultIsDraw:Bool = false;
    /** Whether a node ran out of budget, which leaves the scores of all unfinished nodes meaningless **/
    private var isAborted:Bool = false;
    /** Set right before searching the child of a null move, and consumed by that search **/
    private var isNullMoveChild:Bool = false;

    /** In a stalemate, where the side to move has no legal moves and loses, the report has no move and that side's losing score **/
    public function run():BestMoveReport
    {
        if (rootMoves.length == 0 && board.decisiveScore() == null)
        {
            report.record(Move.NONE, board.turn == White ? BLACK_WIN_SCORE : WHITE_WIN_SCORE, 0, 0);
            return report;
        }

        var rootHash:Int = board.hash();
        var rootVerificationKey:Int = board.verificationKey();
        var rootIsInCheck:Bool = board.isIntellectorAttacked();
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

            var score:Float = search(alpha, beta, iteration, 0, iteration, rootHash, rootVerificationKey, true, rootIsInCheck);
            if (score <= alpha)
                score = search(Math.NEGATIVE_INFINITY, alpha + 1, iteration, 0, iteration, rootHash, rootVerificationKey, true, rootIsInCheck);
            else if (score >= beta)
                score = search(beta - 1, Math.POSITIVE_INFINITY, iteration, 0, iteration, rootHash, rootVerificationKey, true, rootIsInCheck);

            expectedScore = score;
            if (resultMove == Move.NONE)
                score = search(Math.NEGATIVE_INFINITY, Math.POSITIVE_INFINITY, iteration, 0, iteration, rootHash, rootVerificationKey, true, rootIsInCheck);

            if (budget.hasRemaining() || iteration == 1)
                report.record(resultMove, score, iteration, rootMoves.length);

            budget.onIterationCompleted(report);

            if (report.move == Move.NONE)
                throw "Anaconda found no move to play";

            iteration++;
        }

        return report;
    }

    /**
        `verificationKey` is the position's `Board.verificationKey()`, needed only at depths that reach the table.
        `isInCheck` tells whether the side to move's intellector is attacked.
    **/
    private function search(alpha:Float, beta:Float, depth:Int, extension:Float, maxDepth:Int, hash:Int, verificationKey:Int, isRoot:Bool, isInCheck:Bool):Float
    {
        var followsNullMove:Bool = isNullMoveChild;
        isNullMoveChild = false;

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

        if (depth == SearchTuning.NULL_MOVE_DEPTH && !isRoot && !isInCheck && !followsNullMove) // a pruned root has no move; passing in check loses at once
        {
            board.passTurn();
            var passedIsInCheck:Bool = board.isIntellectorAttacked();
            var passedHash:Int = board.hashAfterPass(hash);
            var passedVerificationKey:Int = board.verificationKeyAfterPass(verificationKey);
            var isPruned:Bool = false;
            var nullMoveScore:Float = 0;
            var nullMoveScoreIsDraw:Bool = false;
            if (board.turn == Black && beta < Math.POSITIVE_INFINITY)
            {
                nullMoveScore = search(beta - 1, beta, depth - 1, extension, maxDepth, passedHash, passedVerificationKey, false, passedIsInCheck);
                isPruned = nullMoveScore >= beta;
                nullMoveScoreIsDraw = resultIsDraw;
            }
            else if (board.turn == White && alpha > Math.NEGATIVE_INFINITY)
            {
                nullMoveScore = search(alpha, alpha + 1, depth - 1, extension, maxDepth, passedHash, passedVerificationKey, false, passedIsInCheck);
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

        if (depth >= SearchTuning.NULL_MOVE_PRUNING_DEPTH && !isRoot && !isInCheck && !followsNullMove && board.hasPromotionKindPiece(board.turn))
        {
            var nullMoveScore:Null<Float> = nullMovePruningScore(alpha, beta, depth, extension, maxDepth, hash, verificationKey);
            if (nullMoveScore != null)
                return nullMoveScore;
        }

        if (depth < 1)
            return conclude(isInCheck ? quiesceInCheck(alpha, beta, evaluate()) : quiesce(0, alpha, beta, evaluate()), Move.NONE, null);

        var score:Float = board.turn == White
            ? searchMovesAsMaximizer(alpha, beta, depth, extension, maxDepth, hash, verificationKey, isRoot)
            : searchMovesAsMinimizer(alpha, beta, depth, extension, maxDepth, hash, verificationKey, isRoot);

        if (resultMove != Move.NONE && resultMoveIsQuiet)
            history.recordQuietBest(resultMove);

        if (depth >= SearchTuning.HASHING_DEPTH && !resultIsDraw && !isAborted)
            table.store(hash, verificationKey, alpha, beta, resultMove, score, depth);

        return score;
    }

    /**
        The score to return if passing, searched at a reduced depth, still reaches the bound of the side to move; null otherwise.
        Tried only if the static evaluation already reaches it. A decisive score after the pass is replaced by the bound,
        since a pass is no legal move to win or lose by.
    **/
    private function nullMovePruningScore(alpha:Float, beta:Float, depth:Int, extension:Float, maxDepth:Int, hash:Int, verificationKey:Int):Null<Float>
    {
        var isWhite:Bool = board.turn == White;
        var staticScore:Float = evaluate();
        if (isWhite ? beta > DECISIVE_THRESHOLD || staticScore < beta : alpha < -DECISIVE_THRESHOLD || staticScore > alpha)
            return null;

        var reduction:Int = SearchTuning.NULL_MOVE_REDUCTION + (depth >= SearchTuning.NULL_MOVE_DEEP_DEPTH ? 1 : 0);
        board.passTurn();
        ply++;
        var passedIsInCheck:Bool = board.isIntellectorAttacked();
        var passedHash:Int = board.hashAfterPass(hash);
        var passedVerificationKey:Int = board.verificationKeyAfterPass(verificationKey);
        isNullMoveChild = true;
        var score:Float = isWhite
            ? search(beta - 1, beta, depth - 1 - reduction, extension, maxDepth, passedHash, passedVerificationKey, false, passedIsInCheck)
            : search(alpha, alpha + 1, depth - 1 - reduction, extension, maxDepth, passedHash, passedVerificationKey, false, passedIsInCheck);
        var scoreIsDraw:Bool = resultIsDraw;
        ply--;
        board.passTurn();

        if (isWhite ? score < beta : score > alpha)
            return null;

        var isDecisive:Bool = Math.abs(score) > DECISIVE_THRESHOLD;
        return conclude(isDecisive ? (isWhite ? beta : alpha) : score, Move.NONE, null, scoreIsDraw && !isDecisive);
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
                score = search(alpha, alpha + 1, depth - 1, childExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
                line = lineThrough(move);
                if (score > alpha && isReduced)
                {
                    score = search(alpha, alpha + 1, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
                    line = lineThrough(move);
                }
                if (score >= alpha + 1 && score < beta)
                {
                    score = search(score - 1, beta, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
                    line = lineThrough(move);
                }
            }
            else
            {
                score = search(alpha, beta, depth - 1, childExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
                line = lineThrough(move);
                if (score > alpha && isReduced)
                {
                    score = search(alpha, beta, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
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
                {
                    history.recordCutoff(move, depth);
                    recordKiller(move);
                }
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
                score = search(beta - 1, beta, depth - 1, childExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
                line = lineThrough(move);
                if (score < beta && isReduced)
                {
                    score = search(beta - 1, beta, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
                    line = lineThrough(move);
                }
                if (score > alpha && score <= beta - 1)
                {
                    score = search(alpha, score + 1, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
                    line = lineThrough(move);
                }
            }
            else
            {
                score = search(alpha, beta, depth - 1, childExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
                line = lineThrough(move);
                if (score < beta && isReduced)
                {
                    score = search(alpha, beta, depth - 1, unreducedExtension, maxDepth, childHash, childVerificationKey, false, isCheck);
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
                {
                    history.recordCutoff(move, depth);
                    recordKiller(move);
                }
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
        ply++;
        if (tracksRepetition)
            board.enterPosition(childHash);
    }

    private inline function unmakeSearchedMove(childHash:Int, tracksRepetition:Bool):Void
    {
        board.unmakeMove();
        ply--;
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

    /**
        Quiescence search of a main search leaf whose side to move has its intellector attacked: no standing pat while an evasion exists.
        Deeper quiescence plies stand pat in check, since searching their evasions costs more than it gains.
    **/
    private function quiesceInCheck(alpha:Float, beta:Float, standPatScore:Float):Float
    {
        if (Math.abs(standPatScore) > DECISIVE_THRESHOLD)
            return standPatScore;

        return quiesceEvasions(alpha, beta, standPatScore) ?? quiesce(0, alpha, beta, standPatScore);
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

                var score:Float = quiesceAfter(move, depth, alpha, beta, board.scoreAfterCapture(standPatScore, move));
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

                var score:Float = quiesceAfter(move, depth, alpha, beta, board.scoreAfterCapture(standPatScore, move));
                if (score <= alpha)
                    return score;
                if (score < beta)
                    beta = score;
            }

            return beta;
        }
    }

    /**
        Best score over the captures and intellector moves that leave the own intellector unattacked,
        or null if there are none: quiet blocks aren't generated, so the node can't be proven lost then.
    **/
    private function quiesceEvasions(alpha:Float, beta:Float, standPatScore:Float):Null<Float>
    {
        var isWhite:Bool = board.turn == White;
        var winScore:Float = isWhite ? WHITE_WIN_SCORE : BLACK_WIN_SCORE;
        var intellectorSquare:Int = board.intellectorSquare(board.turn);
        var moves:Array<Move> = orderedCaptures();
        MoveGenerator.addIntellectorMovesOfSideToMove(moves, board);

        var value:Null<Float> = null;
        for (move in moves)
        {
            if (move.from == intellectorSquare && BoardGeometry.isFinalSquare(move.to, board.turn))
                return winScore;

            board.makeUnscoredMove(move);
            var isLegal:Bool = !board.attacksIntellector(board.turn);
            board.unmakeUnscoredMove();
            if (!isLegal)
                continue;

            var score:Float = quiesceAfter(move, 0, alpha, beta, board.scoreAfterMove(standPatScore, move));
            if (isWhite)
            {
                if (value == null || score > value)
                    value = score;
                if (score >= beta)
                    return score;
                if (score > alpha)
                    alpha = score;
            }
            else
            {
                if (value == null || score < value)
                    value = score;
                if (score <= alpha)
                    return score;
                if (score < beta)
                    beta = score;
            }
        }

        return value;
    }

    private inline function isQuiescenceCandidate(move:Move, depth:Int):Bool
    {
        var to:Int = move.to;
        return depth < SearchTuning.UNRESTRICTED_QUIESCENCE_DEPTH || quiescenceCaptureCounts[to] > 0 || board.pieces[to].isIntellector();
    }

    /** Quiescence score after `move`, `scoreAfterMove` being the score it leads to **/
    private inline function quiesceAfter(move:Move, depth:Int, alpha:Float, beta:Float, scoreAfterMove:Float):Float
    {
        var to:Int = move.to;

        board.makeUnscoredMove(move);
        quiescenceCaptureCounts[to]++;
        var score:Float = quiesce(depth + 1, alpha, beta, scoreAfterMove);
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
            sortMoves(moves);
            SearchTuning.putFirst(moves, table.bestMove(hash, verificationKey));
        }
        else
            orderShallowMoves(moves);
        return moves;
    }

    /** Captures ordered as by `orderedCaptures`, then the killer moves, then the other quiet moves in generation order **/
    private function orderShallowMoves(moves:Array<Move>):Void
    {
        var isWhite:Bool = board.turn == White;
        var keys:Array<Float> = [for (move in moves) board.isCapture(move) ? captureKey(move) : quietKey(move, isWhite)];
        SearchTuning.sortByKeys(moves, keys, isWhite);
    }

    private inline function quietKey(move:Move, isWhite:Bool):Float
    {
        var rank:Int = killerRank(move);
        if (rank == 0)
            rank = 3;
        return isWhite ? -rank * SearchTuning.KILLER_ORDERING_STEP : rank * SearchTuning.KILLER_ORDERING_STEP;
    }

    /** 1 for the latest killer move of the current ply, 2 for the other one, 0 for any other move **/
    private inline function killerRank(move:Move):Int
    {
        var killerSlot:Int = 2 * ply;
        return ply >= SearchTuning.KILLER_PLY_COUNT ? 0 : move == killers[killerSlot] ? 1 : move == killers[killerSlot + 1] ? 2 : 0;
    }

    private inline function recordKiller(move:Move):Void
    {
        var killerSlot:Int = 2 * ply;
        if (ply < SearchTuning.KILLER_PLY_COUNT && killers[killerSlot] != move)
        {
            killers[killerSlot + 1] = killers[killerSlot];
            killers[killerSlot] = move;
        }
    }

    /**
        Puts the most promising moves for the side to move first: immediate wins, captures that don't lose material by their gain,
        killer moves, the other quiet moves by history, then the other captures.
    **/
    private function sortMoves(moves:Array<Move>):Void
    {
        var keys:Array<Float> = [for (move in moves) orderingKey(move)];
        SearchTuning.sortByKeys(moves, keys, true);
    }

    /** Ordering key of `move` for the side to move, higher first **/
    private function orderingKey(move:Move):Float
    {
        var pieces:PieceArray = board.pieces;
        var movingPiece:Piece = pieces[move.from];
        if (movingPiece.isIntellector() && BoardGeometry.isFinalSquare(move.to, board.turn))
            return SearchTuning.WINNING_MOVE_ORDERING_KEY;

        if (board.isCapture(move))
        {
            var gain:Float = Math.abs(Evaluation.PIECE_VALUES[pieces[move.to]]) - Math.abs(Evaluation.PIECE_VALUES[movingPiece]);
            return gain >= 0 ? SearchTuning.CAPTURE_ORDERING_KEY + gain : -SearchTuning.CAPTURE_ORDERING_KEY + gain;
        }

        var killerRank:Int = killerRank(move);
        if (killerRank > 0)
            return SearchTuning.KILLER_ORDERING_STEP * (3 - killerRank);

        return history.cutoffWeight(move) / SearchTuning.HISTORY_ORDERING_DIVISOR;
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
