package engine;

import net.shared.board.RawPly;

typedef EvaluationResult = {
    var mainLine:Array<RawPly>;
    var score:Float;
    var depth:Int;
}