package engine.hxconda.search.budget;

import engine.hxconda.search.BestMoveReport;

/**
    Decides when an `AlphaBetaSearch` stops and how it reports progress.
    Implementations should be final classes with inline methods: the search is specialized per budget class, so the calls get inlined.
**/
interface SearchBudget
{
    /** Called right before the first iteration **/
    public function start():Void;

    /** Whether another iteration may start; also gates the end-of-iteration report **/
    public function hasRemaining():Bool;

    /** Whether non-root nodes of deep iterations have to be abandoned **/
    public function isExhausted():Bool;

    public function onNodeEntered():Void;

    /** Whether transposition table bounds may narrow the window of a node **/
    public function allowsWindowNarrowing(isRoot:Bool):Bool;

    /** Whether a node may report its best move found so far as the best root move **/
    public function allowsRootProgress(isRoot:Bool, depth:Int, maxDepth:Int, isMaximizing:Bool):Bool;

    /** Whether the search collects the principal line **/
    public function tracksLines():Bool;

    public function onIterationCompleted(report:BestMoveReport):Void;
}
