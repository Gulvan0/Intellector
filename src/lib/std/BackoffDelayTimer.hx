package lib.std;

import haxe.Timer;

class BackoffDelayTimer
{
    private var nativeTimer:Null<Timer> = null;

    private var initialDelayMs:Int;
    private var minFactor:Float;
    private var factorSpan:Float;
    private var maxDelayThresholdMs:Int;
    private var minDeltaMsAboveThreshold:Int;
    private var deltaMsAboveThresholdSpan:Int;

    private var delayMs:Float;
    private var callback:Void->Void;

    public function new(initialDelayMs:Int, minFactor:Float, maxFactor:Float, maxDelayThresholdMs:Int, minDeltaMsAboveThreshold:Int, maxDeltaMsAboveThreshold:Int, callback:Void->Void)
    {
        this.initialDelayMs = initialDelayMs;
        this.minFactor = minFactor;
        this.factorSpan = maxFactor - minFactor;
        this.maxDelayThresholdMs = maxDelayThresholdMs;
        this.minDeltaMsAboveThreshold = minDeltaMsAboveThreshold;
        this.deltaMsAboveThresholdSpan = maxDeltaMsAboveThreshold - minDeltaMsAboveThreshold;

        this.delayMs = initialDelayMs;
        this.callback = callback;
    }

    public function startDelay()
    {
        stop();

        nativeTimer = new Timer(Math.round(delayMs));
        nativeTimer.run = timeout;
    }

    public function reset()
    {
        stop();

        this.delayMs = initialDelayMs;
    }

    public function stop()
    {
        if (nativeTimer != null)
        {
            nativeTimer.stop();
            nativeTimer = null;
        }
    }

    private function timeout()
    {
        if (delayMs < maxDelayThresholdMs)
            delayMs *= minFactor + factorSpan * Math.random();
        else
            delayMs += minDeltaMsAboveThreshold + deltaMsAboveThresholdSpan * Math.random();

        callback();
    }
}
