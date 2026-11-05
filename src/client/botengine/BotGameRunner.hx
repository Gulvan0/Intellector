package client.botengine;

import client.logic.bot.BotStrengthRules;
import client.tabs.BotGameLease;
import haxe.Timer;
import intellectorboard.mappers.Sip;
import intellectorboard.primitives.ply.RawPly;
import morestd.Signal;

/**
    Plays the bots' moves in the games against them opened in this tab, wherever in the app the user goes meanwhile.
    Only one of the browser's tabs computes a game's move at a time, see `BotGameLease`.
**/
class BotGameRunner
{
    /** How often the server is told this tab is alive while it works on a bot's turn; the server suspends a game after 90 s of silence **/
    private static inline final HEARTBEAT_INTERVAL_MS:Int = 20000;

    /** Dispatched with a game's id when the progress of its bot's search in this tab changes **/
    public static final progressChanged:Signal<Int> = new Signal();

    private static var submitPly:(gameId:Int, ply:RawPly, searchedSip:String, onSettled:Void->Void)->Void;
    private static var onSearchFailed:(gameId:Int, reason:String, retry:Void->Void)->Void;
    private static var sendHeartbeat:Int->Void;
    private static final turns:Map<Int, BotTurn> = [];

    /**
        `submitPly` sends the bot's ply, made in the position `searchedSip`, then calls `onSettled` whatever the outcome.
        `onSearchFailed` tells the user the bot couldn't find a move, for the given `reason`; `retry` searches again.
        `sendHeartbeat` tells the server this tab is alive and working on the game's bot turn.
    **/
    public static function init(
        submitPly:(gameId:Int, ply:RawPly, searchedSip:String, onSettled:Void->Void)->Void,
        onSearchFailed:(gameId:Int, reason:String, retry:Void->Void)->Void,
        sendHeartbeat:Int->Void
    ):Void
    {
        BotGameRunner.submitPly = submitPly;
        BotGameRunner.onSearchFailed = onSearchFailed;
        BotGameRunner.sendHeartbeat = sendHeartbeat;
    }

    /** How far this tab's search for game `gameId`'s bot move has got; null while this tab isn't searching **/
    public static function progress(gameId:Int):Null<BotSearchProgress>
    {
        return turns.get(gameId)?.progress;
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
        turn.heartbeatTimer = new Timer(HEARTBEAT_INTERVAL_MS);
        turn.heartbeatTimer.run = () -> sendHeartbeat(gameId);
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
        stopRetryTimer(turn);
        turn.heartbeatTimer.stop();
        releaseLease(turn);
        progressChanged.dispatch(gameId);
    }

    private static function begin(turn:BotTurn):Void
    {
        turn.failed = false;
        BotGameLease.tryAcquire(turn.gameId, release -> onLeaseAnswered(turn, release));
    }

    private static function onLeaseAnswered(turn:BotTurn, release:Null<Void->Void>):Void
    {
        if (!isCurrent(turn))
        {
            if (release != null)
                release();
            return;
        }

        if (release == null)
        {
            turn.leaseRetryTimer = Timer.delay(() -> {
                if (isCurrent(turn))
                    begin(turn);
            }, BotGameLease.RETRY_INTERVAL_MS);
            return;
        }

        turn.releaseLease = release;

        setProgress(turn, 0);
        turn.search.start(
            turn.gameId,
            turn.request.positions,
            turn.request.settings,
            turn.request.allocationSeconds,
            move -> onFound(turn, move),
            reason -> onFailed(turn, reason),
            depth -> {
                if (isCurrent(turn))
                    setProgress(turn, depth);
            }
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

    private static function onFailed(turn:BotTurn, reason:String):Void
    {
        if (!isCurrent(turn))
            return;

        turn.failed = true;
        turn.progress = null;
        progressChanged.dispatch(turn.gameId);
        stopRetryTimer(turn);
        releaseLease(turn);
        onSearchFailed(turn.gameId, reason, () -> {
            if (isCurrent(turn) && turn.failed)
                begin(turn);
        });
    }

    private static function setProgress(turn:BotTurn, depth:Int):Void
    {
        turn.progress = new BotSearchProgress(depth, BotStrengthRules.halfDepth(turn.request.settings.strength) * 2); // the engine's depth is in plies
        progressChanged.dispatch(turn.gameId);
    }

    private static function isCurrent(turn:BotTurn):Bool
    {
        return turns.get(turn.gameId) == turn;
    }

    private static function stopRetryTimer(turn:BotTurn):Void
    {
        if (turn.leaseRetryTimer != null)
            turn.leaseRetryTimer.stop();
        turn.leaseRetryTimer = null;
    }

    private static function releaseLease(turn:BotTurn):Void
    {
        if (turn.releaseLease != null)
            turn.releaseLease();
        turn.releaseLease = null;
    }
}

private class BotTurn
{
    public final gameId:Int;
    public final request:BotMoveRequest;
    public final search:BotMoveSearch = new BotMoveSearch();
    /** Whether the search failed and awaits a retry **/
    public var failed:Bool = false;
    /** Null while this tab doesn't search: waiting for the lease, or the search failed **/
    public var progress:Null<BotSearchProgress> = null;
    /** Null while this tab doesn't hold the game's lease **/
    public var releaseLease:Null<Void->Void> = null;
    public var leaseRetryTimer:Null<Timer> = null;
    /** Runs from the turn's start to its end, a failed search included: the user is here, the game isn't abandoned **/
    public var heartbeatTimer:Null<Timer> = null;

    public function new(gameId:Int, request:BotMoveRequest)
    {
        this.gameId = gameId;
        this.request = request;
    }
}
