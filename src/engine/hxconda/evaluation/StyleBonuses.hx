package engine.hxconda.evaluation;

import engine.hxconda.HxcondaStyle;
import engine.hxconda.board.Board;
import engine.hxconda.board.BoardGeometry.SQUARE_COUNT;
import engine.hxconda.board.BoardGeometry;
import engine.hxconda.board.Move;
import engine.hxconda.board.MoveGenerator;
import engine.hxconda.board.Piece;
import engine.hxconda.board.PlayerColor;

/**
    How much a style likes each move of the side to move, in centiprogressors for that side, on top of its search score.
    Slow: meant for the root moves only.
**/
class StyleBonuses
{
    private static inline final CHECK_BONUS:Float = 40;
    private static inline final SACRIFICE_BONUS:Float = 50;
    private static inline final PROGRESSOR_MOVE_BONUS:Float = 30;
    private static inline final FORWARD_INTELLECTOR_MOVE_BONUS:Float = 30;
    private static inline final UNDEFENDED_PIECE_PENALTY:Float = 20;
    private static inline final COUNTER_ATTACK_PENALTY:Float = 40;
    private static inline final ATTACKED_SQUARE_BONUS:Float = 3;
    private static inline final LIBERATOR_JUMP_BONUS:Float = 25;
    private static inline final SLIDE_STEP_BONUS:Float = 8;

    private final board:Board;
    private final style:HxcondaStyle;
    private final side:PlayerColor;
    private final undefendedPieceCount:Int;
    private final attackedOwnPieceCount:Int;
    private final attackedOpponentPieceCount:Int;
    private final attackedSquareCount:Int;

    public function bonus(move:Move):Float
    {
        return switch style {
            case Standard: 0;
            case Vrezh: vrezhBonus(move);
            case Trailblazer: trailblazerBonus(move);
            case Fortress: fortressBonus(move);
            case Unchained: unchainedBonus(move);
        }
    }

    /** Checks and sacrifices **/
    private function vrezhBonus(move:Move):Float
    {
        var movingPiece:Piece = board.pieces[move.from];
        var capturedValue:Float = board.isCapture(move) ? Math.abs(Evaluation.PIECE_VALUES[board.pieces[move.to]]) : 0;

        board.makeMove(move);
        var bonus:Float = board.attacksIntellector(side) ? CHECK_BONUS : 0;
        if (!movingPiece.isIntellector() && isSacrifice(move.to, capturedValue))
            bonus += SACRIFICE_BONUS;
        board.unmakeMove();

        return bonus;
    }

    /**
        Whether the piece that has just moved to `square` is attacked and losing it there costs material, net of
        `capturedValue` taken by the move: it is undefended, or an attacker is cheaper than it
    **/
    private function isSacrifice(square:Int, capturedValue:Float):Bool
    {
        var opponent:PlayerColor = side.opponent();
        if (!board.isAttackedBy(square, opponent))
            return false;

        var pieceValue:Float = Math.abs(Evaluation.PIECE_VALUES[board.pieces[square]]);
        var cheapestAttackerValue:Float = Math.POSITIVE_INFINITY;
        for (capture in MoveGenerator.generateCaptures(board))
            if (capture.to == square)
                cheapestAttackerValue = Math.min(cheapestAttackerValue, Math.abs(Evaluation.PIECE_VALUES[board.pieces[capture.from]]));

        var loss:Float = board.isAttackedBy(square, side) ? pieceValue - cheapestAttackerValue : pieceValue;
        return loss - capturedValue > 0;
    }

    /** Progressor moves and forward intellector moves **/
    private function trailblazerBonus(move:Move):Float
    {
        var movingPiece:Piece = board.pieces[move.from];
        if (movingPiece == WhiteProgressor.ofColor(side))
            return PROGRESSOR_MOVE_BONUS;

        var advance:Int = BoardGeometry.height(move.to) - BoardGeometry.height(move.from);
        if (movingPiece.isIntellector() && (side == White ? advance > 0 : advance < 0))
            return FORWARD_INTELLECTOR_MOVE_BONUS;

        return 0;
    }

    /** Defended pieces, and no counter-attacks while own pieces are attacked **/
    private function fortressBonus(move:Move):Float
    {
        board.makeMove(move);
        var bonus:Float = -UNDEFENDED_PIECE_PENALTY * (countUndefendedPieces() - undefendedPieceCount);
        if (attackedOwnPieceCount > 0 && countAttackedPieces(side) >= attackedOwnPieceCount && countAttackedPieces(side.opponent()) > attackedOpponentPieceCount)
            bonus -= COUNTER_ATTACK_PENALTY;
        board.unmakeMove();

        return bonus;
    }

    /** Attacked squares, liberator jumps and long slides **/
    private function unchainedBonus(move:Move):Float
    {
        var movingPiece:Piece = board.pieces[move.from];
        var bonus:Float = 0;

        if (movingPiece == WhiteLiberator.ofColor(side) && !BoardGeometry.areAdjacent(move.from, move.to))
            bonus += LIBERATOR_JUMP_BONUS;
        else if (movingPiece == WhiteAggressor.ofColor(side))
            bonus += SLIDE_STEP_BONUS * (BoardGeometry.rayDistance(BoardGeometry.AGGRESSOR_RAYS, BoardGeometry.AGGRESSOR_DIRECTIONS, move.from, move.to) - 1);
        else if (movingPiece == WhiteDominator.ofColor(side))
            bonus += SLIDE_STEP_BONUS * (BoardGeometry.rayDistance(BoardGeometry.DOMINATOR_RAYS, BoardGeometry.DOMINATOR_DIRECTIONS, move.from, move.to) - 1);

        board.makeMove(move);
        bonus += ATTACKED_SQUARE_BONUS * (countAttackedSquares() - attackedSquareCount);
        board.unmakeMove();

        return bonus;
    }

    /** Pieces of `side`, its intellector aside, that none of its other pieces defends **/
    private function countUndefendedPieces():Int
    {
        var count:Int = 0;
        for (square in 0...SQUARE_COUNT)
        {
            var piece:Piece = board.pieces[square];
            if (piece != Empty && piece.color() == side && !piece.isIntellector() && !board.isAttackedBy(square, side))
                count++;
        }
        return count;
    }

    /** Pieces of `victim` under attack: its intellector counts as attacked by the side, not by the opponent **/
    private function countAttackedPieces(victim:PlayerColor):Int
    {
        var count:Int = 0;
        for (square in 0...SQUARE_COUNT)
        {
            var piece:Piece = board.pieces[square];
            if (piece != Empty && piece.color() == victim && (victim != side || !piece.isIntellector()) && board.isAttackedBy(square, victim.opponent()))
                count++;
        }
        return count;
    }

    private function countAttackedSquares():Int
    {
        var count:Int = 0;
        for (square in 0...SQUARE_COUNT)
            if (board.isAttackedBy(square, side))
                count++;
        return count;
    }

    /** Bonuses for the moves of the side to move on `board`, which has to stay in this position between the calls **/
    public function new(board:Board, style:HxcondaStyle)
    {
        this.board = board;
        this.style = style;
        side = board.turn;
        undefendedPieceCount = style == Fortress ? countUndefendedPieces() : 0;
        attackedOwnPieceCount = style == Fortress ? countAttackedPieces(side) : 0;
        attackedOpponentPieceCount = style == Fortress ? countAttackedPieces(side.opponent()) : 0;
        attackedSquareCount = style == Unchained ? countAttackedSquares() : 0;
    }
}
