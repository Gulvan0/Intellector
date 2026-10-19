package client.datatypes.player;

/** A player found by a nickname search **/
class FoundPlayer
{
    public final login:String;
    public final nickname:String;
    public final status:PlayerStatus;
    public final role:Null<PlayerRole>;
    public final relation:PlayerRelation;
    public final mainRating:Null<MainRating>;

    public function new(login:String, nickname:String, status:PlayerStatus, role:Null<PlayerRole>, relation:PlayerRelation, mainRating:Null<MainRating>)
    {
        this.login = login;
        this.nickname = nickname;
        this.status = status;
        this.role = role;
        this.relation = relation;
        this.mainRating = mainRating;
    }
}
