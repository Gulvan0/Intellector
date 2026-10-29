package engine.hxconda.board;

import engine.hxconda.board.BoardGeometry.NO_DIRECTION;
import engine.hxconda.board.BoardGeometry.NO_SQUARE;
import engine.hxconda.board.BoardGeometry.SQUARE_COUNT;
import engine.hxconda.evaluation.Evaluation;
import js.lib.Int32Array;
import js.lib.Int8Array;

/**
    Mutable position the search runs on, with the stack of moves to undo and the visit counts of the positions on the current line.
**/
class Board
{
    private static inline final DEFAULT_STARTING_NOTATION:String = "mpeeePMleeeeLapeeePAdeeeeDipeeePIdeeeeDapeeePAleeeeLmpeeePMw";

    public final pieces:PieceArray;
    public final zobristKeys:ZobristKeys;
    public var turn(default, null):PlayerColor = White;
    public var whiteIntellectorSquare(default, null):Int = NO_SQUARE;
    public var blackIntellectorSquare(default, null):Int = NO_SQUARE;
    /**
        Sum of `Evaluation.pieceSquareScore` over the board, stale while moves made by `makeUnscoredMove` are on it.
        Kept up to date incrementally, which is exact: every piece-square score is a multiple of 0.5, far below 2^52.
    **/
    public var materialScore(default, null):Float = 0;

    /** Bit `square & 31` of entry `color * 2 + (square >> 5)` is set while a piece of `color` stands on `square` **/
    private final occupancyMasks:Int32Array = new Int32Array(4);
    private final undoStack:Array<Int> = [];
    private final visitCounts:VisitCounts = new VisitCounts();

    public inline function intellectorSquare(color:PlayerColor):Int
    {
        return color == White ? whiteIntellectorSquare : blackIntellectorSquare;
    }

    /** The squares of `color`'s pieces among 0-31 (`half` 0) or 32-58 (`half` 1), as bits `square & 31` **/
    public inline function occupancyMask(color:PlayerColor, half:Int):Int
    {
        return occupancyMasks[color * 2 + half];
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
            pieces[from] = Piece.Empty;
            pieces[to] = resultingPiece;
            toggleMoveOccupancy(from, to, movingPiece, targetPiece);
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

        if (!isCastling(movedPiece, targetPiece))
            toggleMoveOccupancy(from, to, movedPiece, targetPiece);

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
            visitCounts.increment(hash);
    }

    /** Reverts `enterPosition` **/
    public inline function leavePosition(hash:Int):Void
    {
        if (hash != 0)
            visitCounts.decrement(hash);
    }

    public inline function visitCount(hash:Int):Int
    {
        return visitCounts.count(hash);
    }

    /** Whether `move` takes a piece; intellector-defensor castling does not **/
    public inline function isCapture(move:Move):Bool
    {
        return pieces[move.to] != Empty && !pieces[move.from].isIntellector();
    }

    /** Whether the intellector of the side to move is under attack **/
    public inline function isIntellectorAttacked():Bool
    {
        return attacksIntellector(turn.opponent());
    }

    /** Whether `attacker` attacks the intellector of its opponent **/
    public function attacksIntellector(attacker:PlayerColor):Bool
    {
        if (whiteIntellectorSquare == NO_SQUARE || blackIntellectorSquare == NO_SQUARE)
            return false;

        var square:Int = intellectorSquare(attacker.opponent());
        var progressorSteps:SquareLists = attacker == White ? BoardGeometry.BLACK_PROGRESSOR_STEPS : BoardGeometry.WHITE_PROGRESSOR_STEPS;

        return isReachedByStep(square, BoardGeometry.NEIGHBOURS, WhiteDefensor.ofColor(attacker))
            || isReachedByStep(square, BoardGeometry.LIBERATOR_JUMPS, WhiteLiberator.ofColor(attacker))
            || isReachedByStep(square, progressorSteps, WhiteProgressor.ofColor(attacker))
            || isReachedBySlide(square, BoardGeometry.AGGRESSOR_RAYS, WhiteAggressor.ofColor(attacker))
            || isReachedBySlide(square, BoardGeometry.DOMINATOR_RAYS, WhiteDominator.ofColor(attacker));
    }

