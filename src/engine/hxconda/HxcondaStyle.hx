package engine.hxconda;

/**
    Playing style of a search. Accepted, not applied yet: every style plays as `Standard`.
**/
enum abstract HxcondaStyle(String)
{
    /** No bias **/
    var Standard = "std";
    /** Pushes progressors, marches the Intellector **/
    var Trailblazer = "trl";
    /** Checks and sacrifices **/
    var Vrezh = "vrz";
    /** Keeps every piece defended **/
    var Fortress = "frt";
    /** Trades, open board, long moves **/
    var Unchained = "unc";
}
