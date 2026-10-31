package client.botengine;

import intellectorboard.primitives.ply.RawPly;

/** A move a bot found **/
class BotMove
{
    public final ply:RawPly;
    /** Positive favours white; a decisive score is within a few hundred points of ±100000 **/
    public final score:Float;
    /** The expected continuation, starting with `ply` **/
    public final line:Array<RawPly>;

    public function new(ply:RawPly, score:Float, line:Array<RawPly>)
    {
        this.ply = ply;
        this.score = score;
        this.line = line;
    }
}
