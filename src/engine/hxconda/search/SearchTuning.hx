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
    /** Nodes this deep try a null move searched `NULL_MOVE_REDUCTION` plies shallower, or one more ply shallower from `NULL_MOVE_DEEP_DEPTH` on **/
    public static inline final NULL_MOVE_PRUNING_DEPTH:Int = 3;
    public static inline final NULL_MOVE_REDUCTION:Int = 2;
    public static inline final NULL_MOVE_DEEP_DEPTH:Int = 6;
    public static inline final REPETITIONS_TO_DRAW:Int = 2;
    /** Deeper quiescence plies only consider recaptures and intellector captures **/
    public static inline final UNRESTRICTED_QUIESCENCE_DEPTH:Int = 2;
    /** Quiet moves leading to positions searched this deep get reduced the more the later they come **/
    public static inline final LATE_MOVE_REDUCTION_HASH_DEPTH:Int = 3;
    public static inline final TACTICAL_EXTENSION:Float = 0.5;
    public static inline final ASPIRATION_NEAR_MARGIN:Float = 10;
    public static inline final ASPIRATION_FAR_MARGIN:Float = 20;
    /** Ordering keys, side-relative: immediate wins above captures not losing material, which are offset by their gain; losing captures go below everything **/
    public static inline final WINNING_MOVE_ORDERING_KEY:Float = 1000000000;
    public static inline final CAPTURE_ORDERING_KEY:Float = 100000000;
    public static inline final HISTORY_ORDERING_DIVISOR:Float = 1000000;
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
