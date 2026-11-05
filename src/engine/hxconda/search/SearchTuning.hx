package engine.hxconda.search;

import engine.hxconda.board.Move;
import engine.hxconda.evaluation.Evaluation.DECISIVE_THRESHOLD;

/**
    Constants and helpers of `AlphaBetaSearch`, which cannot hold static fields itself, being generic.
**/
class SearchTuning
{
    public static inline final SORTING_DEPTH:Int = 2;
    public static inline final HASHING_DEPTH:Int = 2;
    public static inline final REPETITION_DEPTH:Int = 2;
    public static inline final NULL_MOVE_DEPTH:Int = 1;
    /** Nodes this deep try a null move searched `NULL_MOVE_REDUCTION` plies shallower, plus the depth shifted right by `NULL_MOVE_REDUCTION_DEPTH_SHIFT` **/
    public static inline final NULL_MOVE_PRUNING_DEPTH:Int = 3;
    public static inline final NULL_MOVE_REDUCTION:Int = 3;
    public static inline final NULL_MOVE_REDUCTION_DEPTH_SHIFT:Int = 2;
    /** Nodes this deep without a hash move are searched a ply shallower **/
    public static inline final NO_HASH_MOVE_REDUCTION_DEPTH:Int = 4;
    /** Null-window nodes up to this deep return their static evaluation if it clears the bound by `REVERSE_FUTILITY_MARGIN` per ply of depth **/
    public static inline final REVERSE_FUTILITY_DEPTH:Int = 6;
    public static inline final REVERSE_FUTILITY_MARGIN:Float = 60;
    public static inline final REPETITIONS_TO_DRAW:Int = 2;
    /** Deeper quiescence plies only consider recaptures and intellector captures **/
    public static inline final UNRESTRICTED_QUIESCENCE_DEPTH:Int = 2;
    /** Quiet moves in nodes this deep get reduced by `LATE_MOVE_REDUCTION_SCALE` times the product of the logarithms of the depth and of the move's index, by at most `LATE_MOVE_REDUCTION_CAP` plies **/
    public static inline final LATE_MOVE_REDUCTION_DEPTH:Int = 3;
    public static inline final LATE_MOVE_REDUCTION_SCALE:Float = 0.75;
    public static inline final LATE_MOVE_REDUCTION_CAP:Float = 4;
    public static inline final CHECK_EXTENSION:Float = 0.5;
    /** The first moves of a node are never reduced, nor are any at the root **/
    public static inline final UNREDUCED_MOVE_COUNT:Int = 2;
    /** Half-width of the first root window, multiplied by `ASPIRATION_WIDENING` after every failure until it exceeds `ASPIRATION_MAX_MARGIN`; the next window is unbounded on the failed side **/
    public static inline final ASPIRATION_MARGIN:Float = 50;
    public static inline final ASPIRATION_WIDENING:Float = 4;
    public static inline final ASPIRATION_MAX_MARGIN:Float = 400;
    /** Width of the first window a weakened search's exact root move search tries above the score's known lower bound **/
    public static inline final ROOT_EXACT_MARGIN:Float = 20;
    /** Ordering keys, side-relative: immediate wins above captures not losing material, which are offset by their gain; losing captures go below everything **/
    public static inline final WINNING_MOVE_ORDERING_KEY:Float = 1000000000;
    public static inline final CAPTURE_ORDERING_KEY:Float = 100000000;
    public static inline final HISTORY_ORDERING_DIVISOR:Float = 1000000;
    /** A bot's next search of the same game starts after its own move and the opponent's reply **/
    public static inline final PLIES_BETWEEN_SEARCHES:Int = 2;
    public static inline final HISTORY_DECAY_DIVISOR:Float = 2;
    /** Plies from the root that keep killer moves; deeper nodes go without **/
    public static inline final KILLER_PLY_COUNT:Int = 128;
    /** Ordering key distance between the killer moves and the other quiet moves, beyond any capture's key at depth-1 nodes and any history bonus **/
    public static inline final KILLER_ORDERING_STEP:Float = 1000000;

    /** Moves a decisive score one point towards zero, so that faster wins and slower losses are preferred **/
    public static inline function decayDecisiveScore(score:Float):Float
    {
        return score > DECISIVE_THRESHOLD ? score - 1 : score < -DECISIVE_THRESHOLD ? score + 1 : score;
    }

    public static function extendLine(line:Null<Array<Move>>, move:Move):Array<Move>
    {
        var extendedLine:Array<Move> = line ?? [];
        extendedLine.push(move);
        return extendedLine;
    }

    /** Moves `move` to the front of `moves`, keeping the order of the others; nothing happens if it's not there **/
    public static function putFirst(moves:Array<Move>, move:Move):Void
    {
        var i:Int = moves.indexOf(move);
        while (i > 0)
        {
            moves[i] = moves[i - 1];
            i--;
        }
        if (i == 0)
            moves[0] = move;
    }

    /** Stable insertion sort of `moves` by `keys` **/
    public static function sortByKeys(moves:Array<Move>, keys:Array<Float>, isDescending:Bool):Void
    {
        for (i in 1...moves.length)
        {
            var move:Move = moves[i];
            var key:Float = keys[i];
            var j:Int = i - 1;

            if (isDescending)
                while (j >= 0 && keys[j] < key)
                {
                    keys[j + 1] = keys[j];
                    moves[j + 1] = moves[j];
                    j--;
                }
            else
                while (j >= 0 && keys[j] > key)
                {
                    keys[j + 1] = keys[j];
                    moves[j + 1] = moves[j];
                    j--;
                }

            keys[j + 1] = key;
            moves[j + 1] = move;
        }
    }
}
