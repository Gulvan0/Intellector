package client.ui.game.commands;

import http.HttpError;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;
import net.models.game.internal.InternalGameResignPayload;
import net.models.game.mappers.LiveGameMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

/** A game played on the site: the server decides whether leaving it aborts it **/
class InternalGameCommands implements LiveGameCommands
{
    private final gameId:Int;

    public function move(ply:RawPly, position:Position, onFailed:HttpError->Void):Void
    {
        Rest.client().execute(
            RestOperationRegistry.APPEND_PLY_TO_INTERNAL_GAME,
            _ -> {},
            onFailed,
            null,
            null,
            LiveGameMapper.plyToDto(gameId, ply)
        );
    }

    public function resign(abort:Bool, onFailed:HttpError->Void):Void
    {
        Rest.client().execute(
            RestOperationRegistry.RESIGN_INTERNAL_GAME,
            _ -> {},
            onFailed,
            null,
            null,
            ({game_id: gameId} : InternalGameResignPayload)
        );
    }

    public function new(gameId:Int)
    {
        this.gameId = gameId;
    }
}
