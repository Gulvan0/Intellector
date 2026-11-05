package client.botengine;

import client.datatypes.bot.BotSettings;
import client.logic.bot.BotKinds;
import client.logic.bot.BotStrengthRules;
import client.logic.bot.BotThinkCapRules;
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
        Searches the last of `positions`, the game's positions oldest first. The searches of one game `gameId` share what they learn.
        `allocationSeconds`: what the bot's clock allows for this move, see `BotTimeAllocation`; null for an untimed game.
        The search stops at the bot's depth or after the lesser of the allocation and the bot's think time cap;
        with neither, after `BotThinkCapRules.MAX_SECONDS`.
        The bot weakens its move by its strength once it has played enough plies of the game, see `BotStrengthRules.weakening`.
        `onDepthReached` gets every newly completed depth, in plies.
    **/
    public function start(gameId:Int, positions:Array<Position>, settings:BotSettings, allocationSeconds:Null<Float>, onFound:BotMove->Void, onFailed:String->Void, ?onDepthReached:Int->Void):Void
    {
        var position:Position = positions[positions.length - 1];
        var history:Array<String> = [for (i in 0...positions.length - 1) AnacondaNotation.fromPosition(positions[i])];
        var capSeconds:Float = lesser(allocationSeconds, settings.thinkCapSeconds) ?? (BotThinkCapRules.MAX_SECONDS:Float);
        var ownPlyCount:Int = 0;
        for (i in 0...positions.length - 1)
            if (positions[i].turnColor == position.turnColor)
                ownPlyCount++;

        engine.searchByDepth(
            AnacondaNotation.fromPosition(position),
            history,
            Std.string(gameId),
            BotStrengthRules.halfDepth(settings.strength),
            capSeconds * 1000,
            BotStrengthRules.weakening(settings.strength, ownPlyCount),
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
