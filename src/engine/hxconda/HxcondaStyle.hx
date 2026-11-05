package engine.hxconda;

/**
    Playing style of a search: the piece values, advancement bonuses and draw score of its evaluation (see `Evaluation.useStyle`),
    and the bonuses a weakened search's move choice adds to the scores (see `StyleBonuses`).
**/
enum abstract HxcondaStyle(String)
{
    /** No bias **/
    var Standard = "std";
    /** Values progressors and their and the intellector's advancement more; likes progressor and forward intellector moves **/
    var Trailblazer = "trl";
    /** Values aggressors more and dislikes draws; likes checks and sacrifices **/
    var Vrezh = "vrz";
    /** Values defensors more and likes draws; likes its pieces defended and dislikes counter-attacking while attacked **/
    var Fortress = "frt";
    /** Values liberators more; likes attacking more squares, liberator jumps and long slides **/
    var Unchained = "unc";
}
