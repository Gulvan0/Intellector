package client.datatypes.player;

enum ConnectionKind
{
    Friends; // mutual follows
    Following; // one-way, by the player
    Followers; // one-way, of the player
}
