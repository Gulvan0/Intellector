package engine.hxconda.protocol;

import engine.hxconda.HxcondaStyle;
import engine.hxconda.search.weakening.Weakening;

/**
    Message posted to the engine worker.
**/
typedef HxcondaRequest = {
    var kind:HxcondaRequestKind;
    /** Position in the Anaconda notation, see `Board` **/
    var position:String;
    /** Positions of the game before `position`, oldest first, see `Hxconda`; none if absent **/
    var ?history:Array<String>;
    /** Searches of one game, run one after another with the same style, share their memory; absent for a search standing alone **/
    var ?gameId:String;
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
    /** `SearchByDepth` move choice among the root moves; the best move if absent **/
    var ?weakening:Weakening;
    /** `SearchByDepth` playing style, see `HxcondaStyle`; `Standard` if absent **/
    var ?style:HxcondaStyle;
}
