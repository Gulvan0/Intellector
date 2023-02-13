package engine.bots;

import engine.engines.Anaconda;
import js.html.Worker;
import dict.Phrase;
import net.shared.board.Situation;
import net.shared.board.RawPly;

class StandardAnaconda extends Bot
{
    private var defaultDepth:Int;

    public function getReactionToMove(ply:RawPly, resultingSituation:Situation):Null<Phrase>
    {
        return null;
    }

    public function playMove(situation:Situation, botTimeData:Null<BotTimeData>, onResponse:Phrase->Void, onMoveChosen:RawPly->Void)
    {
        var onResultReady:EvaluationResult->Void = result -> {
            onMoveChosen(result.mainLine[0]);
        };
        var onPartialResult:EvaluationResult->Void = result -> {
            if (result.depth % 3 == 0)
                onResponse(BOT_ANACONDA_PARTIAL_RESULT_ACHIEVED(result.depth));
        };

        onResponse(BOT_ANACONDA_THINKING);

        if (botTimeData != null)
            engine.evalutateByTime(situation, botTimeData.getSecsToMove(), onResultReady, onPartialResult);
        else
        {
            engine.evalutateByTime(situation, 120, onResultReady, onPartialResult);
            //engine.evalutateByDepth(situation, defaultDepth, onResultReady, onPartialResult); //Not working atm
        }
    }

    public function new(botName:String, defaultDepth:Int) 
    {
        super(botName, new Anaconda());
        this.defaultDepth = defaultDepth;
    }
}