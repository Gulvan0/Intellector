package client.datatypes;

/**
    When a new move snaps the view back from an older position to the live one.
**/
enum abstract FollowLatestMoveMode(String) from String to String
{
    var ALWAYS = "always";
    // Only in a game the user is playing.
    var OWN_GAME_ONLY = "own_game_only";
    var NEVER = "never";
}
