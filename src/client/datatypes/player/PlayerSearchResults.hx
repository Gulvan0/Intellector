package client.datatypes.player;

/** The best matches of a nickname search, and how many players matched in all **/
class PlayerSearchResults
{
    public final players:Array<FoundPlayer>;
    public final totalCount:Int;

    public function new(players:Array<FoundPlayer>, totalCount:Int)
    {
        this.players = players;
        this.totalCount = totalCount;
    }
}
