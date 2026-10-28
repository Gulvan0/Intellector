package engine.hxconda.protocol;

typedef HxcondaReportMessage = {
    /** Null if the search could not settle on a move **/
    var move:Null<HxcondaMoveMessage>;
    /** Positive favours white; a decisive score is within a few hundred points of ±100000 **/
    var score:Float;
    /** Depth of the iteration that found `move` **/
    var depth:Int;
    /** How many root moves had been searched when `move` was found **/
    var searchedRootMoveCount:Int;
    /** Expected continuation, starting with a root move. `SearchByTime` only; can disagree with `move` **/
    var ?principalLine:Array<HxcondaMoveMessage>;
}
