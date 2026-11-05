package client.ui.game.controllers;

import client.botengine.BotGameRunner;
import client.datatypes.request.FailedAction;
import client.errors.ErrorReporter;
import client.ui.common.notifications.RequestFailureNotice;
import intellectorboard.primitives.ply.RawPly;
import net.models.game.external.ExternalGameHeartbeatPayload;
import net.models.game.mappers.LiveGameMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

/** Connects the `BotGameRunner`, running the bots' searches in any tab, to the server **/
class BotGameRequests
{
    public static function connect():Void
    {
        BotGameRunner.init(submitPly, onSearchFailed, sendHeartbeat);
    }

    private static function submitPly(gameId:Int, ply:RawPly, searchedSip:String, onSettled:Void->Void):Void
    {
        Rest.client().execute(
            RestOperationRegistry.APPEND_PLY_TO_EXTERNAL_GAME,
            _ -> onSettled(),
            error -> {
                onSettled();
                var status:Null<Int> = error.httpStatus;
                if (status == null || status >= 500) // otherwise the game has moved on without this ply
                    RequestFailureNotice.showHttpError(BOT_MOVE, error, submitPly.bind(gameId, ply, searchedSip, () -> {}));
            },
            null,
            null,
            LiveGameMapper.externalPlyToDto(gameId, ply, searchedSip)
        );
    }

    private static function sendHeartbeat(gameId:Int):Void
    {
        Rest.client().execute(RestOperationRegistry.HEARTBEAT_EXTERNAL_GAME, _ -> {}, _ -> {}, null, null, ({game_id: gameId} : ExternalGameHeartbeatPayload));
    }

    private static function onSearchFailed(gameId:Int, reason:String, retry:Void->Void):Void
    {
        ErrorReporter.report("The bot's search failed", reason);
        RequestFailureNotice.show(BOT_MOVE, Unexpected, retry);
    }
}
