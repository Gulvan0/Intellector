package engine.hxconda.search.weakening;

/** What a root move's recorded value says about its score **/
enum abstract ScoreBound(Int)
{
    var Exact = 0;
    /** The score is at least the value **/
    var Lower = 1;
    /** The score is at most the value **/
    var Upper = 2;
}
