package client.ui.game.controllers;

import client.datatypes.game.GameClock;
import client.datatypes.game.LiveGameState;
import client.ui.game.BoardStage;
import client.ui.game.PlayerBar;
import haxe.Timer;
import intellectorboard.primitives.piece.PieceColor;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

/** Keeps the players' clocks running on their bars, and acts on what they show: a timeout to check, the low time warning **/
class GameClockTicker
{
    private static inline final REFRESH_MS:Int = 200;
    private static inline final LOW_TIME_MS:Float = 60 * 1000;
    private static inline final LOW_TIME_WARNING_MIN_START_SECONDS:Int = 90; // a game starting with less has no low time warning: it would sound almost at once

    private final session:LiveGameSession;
    private final stage:BoardStage;

    private var timer:Null<Timer> = null;
    private var timeoutCheckedFor:Null<GameClock> = null;
    private var lowTimeSounded:Bool = false;

    public function new(session:LiveGameSession, stage:BoardStage)
    {
        this.session = session;
        this.stage = stage;
    }

    public function start():Void
    {
        timer = new Timer(REFRESH_MS);
        timer.run = refresh;
    }

    public function stop():Void
    {
        if (timer != null)
            timer.stop();
    }

    /** A new clock came: its timeout hasn't been checked yet **/
    public function onClockChanged():Void
    {
        timeoutCheckedFor = null;
        refresh();
    }

    public function refresh():Void
    {
        var state:LiveGameState = session.state;
        var clock:Null<GameClock> = state.clockAt(state.history.shownPlyIndex());
        var nowMs:Float = ServerTime.now();

        for (color in [White, Black])
        {
            var bar:PlayerBar = stage.barOf(color, session.orientation);
            var remainingMs:Null<Float> = clock != null ? clock.remainingMs(color, nowMs) : null;
            if (color == session.userColor)
                remainingMs = firstMoveRemainingMs(nowMs) ?? remainingMs;
            bar.setClock(remainingMs, clock != null && clock.tickingSide == color);
        }

        var latestClock:Null<GameClock> = state.clockAt(state.history.plyCount());
        checkTimeout(latestClock, nowMs);
        checkLowTime(latestClock, nowMs);
    }

    // what's left of the user's first-move deadline, if it's their turn within the first two plies; shown in place of their clock
    private function firstMoveRemainingMs(nowMs:Float):Null<Float>
    {
        var state:LiveGameState = session.state;
        var deadlineStartMs:Null<Float> = state.firstMoveDeadlineStartMs();
        if (deadlineStartMs == null || !session.isPlaying() || !state.history.isShowingLatest() || state.history.latestPosition().turnColor != session.userColor)
            return null;

        return Math.max(0, deadlineStartMs + state.firstMoveDeadlineSeconds() * 1000 - nowMs);
    }

    // once a game, when the user's own running clock drops below a minute
    private function checkLowTime(clock:Null<GameClock>, nowMs:Float):Void
    {
        var userColor:Null<PieceColor> = session.userColor;
        if (lowTimeSounded || !session.isPlaying() || clock == null || clock.tickingSide != userColor)
            return;

        var startSeconds:Int = switch session.state.info.timeControl {
            case Fischer(instance): instance.startSeconds;
            case None: 0;
        }
        if (startSeconds < LOW_TIME_WARNING_MIN_START_SECONDS || clock.remainingMs(userColor, nowMs) >= LOW_TIME_MS)
            return;

        lowTimeSounded = true;
        Sounds.play(LOW_TIME);
    }

    // a running clock at 0: the server learns of it from a check, unless a move comes first
    private function checkTimeout(clock:Null<GameClock>, nowMs:Float):Void
    {
        if (clock == null || clock.tickingSide == null || session.state.isOver() || clock == timeoutCheckedFor)
            return;
        if (clock.remainingMs(clock.tickingSide, nowMs) > 0)
            return;

        timeoutCheckedFor = clock;
        Rest.client().execute(RestOperationRegistry.CHECK_TIMEOUT, _ -> {}, _ -> {}, ["game_id" => Std.string(session.gameId)]);
    }
}
