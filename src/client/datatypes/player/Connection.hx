package client.datatypes.player;

/** A player in another player's friends, following or followers **/
class Connection
{
    public final login:String;
    public final nickname:String;
    public final status:PlayerStatus;
    public final mainRating:Null<MainRating>;

    public function new(login:String, nickname:String, status:PlayerStatus, mainRating:Null<MainRating>)
    {
        this.login = login;
        this.nickname = nickname;
        this.status = status;
        this.mainRating = mainRating;
    }
}
