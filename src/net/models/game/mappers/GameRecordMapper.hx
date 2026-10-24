package net.models.game.mappers;

import client.datatypes.game.GameParticipant;
import client.datatypes.game.GameRecord;
import client.datatypes.game.PlayerRating;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import net.models.common.UserRefWithNickname;
import net.models.common.mappers.TimeControlMapper;

class GameRecordMapper
{
    public static function summaryToDatatype(dto:GameSummaryPublic):GameRecord
    {
        return new GameRecord(
            dto.id,
            participantToDatatype(dto.white_player, dto.white_rating),
            participantToDatatype(dto.black_player, dto.black_rating),
            TimeControlMapper.dtoToDatatype(dto.fischer_time_control),
            dto.rated,
            dto.started_at != null ? dto.started_at.getUnixMs() : null,
            sipToPosition(dto.latest_sip),
            null,
            dto.last_ply_at != null ? dto.last_ply_at.getUnixMs() : null,
            LiveGameMapper.outcomeToDatatype(dto.outcome)
        );
    }

    public static function ongoingToDatatype(dto:OngoingGamePublic):GameRecord
    {
        return new GameRecord(
            dto.id,
            participantToDatatype(dto.white_player, dto.white_rating),
            participantToDatatype(dto.black_player, dto.black_rating),
            TimeControlMapper.dtoToDatatype(dto.fischer_time_control),
            dto.rated,
            dto.started_at != null ? dto.started_at.getUnixMs() : null,
            sipToPosition(dto.latest_sip),
            dto.ply_cnt,
            dto.last_ply_at != null ? dto.last_ply_at.getUnixMs() : null,
            null
        );
    }

    public static function applyUpdate(game:GameRecord, dto:OngoingGameUpdate):GameRecord
    {
        return game.updated(sipToPosition(dto.latest_sip), dto.ply_cnt, dto.last_ply_at != null ? dto.last_ply_at.getUnixMs() : null);
    }

    private static function participantToDatatype(player:UserRefWithNickname, rating:Null<PlayerRatingPublic>):GameParticipant
    {
        var ratingDatatype:Null<PlayerRating> = rating != null ? new PlayerRating(rating.elo, rating.provisional) : null;
        return new GameParticipant(player.user_ref, player.nickname, ratingDatatype);
    }

    private static function sipToPosition(sip:String):Position
    {
        return new Sip(sip).toPosition() ?? Position.defaultStarting();
    }
}
