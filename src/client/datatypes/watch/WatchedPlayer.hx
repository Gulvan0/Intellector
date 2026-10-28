package client.datatypes.watch;

/** The player whose new games the user follows **/
class WatchedPlayer
{
    public final login:String;
    public final nickname:String;

    public function new(login:String, nickname:String)
    {
        this.login = login;
        this.nickname = nickname;
    }
}
