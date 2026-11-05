package engine.hxconda.evaluation;

import engine.hxconda.HxcondaStyle;
import engine.hxconda.board.BoardGeometry.SQUARE_COUNT;
import engine.hxconda.board.BoardGeometry;
import engine.hxconda.board.Piece;
import engine.hxconda.board.PlayerColor;
import js.lib.Float64Array;

/**
    Static evaluation terms. Scores are from white's perspective: positive favours white.
    The tables follow the style set by `useStyle`, `Standard` until then.
**/
class Evaluation
{
    public static inline final WHITE_WIN_SCORE:Float = 100000;
    public static inline final BLACK_WIN_SCORE:Float = -100000;
    /** Scores beyond `±DECISIVE_THRESHOLD` mean that one of the sides wins **/
    public static inline final DECISIVE_THRESHOLD:Float = 90000;
    public static inline final DRAW_SCORE:Float = 0;

    private static inline final MOBILITY_WEIGHT:Float = 5;
    private static inline final CENTRALITY_WEIGHT:Float = 5;
    /** Multiplier of Trailblazer's progressor and intellector advancement bonuses **/
    private static inline final TRAILBLAZER_ADVANCEMENT_FACTOR:Float = 1.5;
    /** How much Fortress likes and Vrezh dislikes a draw, from the side the bot plays **/
    private static inline final CONTEMPT:Float = 200;

    private static final STANDARD_PIECE_VALUES:Array<Float> = [100, -100, 600, -600, 170, -170, 200, -200, 150, -150, WHITE_WIN_SCORE, BLACK_WIN_SCORE, 0];

    /** Material value of each piece code **/
    public static final PIECE_VALUES:Float64Array = Float64Array.from(STANDARD_PIECE_VALUES);

    private static final DISTANCE_TO_CENTER:Array<Int> = [
        5, 4, 4, 4, 4, 4, 5, // a
        4, 3, 3, 3, 3, 4, // b
        4, 3, 2, 2, 2, 3, 4, // c
        3, 2, 1, 1, 2, 3, // d
        3, 2, 1, 0, 1, 2, 3, // e
        3, 2, 1, 1, 2, 3, // f
        4, 3, 2, 2, 2, 3, 4, // g
        4, 3, 3, 3, 3, 4, // h
        5, 4, 4, 4, 4, 4, 5 // i
    ];

    private static final WHITE_PROGRESSOR_ADVANCEMENT:Array<Int> = [
        0, 0, 20, 50, 100, 150, 0, // a
        0, 0, 20, 50, 100, 150, // b
        0, 0, 20, 50, 100, 150, 0, // c
        0, 0, 20, 50, 100, 150, // d
        0, 0, 20, 50, 100, 150, 0, // e
        0, 0, 20, 50, 100, 150, // f
        0, 0, 20, 50, 100, 150, 0, // g
        0, 0, 20, 50, 100, 150, // h
        0, 0, 20, 50, 100, 150, 0 // i
    ];

    private static final BLACK_PROGRESSOR_ADVANCEMENT:Array<Int> = [
        0, -150, -100, -50, -20, 0, 0, // a
        -150, -100, -50, -20, 0, 0, // b
        0, -150, -100, -50, -20, 0, 0, // c
        -150, -100, -50, -20, 0, 0, // d
        0, -150, -100, -50, -20, 0, 0, // e
        -150, -100, -50, -20, 0, 0, // f
        0, -150, -100, -50, -20, 0, 0, // g
        -150, -100, -50, -20, 0, 0, // h
        0, -150, -100, -50, -20, 0, 0 // i
    ];

    private static final WHITE_INTELLECTOR_ADVANCEMENT:Array<Int> = [
        0, 5, 10, 20, 50, 100, 100000, // a
        0, 5, 10, 20, 50, 100, // b
        0, 5, 10, 20, 50, 100, 100000, // c
        0, 5, 10, 20, 50, 100, // d
        0, 5, 10, 20, 50, 100, 100000, // e
        0, 5, 10, 20, 50, 100, // f
        0, 5, 10, 20, 50, 100, 100000, // g
        0, 5, 10, 20, 50, 100, // h
        0, 5, 10, 20, 50, 100, 100000 // i
    ];

    private static final BLACK_INTELLECTOR_ADVANCEMENT:Array<Int> = [
        -100000, -100, -50, -20, -10, -5, 0, // a
        -100, -50, -20, -10, -5, 0, // b
        -100000, -100, -50, -20, -10, -5, 0, // c
        -100, -50, -20, -10, -5, 0, // d
        -100000, -100, -50, -20, -10, -5, 0, // e
        -100, -50, -20, -10, -5, 0, // f
        -100000, -100, -50, -20, -10, -5, 0, // g
        -100, -50, -20, -10, -5, 0, // h
        -100000, -100, -50, -20, -10, -5, 0 // i
    ];

    private static var advancementFactor:Float = 1;

    private static final PIECE_SQUARE_SCORES:Float64Array = fillPieceSquareScores(new Float64Array(Piece.COUNT * SQUARE_COUNT));

