package engine.hxconda.search;

import engine.hxconda.board.Move;

class TranspositionEntry
{
    public final move:Move;
    public final depth:Int;
    public final score:Float;
    /** Lower end of the window `score` is exact within: equals `score` for an upper bound **/
    public final alpha:Float;
    /** Upper end of the window `score` is exact within: equals `score` for a lower bound **/
    public final beta:Float;

    public function new(move:Move, depth:Int, score:Float, alpha:Float, beta:Float)
    {
        this.move = move;
        this.depth = depth;
        this.score = score;
        this.alpha = alpha;
        this.beta = beta;
    }
}
