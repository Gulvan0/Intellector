package engine.hxconda.board;

import engine.hxconda.board.BoardGeometry.NO_SQUARE;
import engine.hxconda.board.BoardGeometry.SQUARE_COUNT;
import engine.hxconda.evaluation.Evaluation;
import js.lib.Map;

/**
    Mutable position the search runs on, with the stack of moves to undo and the visit counts of the positions on the current line.
**/
class Board
{
    private static inline final DEFAULT_STARTING_NOTATION:String = "mpeeePMleeeeLapeeePAdeeeeDipeeePIdeeeeDapeeePAleeeeLmpeeePMw";

    public final pieces:Array<Piece>;
    public final zobristKeys:ZobristKeys;
    public var turn(default, null):PlayerColor = White;
    public var whiteIntellectorSquare(default, null):Int = NO_SQUARE;
    public var blackIntellectorSquare(default, null):Int = NO_SQUARE;
    /**
        Sum of `Evaluation.pieceSquareScore` over the board, stale while moves made by `makeUnscoredMove` are on it.
        Kept up to date incrementally, which is exact: every piece-square score is a multiple of 0.5, far below 2^52.
    **/
    public var materialScore(default, null):Float = 0;

    private final undoStack:Array<Int> = [];
    private final visitCounts:Map<Int, Int> = new Map();

    public inline function intellectorSquare(color:PlayerColor):Int
    {
        return color == White ? whiteIntellectorSquare : blackIntellectorSquare;
    }

    public function hash():Int
    {
        var hash:Int = turn == Black ? zobristKeys.blackToMove : 0;
        for (square in 0...SQUARE_COUNT)
            hash ^= zobristKeys.of(square, pieces[square]);
        return hash;
    }

    /** Hash of the position `move` leads to, given `hash` of the current one **/
    public function hashAfter(hash:Int, move:Move):Int
    {
        var from:Int = move.from;
        var to:Int = move.to;
        var movingPiece:Piece = pieces[from];
        var targetPiece:Piece = pieces[to];
        var pieceLeftBehind:Piece = isCastling(movingPiece, targetPiece) ? targetPiece : Empty;

        return hash
            ^ zobristKeys.blackToMove
            ^ zobristKeys.of(from, movingPiece)
            ^ zobristKeys.of(to, targetPiece)
            ^ zobristKeys.of(from, pieceLeftBehind)
            ^ zobristKeys.of(to, move.resultingPiece);
    }

    public inline function hashAfterPass(hash:Int):Int
    {
        return hash ^ zobristKeys.blackToMove;
    }

    public function makeMove(move:Move):Void
    {
        applyMove(move, true);
    }

    /** `makeMove` without updating `materialScore`, for lines that track the score on their own **/
    public function makeUnscoredMove(move:Move):Void
    {
        applyMove(move, false);
    }

    public function unmakeMove():Void
    {
        revertMove(true);
    }

    /** Reverts `makeUnscoredMove` **/
    public function unmakeUnscoredMove():Void
    {
        revertMove(false);
    }

    private inline function applyMove(move:Move, updatesScore:Bool):Void
    {
        var from:Int = move.from;
        var to:Int = move.to;
        var movingPiece:Piece = pieces[from];
        var targetPiece:Piece = pieces[to];
        var resultingPiece:Piece = move.resultingPiece;

        undoStack.push(from | (to << 6) | (movingPiece << 12) | (targetPiece << 16));

        if (resultingPiece == WhiteIntellector)
            whiteIntellectorSquare = to;
        else if (resultingPiece == BlackIntellector)
            blackIntellectorSquare = to;

        if (targetPiece == WhiteIntellector)
            whiteIntellectorSquare = NO_SQUARE;
        else if (targetPiece == BlackIntellector)
            blackIntellectorSquare = NO_SQUARE;

        if (isCastling(movingPiece, targetPiece))
        {
            pieces[from] = targetPiece;
            pieces[to] = movingPiece;
        }
        else
        {
            pieces[from] = Empty;
            pieces[to] = resultingPiece;
        }

        if (updatesScore)
            materialScore += squarePairScore(from, pieces[from], to, pieces[to]) - squarePairScore(from, movingPiece, to, targetPiece);

        turn = turn.opponent();
    }

