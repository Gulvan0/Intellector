package client.datatypes.challenge.creation;

enum abstract CalleeKind(String) from String to String
{
    var PLAYER = "player";
    var GUEST = "guest";
}
