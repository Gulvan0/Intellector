package client.datatypes.challenge.creation;

enum abstract StartingPositionMode(String) from String to String
{
    var DEFAULT = "default";
    var CUSTOM = "custom";
}
