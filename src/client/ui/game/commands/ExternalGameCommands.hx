package client.ui.game.commands;

import http.HttpError;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import net.models.game.external.ExternalGameEndPayload;
import net.models.game.external.ExternalGameRollbackPayload;
import net.models.common.mappers.PieceColorMapper;
import net.models.game.mappers.LiveGameMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

/** A game the user uploads, against a bot: the server takes plies, results and takebacks from the user as given **/
class ExternalGameCommands implements LiveGameCommands
{
    private final gameId:Int;
    private final userColor:PieceColor;

    public function move(ply:RawPly, position:Position, onFailed:HttpError->Void):Void
    {
        Rest.client().execute(
            RestOperationRegistry.APPEND_PLY_TO_EXTERNAL_GAME,
            _ -> {},
            onFailed,
            null,
            null,
            LiveGameMapper.externalPlyToDto(gameId, ply, Sip.fromPosition(position))
        );
    }

    public function resign(abort:Bool, onFailed:HttpError->Void):Void
    {
        var payload:ExternalGameEndPayload = abort
            ? {game_id: gameId, outcome_kind: ABORT}
            : {game_id: gameId, outcome_kind: RESIGN, winner: PieceColorMapper.datatypeToDto(userColor.opposite())};
        Rest.client().execute(RestOperationRegistry.END_EXTERNAL_GAME, _ -> {}, onFailed, null, null, payload);
    }

    /** Takes the game back to `plyCount` plies **/
    public function rollback(plyCount:Int, onFailed:HttpError->Void):Void
    {
        Rest.client().execute(
            RestOperationRegistry.APPEND_ROLLBACK_TO_EXTERNAL_GAME,
            _ -> {},
            onFailed,
            null,
            null,
            ({game_id: gameId, new_ply_cnt: plyCount} : ExternalGameRollbackPayload)
        );
    }

    public function new(gameId:Int, userColor:PieceColor)
    {
        this.gameId = gameId;
        this.userColor = userColor;
    }
}
