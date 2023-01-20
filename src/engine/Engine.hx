package engine;

import net.shared.board.RawPly;
import js.lib.Promise;
import net.shared.board.Situation;

abstract class Engine 
{
    public abstract function evalutateByTime(situation:Situation, timeLimitSecs:Float, ?partialResultCallback:EvaluationResult->Void):Promise<EvaluationResult>;
    public abstract function evalutateByDepth(situation:Situation, depth:Int, ?partialResultCallback:EvaluationResult->Void):Promise<EvaluationResult>;

    public function analyzeMove(situation:Situation, depth:Int, move:RawPly, callback:MoveReport->Void)
    {
        evalutateByDepth(situation, depth).then(result -> {
            var bestMove:RawPly = result.mainLine[0];
            var optimalScore:Float = result.score;
            var optimalMainline:Array<RawPly> = result.mainLine.slice(1);

            if (bestMove.equals(move))
                callback(Best(optimalScore, optimalMainline));
            else
            {
                var nextSituation:Situation = situation.situationAfterRawPly(move);
                evalutateByDepth(nextSituation, depth).then(suboptimalResult -> {
                    callback(Suboptimal(suboptimalResult.score, suboptimalResult.mainLine, bestMove, optimalScore, optimalMainline));
                });
            }
        });
    }

    public function analyzeGame(startingSituation:Situation, moves:Array<RawPly>, depth:Int, onMoveAnalyzed:Void->Void, onResultReady:Array<MoveReport>->Void)
    {
        if (Lambda.empty(moves))
            onResultReady([]);
        else
        {
            var move:RawPly = moves.shift();
            var nextSituation:Situation = startingSituation.situationAfterRawPly(move);
            analyzeMove(startingSituation, depth, move, report -> {
                onMoveAnalyzed();
                analyzeGame(nextSituation, moves, depth, onMoveAnalyzed, a -> {
                    onResultReady([report].concat(a));
                });
            });
        }
    }
}