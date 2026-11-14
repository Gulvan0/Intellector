package net.models.game.archive.mappers;

import client.datatypes.game.GameParticipant;
import client.datatypes.game.PlayerRating;
import client.datatypes.games.ArchiveGame;
import client.datatypes.games.ArchivePage;
import client.datatypes.games.SavedFilter;
import client.datatypes.games.SavedFilterSummary;
import client.datatypes.games.SortLevel;
import net.models.common.UserRefWithNickname;
import net.models.common.mappers.TimeControlKindMapper;
import net.models.common.mappers.UserRefMapper;
import net.models.game.PlayerRatingPublic;
import net.models.game.mappers.LiveGameMapper;

class ArchiveMapper
{
    public static function resultToDatatype(dto:ArchiveSearchResult):ArchivePage
    {
        return new ArchivePage(dto.games.map(rowToDatatype), dto.total);
    }

    public static function rowToDatatype(dto:ArchiveGameRow):ArchiveGame
    {
        return new ArchiveGame(
            dto.id,
            participantToDatatype(dto.white_player, dto.white_rating),
            participantToDatatype(dto.black_player, dto.black_rating),
            dto.started_at != null ? dto.started_at.getUnixMs() : null,
            dto.ended_at != null ? dto.ended_at.getUnixMs() : null,
            dto.duration_ms,
            TimeControlKindMapper.dtoToDatatype(dto.time_control_kind),
            dto.start_seconds,
            dto.increment_seconds,
            dto.rated,
            dto.custom_starting_sip,
            dto.opening_id,
            dto.ended && dto.outcome_kind != null ? LiveGameMapper.outcomeKindToDatatype(dto.outcome_kind, dto.winner) : null,
            dto.move_count,
            dto.white_time_left_ms,
            dto.black_time_left_ms
        );
    }

    public static function sortToDto(levels:Array<SortLevel>):Array<SortLevelPayload>
    {
        return levels.map(level -> ({column: level.column, descending: level.descending} : SortLevelPayload));
    }

    public static function savedFilterToDatatype(dto:SavedFilterPublic):SavedFilter
    {
        return new SavedFilter(dto.id, dto.key, dto.name, dto.author?.user_ref, dto.author != null ? UserRefMapper.displayName(dto.author) : null, dto.formula);
    }

    public static function summaryToDatatype(dto:SavedFilterSummaryPublic):SavedFilterSummary
    {
        return new SavedFilterSummary(dto.id, dto.name);
    }

    private static function participantToDatatype(player:UserRefWithNickname, rating:Null<PlayerRatingPublic>):GameParticipant
    {
        var ratingDatatype:Null<PlayerRating> = rating != null ? new PlayerRating(rating.elo, rating.provisional) : null;
        return new GameParticipant(player.user_ref, UserRefMapper.displayName(player), ratingDatatype);
    }
}