    private inline function revertMove(updatesScore:Bool):Void
    {
        var record:Int = undoStack.pop();
        var from:Int = record & 63;
        var to:Int = (record >> 6) & 63;
        var movedPiece:Piece = cast (record >> 12) & 15;
        var targetPiece:Piece = cast record >> 16;

        if (updatesScore)
            materialScore += squarePairScore(from, movedPiece, to, targetPiece) - squarePairScore(from, pieces[from], to, pieces[to]);

        pieces[from] = movedPiece;
        pieces[to] = targetPiece;

        if (movedPiece == WhiteIntellector)
            whiteIntellectorSquare = from;
        else if (movedPiece == BlackIntellector)
            blackIntellectorSquare = from;

        if (targetPiece == WhiteIntellector)
            whiteIntellectorSquare = to;
        else if (targetPiece == BlackIntellector)
            blackIntellectorSquare = to;

        turn = turn.opponent();
    }

    public inline function passTurn():Void
    {
        turn = turn.opponent();
    }

    /** Counts a visit of the position with `hash`; zero hashes go uncounted **/
    public inline function enterPosition(hash:Int):Void
    {
        if (hash != 0)
            visitCounts.set(hash, visitCount(hash) + 1);
    }

    /** Reverts `enterPosition` **/
    public inline function leavePosition(hash:Int):Void
    {
        if (hash != 0)
        {
            var count:Int = visitCount(hash);
            if (count == 1)
                visitCounts.delete(hash);
            else
                visitCounts.set(hash, count - 1);
        }
    }

    public inline function visitCount(hash:Int):Int
    {
        return visitCounts.get(hash) ?? 0;
    }

    /** Whether `move` takes a piece; intellector-defensor castling does not **/
    public inline function isCapture(move:Move):Bool
    {
        return pieces[move.to] != Empty && !pieces[move.from].isIntellector();
    }

    /** Whether the intellector of the side to move is under attack **/
    public function isIntellectorAttacked():Bool
    {
        if (whiteIntellectorSquare == NO_SQUARE || blackIntellectorSquare == NO_SQUARE)
            return false;

        var square:Int = intellectorSquare(turn);
        var attacker:PlayerColor = turn.opponent();
        var progressorSteps:SquareLists = attacker == White ? BoardGeometry.BLACK_PROGRESSOR_STEPS : BoardGeometry.WHITE_PROGRESSOR_STEPS;

        return isReachedByStep(square, BoardGeometry.NEIGHBOURS, WhiteDefensor.ofColor(attacker))
            || isReachedByStep(square, BoardGeometry.LIBERATOR_JUMPS, WhiteLiberator.ofColor(attacker))
            || isReachedByStep(square, progressorSteps, WhiteProgressor.ofColor(attacker))
            || isReachedBySlide(square, BoardGeometry.AGGRESSOR_RAYS, WhiteAggressor.ofColor(attacker))
            || isReachedBySlide(square, BoardGeometry.DOMINATOR_RAYS, WhiteDominator.ofColor(attacker));
    }

    /** Score of a won position, null while the game goes on **/
    public function decisiveScore():Null<Float>
    {
        if (whiteIntellectorSquare == NO_SQUARE)
            return Evaluation.BLACK_WIN_SCORE;
        if (blackIntellectorSquare == NO_SQUARE)
            return Evaluation.WHITE_WIN_SCORE;
        if (BoardGeometry.isFinalSquare(whiteIntellectorSquare, White))
            return Evaluation.WHITE_WIN_SCORE;
        if (BoardGeometry.isFinalSquare(blackIntellectorSquare, Black))
            return Evaluation.BLACK_WIN_SCORE;
        return null;
    }

