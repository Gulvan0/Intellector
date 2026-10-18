package client.datatypes.player;

/** How the user and a player follow each other; the times are Unix milliseconds **/
enum PlayerRelation
{
    Unrelated;
    FollowsYou;
    YouFollow(sinceMs:Float);
    Friends(sinceMs:Float); // they follow each other, since the later of the two follows
}
