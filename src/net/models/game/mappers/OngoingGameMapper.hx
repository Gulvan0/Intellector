package net.models.game.mappers;

import client.datatypes.GameClock;
import client.datatypes.OngoingGame;
import client.datatypes.TimeControl;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import net.models.common.UserRefWithNickname;
import net.models.common.mappers.PieceColorMapper;
import net.models.common.mappers.TimeControlMapper;

class OngoingGameMapper
{
    /** `ownRef` is the current user's, who plays the game **/
    public static function dtoToDatatype(dto:OngoingGamePublic, ownRef:String):OngoingGame
    {
        var lastPlyAtMs:Null<Float> = dto.last_ply_at != null ? dto.last_ply_at.getUnixMs() : null;
        return create(
            dto.id,
            dto.white_player,
            dto.black_player,
            ownRef,
            TimeControlMapper.dtoToDatatype(dto.fischer_time_control),
            dto.rated,
            dto.started_at.getUnixMs(),
            dto.latest_sip,
            dto.ply_cnt,
            lastPlyAtMs,
            clockToDatatype(dto.latest_time_update)
        );
    }

    /** A game that has just started: no moves yet, full clocks, none of them running **/
    public static function startedToDatatype(dto:GameSummaryPublic, ownRef:String):OngoingGame
    {
        var timeControl:TimeControl = TimeControlMapper.dtoToDatatype(dto.fischer_time_control);
        var startedAtMs:Float = dto.started_at.getUnixMs();
        var clock:Null<GameClock> = switch timeControl {
            case None: null;
            case Fischer(instance): new GameClock(instance.startSeconds * 1000, instance.startSeconds * 1000, null, startedAtMs);
        }
        return create(dto.id, dto.white_player, dto.black_player, ownRef, timeControl, dto.rated, startedAtMs, dto.latest_sip, 0, null, clock);
    }

    public static function applyUpdate(game:OngoingGame, dto:OngoingGameUpdate):OngoingGame
    {
        var lastPlyAtMs:Null<Float> = dto.last_ply_at != null ? dto.last_ply_at.getUnixMs() : null;
        return game.updated(sipToPosition(dto.latest_sip), dto.ply_cnt, lastPlyAtMs, clockToDatatype(dto.latest_time_update));
    }

    private static function create(id:Int, whitePlayer:UserRefWithNickname, blackPlayer:UserRefWithNickname, ownRef:String, timeControl:TimeControl, rated:Bool, startedAtMs:Float, sip:String, plyCount:Int, lastPlyAtMs:Null<Float>, clock:Null<GameClock>):OngoingGame
    {
        var ownColor:PieceColor = whitePlayer.user_ref == ownRef ? White : Black;
        var opponent:UserRefWithNickname = ownColor == White ? blackPlayer : whitePlayer;
        return new OngoingGame(id, opponent.nickname, ownColor, timeControl, rated, startedAtMs, sipToPosition(sip), plyCount, lastPlyAtMs, clock);
    }

    private static function sipToPosition(sip:String):Position
    {
        return new Sip(sip).toPosition() ?? Position.defaultStarting();
    }

    private static function clockToDatatype(dto:Null<GameTimeUpdatePublic>):Null<GameClock>
    {
        if (dto == null)
            return null;

        var tickingSide:Null<PieceColor> = dto.ticking_side != null ? PieceColorMapper.dtoToDatatype(dto.ticking_side) : null;
        return new GameClock(dto.white_ms, dto.black_ms, tickingSide, dto.updated_at.getUnixMs());
    }
}
