package engine.hxconda;

import engine.hxconda.protocol.HxcondaEvent;
import engine.hxconda.protocol.HxcondaMoveMessage;
import engine.hxconda.protocol.HxcondaProtocol;
import engine.hxconda.protocol.HxcondaReportMessage;
import engine.hxconda.protocol.HxcondaRequest;
import engine.hxconda.search.weakening.Weakening;
import js.html.ErrorEvent;
import js.html.MessageEvent;
import js.html.Worker;

/**
    Runs Hxconda searches off the main thread, in the web worker built from `hxconda.hxml`.
    All engines share one worker, which keeps its memory between the searches of a game, see `Hxconda`, and runs one search at a time.
    An engine starting a search abandons its own running or queued one; a search started while another engine's is running waits
    for it. `stop` abandons the engine's search: a running one by terminating the worker, which loses its memory.
    `history` lists the positions of the game before the searched one, oldest first: the search scores returning to any of them as a draw.
**/
class HxcondaEngine
{
    private static inline final WORKER_URL:String = "bin/hxconda.js";

    private static var worker:Null<Worker> = null;
    private static var runningEngine:Null<HxcondaEngine> = null;
    private static final waiting:Array<WaitingSearch> = [];

    /** Searches within the node budget of a difficulty `level` (0 to 10), which plays the same on any hardware **/
    public function searchByLevel(notation:String, history:Array<String>, level:Int, onEvent:HxcondaEvent->Void):Void
    {
        start({kind: SearchByLevel, position: notation, history: history, level: level}, onEvent);
    }

    /** Searches within `nodeLimit` nodes, adding evaluation noise of up to `noiseAmplitude`, see `NodeBudget` **/
    public function searchByNodes(notation:String, history:Array<String>, nodeLimit:Int, noiseAmplitude:Float, onEvent:HxcondaEvent->Void):Void
    {
        start({kind: SearchByNodes, position: notation, history: history, nodeLimit: nodeLimit, noiseAmplitude: noiseAmplitude}, onEvent);
    }

    /** Searches for `durationMs` milliseconds **/
    public function searchByTime(notation:String, history:Array<String>, durationMs:Float, onEvent:HxcondaEvent->Void):Void
    {
        start({kind: SearchByTime, position: notation, history: history, durationMs: durationMs}, onEvent);
    }

    /**
        Searches `halfDepth` full moves deep or, with a `timeCapMs`, until the cap runs out.
        Without a `weakening` it plays the best move found, see `Hxconda.bestMoveByDepth`.
        Searches of the same `gameId` in a row, with the same style, share what they learn.
        `onDepthReached` gets every newly completed depth, in plies, the deepest one right before `onCompleted`.
        `onCompleted` gets the score (positive favours white) and the expected line, starting with the chosen move.
    **/
    public function searchByDepth(notation:String, history:Array<String>, gameId:String, halfDepth:Int, timeCapMs:Null<Float>, ?weakening:Weakening, ?style:HxcondaStyle, onCompleted:(score:Float, mainLine:Array<HxcondaMoveMessage>)->Void, ?onDepthReached:Int->Void, ?onFailed:String->Void):Void
    {
        var request:HxcondaRequest = {
            kind: SearchByDepth,
            position: notation,
            history: history,
            gameId: gameId,
            maxDepth: halfDepth * 2,
            style: style ?? Standard
        };
        if (timeCapMs != null)
            request.timeCapMs = timeCapMs;
        if (weakening != null)
            request.weakening = weakening;

        start(request, event -> {
            switch event
            {
                case Iteration(report):
                    if (onDepthReached != null)
                        onDepthReached(report.depth);
                case Completed(report) if (report != null && report.move != null):
                    onCompleted(report.score, mainLine(report));
                case Completed(_):
                    if (onFailed != null)
                        onFailed("The side to move has no legal moves");
                case Failed(error):
                    if (onFailed != null)
                        onFailed(error);
                case Progress(_):
            }
        });
    }

    public function stop():Void
    {
        for (i in 0...waiting.length)
            if (waiting[i].engine == this)
            {
                waiting.splice(i, 1);
                return;
            }

        if (runningEngine == this)
        {
            terminateWorker();
            runningEngine = null;
            startNextWaiting();
        }
    }

    private function start(request:HxcondaRequest, onEvent:HxcondaEvent->Void):Void
    {
        stop();

        if (runningEngine == null)
            launch(request, onEvent);
        else
            waiting.push({engine: this, request: request, onEvent: onEvent});
    }

    private function launch(request:HxcondaRequest, onEvent:HxcondaEvent->Void):Void
    {
        runningEngine = this;

        var searchWorker:Worker = worker ?? new Worker(WORKER_URL);
        searchWorker.onmessage = (message:MessageEvent) -> {
            if (searchWorker != worker)
                return; // a message queued before the worker's termination

            var event:HxcondaEvent = HxcondaProtocol.decodeResponse(message.data);
            switch event
            {
                case Completed(_):
                    finish(onEvent, event);
                case Failed(_):
                    terminateWorker();
                    finish(onEvent, event);
                default:
                    onEvent(event);
            }
        };
        searchWorker.onerror = (event:ErrorEvent) -> {
            if (searchWorker != worker)
                return;

            terminateWorker();
            finish(onEvent, Failed('The engine worker failed to run: ${event.message ?? "it could not be loaded"}'));
        };
        worker = searchWorker;
        searchWorker.postMessage(request);
    }

    private function finish(onEvent:HxcondaEvent->Void, event:HxcondaEvent):Void
    {
        runningEngine = null;
        onEvent(event);
        if (runningEngine == null)
            startNextWaiting();
    }

    private static function terminateWorker():Void
    {
        if (worker == null)
            return;

        worker.terminate();
        worker = null;
    }

    private static function startNextWaiting():Void
    {
        var next:Null<WaitingSearch> = waiting.shift();
        if (next != null)
            next.engine.launch(next.request, next.onEvent);
    }

    /** The principal line if it starts with the chosen move, which an aspiration re-search can break; the move alone otherwise **/
    private static function mainLine(report:HxcondaReportMessage):Array<HxcondaMoveMessage>
    {
        var line:Null<Array<HxcondaMoveMessage>> = report.principalLine;
        if (line != null && line.length > 0 && isSameMove(line[0], report.move))
            return line;
        else
            return [report.move];
    }

    private static function isSameMove(a:HxcondaMoveMessage, b:HxcondaMoveMessage):Bool
    {
        return a.from == b.from && a.to == b.to && a.resultingPiece == b.resultingPiece;
    }

    public function new() {}
}

private typedef WaitingSearch = {
    var engine:HxcondaEngine;
    var request:HxcondaRequest;
    var onEvent:HxcondaEvent->Void;
}
