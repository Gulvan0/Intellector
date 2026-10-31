package client.botengine;

import client.datatypes.bot.BotSettings;
import client.logic.bot.BotKinds;
import client.logic.bot.BotStrengthRules;
import engine.hxconda.HxcondaEngine;
import engine.hxconda.protocol.HxcondaMoveMessage;
import intellectorboard.plyapplication.PlyPerformer;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;

/**
    Finds a bot's moves, one search at a time: starting another one or calling `stop` abandons the running search.
**/
class BotMoveSearch
{
    private final engine:HxcondaEngine = new HxcondaEngine();

    /**
        Searches the last of `positions`, the game's positions oldest first.
        `allocationSeconds`: what the bot's clock allows for this move, see `BotTimeAllocation`; null for an untimed game.
        The search stops at the bot's depth or after the lesser of the allocation and the bot's think time cap.
        `onDepthReached` gets every newly completed depth, in plies.
    **/
    public function start(positions:Array<Position>, settings:BotSettings, allocationSeconds:Null<Float>, onFound:BotMove->Void, onFailed:String->Void, ?onDepthReached:Int->Void):Void
    {
        var position:Position = positions[positions.length - 1];
        var history:Array<String> = [for (i in 0...positions.length - 1) AnacondaNotation.fromPosition(positions[i])];
        var capSeconds:Null<Float> = lesser(allocationSeconds, settings.thinkCapSeconds);

        engine.searchByDepth(
            AnacondaNotation.fromPosition(position),
            history,
            BotStrengthRules.halfDepth(settings.strength),
            capSeconds != null ? capSeconds * 1000 : null,
            BotStrengthRules.weakness(settings.strength),
            BotKinds.engineStyle(settings.kind),
            (score, mainLine) -> onFound(toBotMove(score, mainLine, position)),
            onDepthReached,
            onFailed
        );
    }

    public function stop():Void
    {
        engine.stop();
    }

    private static function toBotMove(score:Float, mainLine:Array<HxcondaMoveMessage>, position:Position):BotMove
    {
        var line:Array<RawPly> = [];
        var linePosition:Position = position;
        for (move in mainLine)
        {
            var ply:RawPly = AnacondaNotation.toRawPly(move, linePosition);
            line.push(ply);
            linePosition = PlyPerformer.positionAfterRawPly(linePosition, ply);
        }
        return new BotMove(line[0], score, line);
    }

    private static function lesser(a:Null<Float>, b:Null<Float>):Null<Float>
    {
        if (a == null)
            return b;
        if (b == null)
            return a;
        return Math.min(a, b);
    }

    public function new() {}
}
