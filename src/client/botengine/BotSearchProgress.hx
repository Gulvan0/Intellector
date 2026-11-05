package client.botengine;

/** How far a bot's search has got, in plies **/
class BotSearchProgress
{
    public final depth:Int;
    /** The depth at which the search ends, unless its time cap comes first **/
    public final targetDepth:Int;

    public function new(depth:Int, targetDepth:Int)
    {
        this.depth = depth;
        this.targetDepth = targetDepth;
    }
}
