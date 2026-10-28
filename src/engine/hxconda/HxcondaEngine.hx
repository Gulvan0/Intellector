package engine.hxconda;

import engine.hxconda.protocol.HxcondaEvent;
import engine.hxconda.protocol.HxcondaProtocol;
import engine.hxconda.protocol.HxcondaRequest;
import js.html.MessageEvent;
import js.html.Worker;

/**
    Runs Hxconda searches off the main thread, in the web worker built from `hxconda.hxml`.
    One search runs at a time: starting another one or calling `stop` abandons the running search.
    Every search gets a fresh worker, so nothing carries over between searches.
**/
class HxcondaEngine
{
    private static inline final WORKER_URL:String = "bin/hxconda.js";

    private var worker:Null<Worker> = null;

    /** Searches within the node budget of a difficulty `level` (0 to 10), which plays the same on any hardware **/
    public function searchByLevel(notation:String, level:Int, onEvent:HxcondaEvent->Void):Void
    {
        start({kind: SearchByLevel, position: notation, level: level}, onEvent);
    }

    /** Searches within `nodeLimit` nodes, adding evaluation noise of up to `noiseAmplitude`, see `NodeBudget` **/
    public function searchByNodes(notation:String, nodeLimit:Int, noiseAmplitude:Float, onEvent:HxcondaEvent->Void):Void
    {
        start({kind: SearchByNodes, position: notation, nodeLimit: nodeLimit, noiseAmplitude: noiseAmplitude}, onEvent);
    }

    /** Searches for `durationMs` milliseconds **/
    public function searchByTime(notation:String, durationMs:Float, onEvent:HxcondaEvent->Void):Void
    {
        start({kind: SearchByTime, position: notation, durationMs: durationMs}, onEvent);
    }

    public function stop():Void
    {
        if (worker == null)
            return;

        worker.terminate();
        worker = null;
    }

    private function start(request:HxcondaRequest, onEvent:HxcondaEvent->Void):Void
    {
        stop();

        var searchWorker:Worker = new Worker(WORKER_URL);
        searchWorker.onmessage = (message:MessageEvent) -> {
            var event:HxcondaEvent = HxcondaProtocol.decodeResponse(message.data);
            switch event
            {
                case Completed(_) | Failed(_):
                    stop();
                default:
            }
            onEvent(event);
        };
        searchWorker.onerror = () -> {
            stop();
            onEvent(Failed("The engine worker failed to run"));
        };
        searchWorker.postMessage(request);

        worker = searchWorker;
    }

    public function new() {}
}
