package client.datatypes.bot;

/** A member of the Haxaconda bot family, by its code in the bot's user ref **/
enum abstract BotKind(String) from String to String
{
    var STANDARD = "std";
    var TRAILBLAZER = "trl";
    var VREZH = "vrz";
    var FORTRESS = "frt";
    var UNCHAINED = "unc";
}
