package client.datatypes;

/**
    When the board control row (touch-screen substitutes for the right button and modifier keys)
    is shown.
**/
enum abstract BoardControlsVisibility(String) from String to String
{
    // When the primary pointer is coarse (a touch screen).
    var AUTO = "auto";
    var ALWAYS = "always";
    var NEVER = "never";
}
