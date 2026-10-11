package client.datatypes.challenge.creation;

enum abstract CallerColorChoice(String) from String to String
{
    var WHITE = "white";
    var RANDOM = "random";
    var BLACK = "black";
}
