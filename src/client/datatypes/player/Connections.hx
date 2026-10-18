package client.datatypes.player;

class Connections
{
    private final lists:Map<ConnectionKind, Array<Connection>>;

    public function new(friends:Array<Connection>, following:Array<Connection>, followers:Array<Connection>)
    {
        lists = [Friends => friends, Following => following, Followers => followers];
    }

    public function get(kind:ConnectionKind):Array<Connection>
    {
        return lists.get(kind);
    }
}
