package client.datatypes.game;

class PlayerRating
{
    public final elo:Int;
    public final provisional:Bool;

    public function new(elo:Int, provisional:Bool)
    {
        this.elo = elo;
        this.provisional = provisional;
    }
}
