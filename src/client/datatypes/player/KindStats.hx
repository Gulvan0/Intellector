package client.datatypes.player;

import client.datatypes.game.PlayerRating;
import client.datatypes.timecontrol.TimeControlKind;

/** A player's finished games of one time control kind **/
class KindStats
{
    public final kind:TimeControlKind;
    public final totalGames:Int;
    public final ratedGames:Int;
    /** Null until the first rated game **/
    public final rating:Null<PlayerRating>;

    public function new(kind:TimeControlKind, totalGames:Int, ratedGames:Int, rating:Null<PlayerRating>)
    {
        this.kind = kind;
        this.totalGames = totalGames;
        this.ratedGames = ratedGames;
        this.rating = rating;
    }

    public function hasRating():Bool
    {
        return rating != null;
    }
}
