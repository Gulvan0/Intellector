package engine.hxconda.search.budget;

import engine.hxconda.search.BestMoveReport;

/**
    Limits the search by the number of visited nodes, reporting the visited share of the limit every `PROGRESS_INTERVAL` nodes.
**/
final class NodeBudget implements SearchBudget
{
    private static inline final PROGRESS_INTERVAL:Int = 10000;

    private static final LEVEL_NODE_LIMITS:Array<Int> = [3000, 10000, 30000, 100000, 300000, 1000000, 3000000, 10000000, 30000000, 70000000, 150000000];
    private static final LEVEL_NOISE_AMPLITUDES:Array<Float> = [500, 250, 100, 50, 25, 20, 15, 15, 10, 10, 8];

    /** Maximum random offset added to the evaluation, making weaker levels play less precisely **/
    public final noiseAmplitude:Float;

    private final nodeLimit:Int;
    private final onProgress:(percent:Int)->Void;
    private var nodeCount:Int = 0;

    /** Budget of a difficulty `level` from 0 to 10; any other level allows no search at all **/
    public static function forLevel(level:Int, onProgress:(percent:Int)->Void):NodeBudget
    {
        if (Std.isOfType(level, Int) && level >= 0 && level < LEVEL_NODE_LIMITS.length)
            return new NodeBudget(LEVEL_NODE_LIMITS[level], LEVEL_NOISE_AMPLITUDES[level], onProgress);
        else
            return new NodeBudget(0, 0, onProgress);
    }

    public inline function start() {}

    public inline function hasRemaining():Bool
    {
        return nodeLimit - nodeCount > 0;
    }

    public inline function isExhausted():Bool
    {
        return nodeLimit - nodeCount <= 0;
    }

    public inline function onNodeEntered():Void
    {
        if (nodeCount % PROGRESS_INTERVAL == 0)
            onProgress(Math.floor(nodeCount * 100.0 / nodeLimit));
        nodeCount++;
    }

    /** The root reports while the budget lasts, and throughout the first iteration **/
    public inline function allowsRootProgress(isRoot:Bool, depth:Int, maxDepth:Int):Bool
    {
        return isRoot && (hasRemaining() || maxDepth <= 1);
    }

    public inline function tracksLines():Bool
    {
        return false;
    }

    public inline function onIterationCompleted(report:BestMoveReport) {}

    public function new(nodeLimit:Int, noiseAmplitude:Float, onProgress:(percent:Int)->Void)
    {
        this.nodeLimit = nodeLimit;
        this.noiseAmplitude = noiseAmplitude;
        this.onProgress = onProgress;
    }
}
