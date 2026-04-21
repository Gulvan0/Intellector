package lib.std;

import haxe.Timer;

class RefreshableTimer
{
    private var activeNativeTimer:Null<Timer> = null;

    private var periodMs:Int;
    private var callback:Void->Void;

    public function new(periodMs:Int, callback:Void->Void)
    {
        this.periodMs = periodMs;
        this.callback = callback;
    }

    public function start()
    {
        stop();

        activeNativeTimer = new Timer(periodMs);
        activeNativeTimer.run = callback;
    }

    public function stop()
    {
        if (activeNativeTimer != null)
        {
            activeNativeTimer.stop();
            activeNativeTimer = null;
        }
    }

    public function isActive()
    {
        return activeNativeTimer != null;
    }
}
