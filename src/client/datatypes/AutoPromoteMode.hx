package client.datatypes;

/**
    When a promotion skips the prompt and becomes a Dominator.
**/
enum abstract AutoPromoteMode(String) from String to String
{
    var NEVER = "never";
    // Only with Shift held at completion.
    var SHIFT = "shift";
    var ALWAYS = "always";
}