    private static inline function squarePairScore(square:Int, piece:Piece, otherSquare:Int, otherPiece:Piece):Float
    {
        return Evaluation.pieceSquareScore(piece, square) + Evaluation.pieceSquareScore(otherPiece, otherSquare);
    }

    private function computeMaterialScore():Float
    {
        var score:Float = 0;
        for (square in 0...SQUARE_COUNT)
        {
            var piece:Piece = pieces[square];
            if (piece != Empty)
                score += Evaluation.pieceSquareScore(piece, square);
        }
        return score;
    }

    /** `score` updated incrementally for the capture `move`, clamped like a full evaluation **/
    public inline function scoreAfterCapture(score:Float, move:Move):Float
    {
        var from:Int = move.from;
        var to:Int = move.to;
        score -= Evaluation.pieceSquareScore(pieces[from], from);
        score -= Evaluation.pieceSquareScore(pieces[to], to);
        score += Evaluation.pieceSquareScore(move.resultingPiece, to);
        return Evaluation.clampDecisive(score);
    }

    private static inline function isCastling(movingPiece:Piece, targetPiece:Piece):Bool
    {
        return movingPiece == WhiteIntellector && targetPiece == WhiteDefensor || movingPiece == BlackIntellector && targetPiece == BlackDefensor;
    }

    private function isReachedByStep(square:Int, steps:SquareLists, attackingPiece:Piece):Bool
    {
        var squares:Array<Int> = steps.squares;
        for (k in steps.start(square)...steps.end(square))
            if (pieces[squares[k]] == attackingPiece)
                return true;
        return false;
    }

    private function isReachedBySlide(square:Int, rays:SquareLists, attackingPiece:Piece):Bool
    {
        var squares:Array<Int> = rays.squares;
        for (direction in 0...BoardGeometry.DIRECTION_COUNT)
        {
            var ray:Int = square * BoardGeometry.DIRECTION_COUNT + direction;
            for (k in rays.start(ray)...rays.end(ray))
            {
                var piece:Piece = pieces[squares[k]];
                if (piece == attackingPiece)
                    return true;
                if (piece != Empty)
                    break;
            }
        }
        return false;
    }

    /** Fills the board from the Anaconda notation; returns false if `notation` is malformed **/
    private function trySetFromNotation(notation:String):Bool
    {
        if (notation.length != SQUARE_COUNT + 1)
            return false;

        var whiteIntellectorCount:Int = 0;
        var blackIntellectorCount:Int = 0;
        whiteIntellectorSquare = NO_SQUARE;
        blackIntellectorSquare = NO_SQUARE;

        for (square in 0...SQUARE_COUNT)
        {
            var piece:Null<Piece> = Piece.fromLetter(notation.charAt(square));
            if (piece == null)
                return false;

            pieces[square] = piece;
            if (piece == WhiteIntellector)
            {
                whiteIntellectorSquare = square;
                whiteIntellectorCount++;
            }
            else if (piece == BlackIntellector)
            {
                blackIntellectorSquare = square;
                blackIntellectorCount++;
            }
        }

        if (whiteIntellectorCount > 1 || blackIntellectorCount > 1)
            return false;

        switch notation.charAt(SQUARE_COUNT)
        {
            case "w":
                turn = White;
            case "b":
                turn = Black;
            default:
                return false;
        }

        return true;
    }

    /**
        Parses the Anaconda notation: 59 piece letters from a1 to i7 (`e` for an empty square), then the turn letter, `w` or `b`.
        Falls back to the default starting position if `notation` is missing or malformed.
    **/
    public function new(notation:Null<String>)
    {
        zobristKeys = new ZobristKeys();
        pieces = [for (_ in 0...SQUARE_COUNT) Empty];

        if (notation == null || !trySetFromNotation(notation))
            trySetFromNotation(DEFAULT_STARTING_NOTATION);

        materialScore = computeMaterialScore();
        visitCounts.set(hash(), 1);
    }
}
