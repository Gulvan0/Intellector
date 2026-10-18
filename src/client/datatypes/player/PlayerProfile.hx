package client.datatypes.player;

class PlayerProfile
{
    public final login:String;
    public final nickname:String;
    /** Unix time, in milliseconds **/
    public final joinedAtMs:Float;
    public final role:Null<PlayerRole>;
    public final status:PlayerStatus;

    public function new(login:String, nickname:String, joinedAtMs:Float, role:Null<PlayerRole>, status:PlayerStatus)
    {
        this.login = login;
        this.nickname = nickname;
        this.joinedAtMs = joinedAtMs;
        this.role = role;
        this.status = status;
    }
}
