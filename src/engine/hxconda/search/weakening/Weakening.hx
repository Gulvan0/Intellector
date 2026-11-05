package engine.hxconda.search.weakening;

/**
    How a weakened search picks its move: among the best `candidateCount` root moves losing between `minLoss` and `maxLoss`
    centiprogressors against the best one, at random, see `WeakenedMoveChoice`.
**/
typedef Weakening = {
    var minLoss:Float;
    /** Unbounded if absent **/
    var ?maxLoss:Float;
    /** Exponent of the pick weights: the higher, the more the least losing candidates are favoured **/
    var weightExponent:Int;
    var candidateCount:Int;
    /** Even depths from this one on score the root moves; so do depths 1 and 2, the others search plainly **/
    var scoredFromDepth:Int;
}