    /**
        Makes the tables evaluate as `style` does. Changes the evaluation of every search in this thread,
        so it has to be called before the search's board is created, and not while another search runs.
    **/
    public static function useStyle(style:HxcondaStyle):Void
    {
        for (piece in 0...Piece.COUNT)
            PIECE_VALUES[piece] = STANDARD_PIECE_VALUES[piece];

        // Each style values its favourite piece kind about 15% higher
        switch style
        {
            case Standard:
            case Trailblazer:
                setPieceValue(WhiteProgressor, 115);
            case Vrezh:
                setPieceValue(WhiteAggressor, 230);
            case Fortress:
                setPieceValue(WhiteDefensor, 170);
            case Unchained:
                setPieceValue(WhiteLiberator, 195);
        }

        advancementFactor = style == Trailblazer ? TRAILBLAZER_ADVANCEMENT_FACTOR : 1;
        fillPieceSquareScores(PIECE_SQUARE_SCORES);
    }

    /** Score of a draw for a search whose root side to move plays `style` with `rootColor` **/
    public static function drawScore(style:HxcondaStyle, rootColor:PlayerColor):Float
    {
        var contempt:Float = switch style {
            case Vrezh: -CONTEMPT;
            case Fortress: CONTEMPT;
            default: DRAW_SCORE;
        }
        return rootColor == White ? contempt : -contempt;
    }

    /** Value of `piece` standing on `square`: its material value plus the positional bonuses **/
    public static inline function pieceSquareScore(piece:Piece, square:Int):Float
    {
        return PIECE_SQUARE_SCORES[piece * SQUARE_COUNT + square];
    }

    /** Snaps decisive scores to the exact win scores **/
    public static inline function clampDecisive(score:Float):Float
    {
        return score > DECISIVE_THRESHOLD ? WHITE_WIN_SCORE : score < -DECISIVE_THRESHOLD ? BLACK_WIN_SCORE : score;
    }

    private static function computePieceSquareScore(piece:Piece, square:Int):Float
    {
        var value:Float = PIECE_VALUES[piece];
        var distanceToCenter:Int = DISTANCE_TO_CENTER[square];
        var neighbourCount:Int = BoardGeometry.NEIGHBOURS.size(square);
        var liberatorMobility:Float = neighbourCount / 2 + BoardGeometry.LIBERATOR_JUMPS.size(square);

        return switch piece {
            case WhiteProgressor: value + BoardGeometry.WHITE_PROGRESSOR_STEPS.size(square) * MOBILITY_WEIGHT + advancement(WHITE_PROGRESSOR_ADVANCEMENT[square]);
            case BlackProgressor: value - BoardGeometry.BLACK_PROGRESSOR_STEPS.size(square) * MOBILITY_WEIGHT + advancement(BLACK_PROGRESSOR_ADVANCEMENT[square]);
            case WhiteDominator: value + BoardGeometry.rayLength(BoardGeometry.DOMINATOR_RAYS, square) * MOBILITY_WEIGHT - distanceToCenter * CENTRALITY_WEIGHT;
            case BlackDominator: value - BoardGeometry.rayLength(BoardGeometry.DOMINATOR_RAYS, square) * MOBILITY_WEIGHT + distanceToCenter * CENTRALITY_WEIGHT;
            case WhiteLiberator: value + liberatorMobility * MOBILITY_WEIGHT - distanceToCenter * CENTRALITY_WEIGHT;
            case BlackLiberator: value - liberatorMobility * MOBILITY_WEIGHT + distanceToCenter * CENTRALITY_WEIGHT;
            case WhiteAggressor: value + BoardGeometry.rayLength(BoardGeometry.AGGRESSOR_RAYS, square) * MOBILITY_WEIGHT;
            case BlackAggressor: value - BoardGeometry.rayLength(BoardGeometry.AGGRESSOR_RAYS, square) * MOBILITY_WEIGHT;
            case WhiteDefensor: value + neighbourCount * MOBILITY_WEIGHT - distanceToCenter * CENTRALITY_WEIGHT;
            case BlackDefensor: value - neighbourCount * MOBILITY_WEIGHT + distanceToCenter * CENTRALITY_WEIGHT;
            case WhiteIntellector: value + neighbourCount * MOBILITY_WEIGHT + advancement(WHITE_INTELLECTOR_ADVANCEMENT[square]);
            case BlackIntellector: value - neighbourCount * MOBILITY_WEIGHT + advancement(BLACK_INTELLECTOR_ADVANCEMENT[square]);
            case Empty: 0;
        }
    }

    /** Sets the value of the white `piece` and the negated value of its black counterpart **/
    private static function setPieceValue(piece:Piece, value:Float):Void
    {
        PIECE_VALUES[piece] = value;
        PIECE_VALUES[piece.counterpart()] = -value;
    }

    private static function fillPieceSquareScores(scores:Float64Array):Float64Array
    {
        for (piece in 0...Piece.COUNT)
            for (square in 0...SQUARE_COUNT)
                scores[piece * SQUARE_COUNT + square] = computePieceSquareScore(cast piece, square);
        return scores;
    }

    /** An advancement bonus scaled by the style's factor; the decisive bonuses of the final row stay as they are **/
    private static function advancement(bonus:Int):Float
    {
        return Math.abs(bonus) > DECISIVE_THRESHOLD ? bonus : roundAwayFromZero(bonus * advancementFactor);
    }

    /** Keeps black's values the exact negations of white's ones **/
    private static function roundAwayFromZero(value:Float):Float
    {
        return value < 0 ? -Math.round(-value) : Math.round(value);
    }
}
