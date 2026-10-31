package engine.hxconda.search.budget;

import engine.hxconda.search.BestMoveReport;

/**
    Limits the search by depth and, optionally, by wall-clock time, reporting the best move after every completed iteration.
    Once the time cap runs out, the running iteration is abandoned and no further one starts.
**/
final class DepthBudget implements SearchBudget
{
    private final maxDepth:Int;
    private final timeCapMs:Null<Float>;
    private final onIteration:BestMoveReport->Void;
    private final isCapped:Bool;
    private var deadline:Float = 0;
    /** Latched as soon as any check sees the deadline passed, so the iteration it interrupts is never counted as completed **/
    private var isOverdue:Bool = false;
    private var completedDepth:Int = 0;

    public inline function start():Void
    {
        if (isCapped)
            deadline = Clock.now() + timeCapMs;
    }

    public inline function hasRemaining():Bool
    {
        return completedDepth < maxDepth && !checkOverdue();
    }

    public inline function isExhausted():Bool
    {
        return checkOverdue();
    }

    public inline function onNodeEntered() {}

    public inline function allowsWindowNarrowing(isRoot:Bool):Bool
    {
        return true;
    }

    public inline function allowsRootProgress(isRoot:Bool, depth:Int, maxDepth:Int):Bool
    {
        return depth == maxDepth && (hasRemaining() || maxDepth <= 1);
    }

    public inline function tracksLines():Bool
    {
        return true;
    }

    /** The first iteration always completes: it is never abandoned **/
    public inline function onIterationCompleted(report:BestMoveReport):Void
    {
        if (!isOverdue || completedDepth == 0)
        {
            completedDepth++;
            onIteration(report);
        }
    }

    private inline function checkOverdue():Bool
    {
        if (isCapped && !isOverdue && deadline - Clock.now() < 0)
            isOverdue = true;
        return isOverdue;
    }

    /** `timeCapMs` = null searches until `maxDepth` regardless of time **/
    public function new(maxDepth:Int, timeCapMs:Null<Float>, onIteration:BestMoveReport->Void)
    {
        this.maxDepth = maxDepth;
        this.timeCapMs = timeCapMs;
        this.onIteration = onIteration;
        isCapped = timeCapMs != null;
    }
}
