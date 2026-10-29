package engine.hxconda;

import engine.hxconda.protocol.HxcondaProtocol;
import engine.hxconda.protocol.HxcondaRequest;
import engine.hxconda.protocol.HxcondaResponse;
import engine.hxconda.search.BestMoveReport;
import js.html.DedicatedWorkerGlobalScope;
import js.html.MessageEvent;

/**
    Main class of the engine's web worker build (`hxconda.hxml`): runs the searches `HxcondaEngine` requests.
**/
class HxcondaWorker
{
    private static var scope:DedicatedWorkerGlobalScope;

    public static function main():Void
    {
        scope = cast js.Lib.global;
        scope.onmessage = onMessage;
    }

    private static function onMessage(event:MessageEvent):Void
    {
        var request:HxcondaRequest = event.data;

        try
        {
            var report:BestMoveReport = switch request.kind {
                case SearchByLevel: Hxconda.bestMoveByLevel(request.position, request.history, request.level, postProgress);
                case SearchByTime: Hxconda.bestMoveByTime(request.position, request.history, request.durationMs, postIteration);
                case SearchByNodes: Hxconda.bestMoveByNodes(request.position, request.history, request.nodeLimit, request.noiseAmplitude ?? 0.0, postProgress);
            }
            post({kind: Completed, report: HxcondaProtocol.reportMessage(report)});
        }
        catch (e:haxe.Exception)
        {
            post({kind: Failed, error: e.message});
        }
    }

    private static function postProgress(percent:Int):Void
    {
        post({kind: Progress, percent: percent});
    }

    private static function postIteration(report:BestMoveReport):Void
    {
        post({kind: Iteration, report: HxcondaProtocol.reportMessage(report)});
    }

    private static function post(response:HxcondaResponse):Void
    {
        scope.postMessage(response);
    }
}
