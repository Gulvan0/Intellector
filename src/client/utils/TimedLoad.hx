package client.utils;

import haxe.Timer;
import http.HttpError;

/** One request at a time, given up on after a timeout: starting another one, or cancelling, makes the earlier answer ignored **/
class TimedLoad
{
    private static inline final DEFAULT_TIMEOUT_MS:Int = 10000;

    private final timeoutMs:Int;

    private var attempt:Int = 0;
    private var timer:Null<Timer> = null;

    public function new(timeoutMs:Int = DEFAULT_TIMEOUT_MS)
    {
        this.timeoutMs = timeoutMs;
    }

    /**
        `send` performs the request, calling its first argument with the response or its second with
        the error. Exactly one of `onLoaded` and `onFailed` follows, unless `start` or `cancel` comes
        first. `onFailed` gets null for a timeout.
    **/
    public function start<T>(send:(T->Void, HttpError->Void)->Void, onLoaded:T->Void, onFailed:Null<HttpError>->Void):Void
    {
        cancel();
        var current:Int = attempt;

        timer = Timer.delay(() -> {
            if (current == attempt)
            {
                cancel();
                onFailed(null);
            }
        }, timeoutMs);

        send(
            response -> {
                if (current == attempt)
                {
                    cancel();
                    onLoaded(response);
                }
            },
            error -> {
                if (current == attempt)
                {
                    cancel();
                    onFailed(error);
                }
            }
        );
    }

    public function cancel():Void
    {
        attempt++;
        if (timer != null)
            timer.stop();
        timer = null;
    }
}
