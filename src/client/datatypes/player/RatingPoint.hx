package client.datatypes.player;

/** A rating as it became after a rated game **/
class RatingPoint
{
    /** Unix time, in milliseconds **/
    public final atMs:Float;
    public final elo:Int;

    public function new(atMs:Float, elo:Int)
    {
        this.atMs = atMs;
        this.elo = elo;
    }
}
