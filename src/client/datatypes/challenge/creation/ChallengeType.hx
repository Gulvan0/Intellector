package client.datatypes.challenge.creation;

enum abstract ChallengeType(String) from String to String
{
    var DIRECT = "direct";
    var OPEN = "open";
    var BOT = "bot";
}
