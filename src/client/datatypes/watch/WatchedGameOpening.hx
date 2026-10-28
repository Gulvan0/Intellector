package client.datatypes.watch;

/**
    When a game started by the watched player opens in the app instead of being announced. It never
    opens while the page refuses to be left or the user plays an unfinished timed game.
**/
enum abstract WatchedGameOpening(String) from String to String
{
    var ALWAYS = "always";
    // Not while spectating an unfinished timed game either.
    var UNLESS_SPECTATING = "unless_spectating";
    var NEVER = "never";
}
