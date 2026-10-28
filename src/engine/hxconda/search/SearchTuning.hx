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
    public static inline final REPETITIONS_TO_DRAW:Int = 2;
    /** Deeper quiescence plies only consider recaptures and intellector captures **/
    public static inline final UNRESTRICTED_QUIESCENCE_DEPTH:Int = 2;
    /** Quiet moves leading to positions searched this deep get reduced the more the later they come **/
    public static inline final LATE_MOVE_REDUCTION_HASH_DEPTH:Int = 3;
    public static inline final TACTICAL_EXTENSION:Float = 0.5;
    public static inline final ASPIRATION_NEAR_MARGIN:Float = 10;
    public static inline final ASPIRATION_FAR_MARGIN:Float = 20;
    public static inline final DEPTH_ORDERING_WEIGHT:Float = 100;
    public static inline final HISTORY_ORDERING_DIVISOR:Float = 1000000;

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
