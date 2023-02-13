package engine;

import dict.Phrase;
import net.shared.board.Situation;
import net.shared.board.RawPly;

abstract class Bot 
{
    public final name:String;
    private final engine:Engine;
    
    public abstract function getReactionToMove(ply:RawPly, resultingSituation:Situation):Null<Phrase>;
    public abstract function playMove(situation:Situation, botTimeData:Null<BotTimeData>, onResponse:Phrase->Void, onMoveChosen:RawPly->Void):Void;

    public function interrupt() 
    {
        engine.interrupt();
    }

    public function new(name:String, engine:Engine) 
    {
        this.name = name;
        this.engine = engine;
    }
}