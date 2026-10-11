package client.datatypes.challenge.creation;

enum abstract OpenChallengeVisibility(String) from String to String
{
    var PUBLIC = "public";
    var LINK_ONLY = "link_only";
}
