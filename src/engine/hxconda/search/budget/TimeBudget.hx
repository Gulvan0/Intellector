package engine.hxconda.search.budget;

import engine.hxconda.search.BestMoveReport;

/**
    Limits the search by wall-clock time, reporting the best move after every iteration.
**/
final class TimeBudget implements SearchBudget
{
    private final durationMs:Float;
    private final onIteration:BestMoveReport->Void;
    private var deadline:Float = 0;

    public inline function start():Void
    {
        deadline = Clock.now() + durationMs;
    }

    public inline function hasRemaining():Bool
    {
        return deadline - Clock.now() > 0;
    }

    public inline function isExhausted():Bool
    {
        return deadline - Clock.now() < 0;
    }

    public inline function onNodeEntered() {}

    public inline function allowsWindowNarrowing(isRoot:Bool):Bool
    {
        return true;
    }

    public inline function allowsRootProgress(isRoot:Bool, depth:Int, maxDepth:Int, isMaximizing:Bool):Bool
    {
        return depth == maxDepth && (hasRemaining() || maxDepth <= 1);
    }

    public inline function tracksLines():Bool
    {
        return true;
    }

    public inline function onIterationCompleted(report:BestMoveReport):Void
    {
        onIteration(report);
    }

    public function new(durationMs:Float, onIteration:BestMoveReport->Void)
    {
        this.durationMs = durationMs;
        this.onIteration = onIteration;
    }
}
