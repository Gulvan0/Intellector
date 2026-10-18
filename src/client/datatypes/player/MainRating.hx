package client.datatypes.player;

import client.datatypes.game.PlayerRating;
import client.datatypes.timecontrol.TimeControlKind;

/** A player's best rating, and the time control kind it is in **/
class MainRating
{
    public final kind:TimeControlKind;
    public final rating:PlayerRating;

    public function new(kind:TimeControlKind, rating:PlayerRating)
    {
        this.kind = kind;
        this.rating = rating;
    }
}