    /**
        `isIntellectorAttacked` right after making `move`, provided that the side that made it attacked no intellector before.
        Then only the moved piece and the lines through its vacated square can attack.
    **/
    public function isIntellectorAttackedAfter(move:Move):Bool
    {
        if (whiteIntellectorSquare == NO_SQUARE || blackIntellectorSquare == NO_SQUARE)
            return false;

        var square:Int = intellectorSquare(turn);
        var attacker:PlayerColor = turn.opponent();
        var from:Int = move.from;
        var to:Int = move.to;

        if (pieces[from] != Empty) // castling, which leaves the defensor on `from` and no square vacated
            return isReachedByStepFrom(square, BoardGeometry.NEIGHBOURS, WhiteDefensor.ofColor(attacker), from);

        var progressorSteps:SquareLists = attacker == White ? BoardGeometry.BLACK_PROGRESSOR_STEPS : BoardGeometry.WHITE_PROGRESSOR_STEPS;
        var dominator:Piece = WhiteDominator.ofColor(attacker);
        var aggressor:Piece = WhiteAggressor.ofColor(attacker);

        return isReachedByStepFrom(square, BoardGeometry.NEIGHBOURS, WhiteDefensor.ofColor(attacker), to)
            || isReachedByStepFrom(square, BoardGeometry.LIBERATOR_JUMPS, WhiteLiberator.ofColor(attacker), to)
            || isReachedByStepFrom(square, progressorSteps, WhiteProgressor.ofColor(attacker), to)
            || isReachedBySlideThrough(square, to, BoardGeometry.DOMINATOR_RAYS, BoardGeometry.DOMINATOR_DIRECTIONS, dominator)
            || isReachedBySlideThrough(square, to, BoardGeometry.AGGRESSOR_RAYS, BoardGeometry.AGGRESSOR_DIRECTIONS, aggressor)
            || isReachedBySlideThrough(square, from, BoardGeometry.DOMINATOR_RAYS, BoardGeometry.DOMINATOR_DIRECTIONS, dominator)
            || isReachedBySlideThrough(square, from, BoardGeometry.AGGRESSOR_RAYS, BoardGeometry.AGGRESSOR_DIRECTIONS, aggressor);
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

    /** Updates `occupancyMasks` for a non-castling move, or reverts that update **/
    private inline function toggleMoveOccupancy(from:Int, to:Int, movingPiece:Piece, targetPiece:Piece):Void
    {
        toggleOccupancy(from, movingPiece.color());
        toggleOccupancy(to, movingPiece.color());
        if (targetPiece != Empty)
            toggleOccupancy(to, targetPiece.color());
    }

    private inline function toggleOccupancy(square:Int, color:PlayerColor):Void
    {
        occupancyMasks[color * 2 + (square >> 5)] ^= 1 << (square & 31);
    }

    private static inline function isCastling(movingPiece:Piece, targetPiece:Piece):Bool
    {
        return movingPiece == WhiteIntellector && targetPiece == WhiteDefensor || movingPiece == BlackIntellector && targetPiece == BlackDefensor;
    }

    private function isReachedByStep(square:Int, steps:SquareLists, attackingPiece:Piece):Bool
    {
        var squares:Int8Array = steps.squares;
        for (k in steps.start(square)...steps.end(square))
            if (pieces[squares[k]] == attackingPiece)
                return true;
        return false;
    }

    /** Whether `attackingPiece` stands on `origin`, one of `square`'s list in `steps` **/
    private inline function isReachedByStepFrom(square:Int, steps:SquareLists, attackingPiece:Piece, origin:Int):Bool
    {
        var isReached:Bool = false;
        if (pieces[origin] == attackingPiece)
        {
            var squares:Int8Array = steps.squares;
            for (k in steps.start(square)...steps.end(square))
                if (squares[k] == origin)
                    isReached = true;
        }
        return isReached;
    }

    /** Whether `attackingPiece` is the first piece on the ray in `rays` from `square` through `throughSquare` **/
    private function isReachedBySlideThrough(square:Int, throughSquare:Int, rays:SquareLists, directions:Int8Array, attackingPiece:Piece):Bool
    {
        var direction:Int = BoardGeometry.rayDirection(directions, square, throughSquare);
        if (direction == NO_DIRECTION)
            return false;

        var squares:Int8Array = rays.squares;
        var ray:Int = square * BoardGeometry.DIRECTION_COUNT + direction;
        for (k in rays.start(ray)...rays.end(ray))
        {
            var piece:Piece = pieces[squares[k]];
            if (piece != Empty)
                return piece == attackingPiece;
        }
        return false;
    }

    private function isReachedBySlide(square:Int, rays:SquareLists, attackingPiece:Piece):Bool
    {
        var squares:Int8Array = rays.squares;
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

        for (i in 0...occupancyMasks.length)
            occupancyMasks[i] = 0;

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
            if (piece != Empty)
                toggleOccupancy(square, piece.color());

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
        pieces = new PieceArray(SQUARE_COUNT);

        if (notation == null || !trySetFromNotation(notation))
            trySetFromNotation(DEFAULT_STARTING_NOTATION);

        materialScore = computeMaterialScore();
        visitCounts.increment(hash());
    }
}
