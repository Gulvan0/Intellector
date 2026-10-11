package client.datatypes.game;

/** A player of a game **/
class GameParticipant
{
    /** A login, or a guest's `_<id>` **/
    public final ref:String;
    public final nickname:String;
    /** As of the game's start; null for guests **/
    public final rating:Null<PlayerRating>;

    public function new(ref:String, nickname:String, rating:Null<PlayerRating>)
    {
        this.ref = ref;
        this.nickname = nickname;
        this.rating = rating;
    }
}
