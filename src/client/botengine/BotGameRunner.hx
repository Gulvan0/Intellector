package client.botengine;

import client.tabs.BotGameLease;
import haxe.Timer;
import intellectorboard.mappers.Sip;
import intellectorboard.primitives.ply.RawPly;

/**
    Plays the bots' moves in the games against them opened in this tab, wherever in the app the user goes meanwhile.
    Only one of the browser's tabs computes a game's move at a time, see `BotGameLease`.
**/
class BotGameRunner
{
    private static var submitPly:(gameId:Int, ply:RawPly, searchedSip:String, onSettled:Void->Void)->Void;
    private static var onSearchFailed:(gameId:Int, retry:Void->Void)->Void;
    private static final turns:Map<Int, BotTurn> = [];

    /**
        `submitPly` sends the bot's ply, made in the position `searchedSip`, then calls `onSettled` whatever the outcome.
        `onSearchFailed` tells the user the bot couldn't find a move; `retry` searches again.
    **/
    public static function init(submitPly:(gameId:Int, ply:RawPly, searchedSip:String, onSettled:Void->Void)->Void, onSearchFailed:(gameId:Int, retry:Void->Void)->Void):Void
    {
        BotGameRunner.submitPly = submitPly;
        BotGameRunner.onSearchFailed = onSearchFailed;
    }

    /** It's the bot's turn in game `gameId`: searches for its move, unless this tab is already busy with the same turn **/
    public static function requestMove(gameId:Int, request:BotMoveRequest):Void
    {
        var current:Null<BotTurn> = turns.get(gameId);
        if (current != null && current.request.plyCount() == request.plyCount() && !current.failed)
            return;

        stop(gameId);
        var turn:BotTurn = new BotTurn(gameId, request);
        turns.set(gameId, turn);
        begin(turn);
    }

    /** It isn't the bot's turn in game `gameId` any more, or the game is over: drops whatever this tab does for it **/
    public static function stop(gameId:Int):Void
    {
        var turn:Null<BotTurn> = turns.get(gameId);
        if (turn == null)
            return;

        turns.remove(gameId);
        turn.search.stop();
        stopTimers(turn);
        BotGameLease.release(gameId);
    }

    private static function begin(turn:BotTurn):Void
    {
        turn.failed = false;

        if (!BotGameLease.tryAcquire(turn.gameId))
        {
            turn.leaseRetryTimer = Timer.delay(() -> {
                if (isCurrent(turn))
                    begin(turn);
            }, BotGameLease.EXPIRY_MS);
            return;
        }

        var renewalTimer:Timer = new Timer(BotGameLease.RENEWAL_INTERVAL_MS);
        renewalTimer.run = () -> BotGameLease.renew(turn.gameId);
        turn.renewalTimer = renewalTimer;

        turn.search.start(
            turn.request.positions,
            turn.request.settings,
            turn.request.allocationSeconds,
            move -> onFound(turn, move),
            _ -> onFailed(turn)
        );
    }

    private static function onFound(turn:BotTurn, move:BotMove):Void
    {
        if (!isCurrent(turn))
            return;

        submitPly(turn.gameId, move.ply, Sip.fromPosition(turn.request.position()), () -> {
            if (isCurrent(turn))
                stop(turn.gameId);
        });
    }

    private static function onFailed(turn:BotTurn):Void
    {
        if (!isCurrent(turn))
            return;

        turn.failed = true;
        stopTimers(turn);
        BotGameLease.release(turn.gameId);
        onSearchFailed(turn.gameId, () -> {
            if (isCurrent(turn) && turn.failed)
                begin(turn);
        });
    }

    private static function isCurrent(turn:BotTurn):Bool
    {
        return turns.get(turn.gameId) == turn;
    }

    private static function stopTimers(turn:BotTurn):Void
    {
        if (turn.renewalTimer != null)
            turn.renewalTimer.stop();
        if (turn.leaseRetryTimer != null)
            turn.leaseRetryTimer.stop();
        turn.renewalTimer = null;
        turn.leaseRetryTimer = null;
    }
}

private class BotTurn
{
    public final gameId:Int;
    public final request:BotMoveRequest;
    public final search:BotMoveSearch = new BotMoveSearch();
    /** Whether the search failed and awaits a retry **/
    public var failed:Bool = false;
    public var renewalTimer:Null<Timer> = null;
    public var leaseRetryTimer:Null<Timer> = null;

    public function new(gameId:Int, request:BotMoveRequest)
    {
        this.gameId = gameId;
        this.request = request;
    }
}
