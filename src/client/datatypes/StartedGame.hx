package client.datatypes;

/**
    A game that has just started for the current user.
**/
class StartedGame
{
    public final id:Int;
    public final opponentNickname:String;

    public function new(id:Int, opponentNickname:String)
    {
        this.id = id;
        this.opponentNickname = opponentNickname;
    }
}
