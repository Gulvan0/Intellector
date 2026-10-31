package engine.hxconda.protocol;

import engine.hxconda.HxcondaStyle;

/**
    Message posted to the engine worker.
**/
typedef HxcondaRequest = {
    var kind:HxcondaRequestKind;
    /** Position in the Anaconda notation, see `Board` **/
    var position:String;
    /** Positions of the game before `position`, oldest first, see `Hxconda`; none if absent **/
    var ?history:Array<String>;
    /** `SearchByLevel` difficulty, from 0 to 10 **/
    var ?level:Int;
    /** `SearchByTime` thinking time **/
    var ?durationMs:Float;
    /** `SearchByNodes` node budget **/
    var ?nodeLimit:Int;
    /** `SearchByNodes` evaluation noise, see `NodeBudget.noiseAmplitude`; 0 if absent **/
    var ?noiseAmplitude:Float;
    /** `SearchByDepth` depth, in plies **/
    var ?maxDepth:Int;
    /** `SearchByDepth` thinking time cap; none if absent **/
    var ?timeCapMs:Float;
    /** `SearchByDepth` handicap, in centiprogressors; accepted, not applied yet **/
    var ?weakness:Float;
    /** `SearchByDepth` playing style, see `HxcondaStyle`; `Standard` if absent **/
    var ?style:HxcondaStyle;
}
