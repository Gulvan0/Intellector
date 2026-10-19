package client.datatypes.player;

class PlayerProfile
{
    public final login:String;
    public final nickname:String;
    /** Unix time, in milliseconds **/
    public final joinedAtMs:Float;
    public final role:Null<PlayerRole>;
    public final status:PlayerStatus;
    /** Unix time of the player's latest activity, in milliseconds **/
    public final lastActiveMs:Float;

    public function new(login:String, nickname:String, joinedAtMs:Float, role:Null<PlayerRole>, status:PlayerStatus, lastActiveMs:Float)
    {
        this.login = login;
        this.nickname = nickname;
        this.joinedAtMs = joinedAtMs;
        this.role = role;
        this.status = status;
        this.lastActiveMs = lastActiveMs;
    }
}
