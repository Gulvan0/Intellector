package client.ui.game.controllers;

import client.botengine.BotGameRunner;
import client.botengine.BotMoveRequest;
import client.botengine.BotSearchProgress;
import client.botengine.BotTimeAllocation;
import client.datatypes.game.GameClock;
import client.datatypes.game.LiveGameState;
import client.datatypes.request.FailedAction;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.game.BoardStage;
import client.ui.game.commands.ExternalGameCommands;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import morestd.Detachable;

/** In a game against a bot: has this tab search for the bot's move, shows how far it has got, and takes moves back **/
class BotTurnController
{
    private final session:LiveGameSession;
    private final stage:BoardStage;
    private final progressHandle:Detachable;

    public function new(session:LiveGameSession, stage:BoardStage)
    {
        this.session = session;
        this.stage = stage;

        progressHandle = BotGameRunner.progressChanged.subscribe(changedGameId -> {
            if (changedGameId == session.gameId)
                refreshProgress();
        });
    }

    public function dispose():Void
    {
        progressHandle.detach();
    }

    /** Starts the search for the bot's move, if the user plays this game and it's the bot's turn, and stops it otherwise **/
    public function refreshTurn():Void
    {
        var state:LiveGameState = session.state;
        var botColor:Null<PieceColor> = state.info.botColor();
        if (botColor == null || session.userColor == null)
            return;

        if (state.isOver() || state.history.latestPosition().turnColor != botColor || state.history.latestPlyEndsGame()) // the user's decisive ply is shown before the server ends the game
        {
            BotGameRunner.stop(session.gameId);
            return;
        }

        var plyCount:Int = state.history.plyCount();
        var positions:Array<Position> = [for (i in 0...plyCount + 1) state.history.positionAt(i)];
        BotGameRunner.requestMove(session.gameId, new BotMoveRequest(positions, state.info.bot, allocationSeconds(botColor)));
    }

    /** The bot's bar tells how far this tab's search for its move has got **/
    public function refreshProgress():Void
    {
        var botColor:Null<PieceColor> = session.state.info.botColor();
        var progress:Null<BotSearchProgress> = botColor != null ? BotGameRunner.progress(session.gameId) : null;
        for (color in [White, Black])
            stage.barOf(color, session.orientation).setBotProgress(color == botColor ? progress : null);
    }

    /** Back to before the user's last move, at once **/
    public function takeBack():Void
    {
        var state:LiveGameState = session.state;
        var userToMove:Bool = state.history.latestPosition().turnColor == session.userColor;
        BotGameRunner.stop(session.gameId);
        new ExternalGameCommands(session.gameId, session.userColor).rollback(state.history.plyCount() - (userToMove ? 2 : 1), error -> {
            RequestFailureNotice.showHttpError(TAKE_BACK, error);
            refreshTurn();
        });
    }

    // what the bot's clock allows for its move; null in a correspondence game
    private function allocationSeconds(botColor:PieceColor):Null<Float>
    {
        var state:LiveGameState = session.state;
        var clock:Null<GameClock> = state.clockAt(state.history.plyCount());
        return switch state.info.timeControl {
            case Fischer(instance) if (clock != null):
                BotTimeAllocation.secondsToMove(
                    clock.remainingMs(botColor, ServerTime.now()) / 1000,
                    instance.incrementSeconds,
                    state.history.plyCount() + 1,
                    state.history.latestPosition().countPieces()
                );
            default: null;
        }
    }
}
