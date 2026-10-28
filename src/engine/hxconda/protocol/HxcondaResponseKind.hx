package engine.hxconda.protocol;

enum abstract HxcondaResponseKind(String)
{
    /** `SearchByLevel` and `SearchByNodes` only: carries `percent` **/
    var Progress = "progress";
    /** `SearchByTime` only, posted after every iteration: carries `report` **/
    var Iteration = "iteration";
    /** Ends the search: carries `report` unless nothing was found **/
    var Completed = "completed";
    /** Ends the search, typically because the game is already over: carries `error` **/
    var Failed = "failed";
}
