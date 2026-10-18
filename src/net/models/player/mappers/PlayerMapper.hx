package net.models.player.mappers;

import client.datatypes.game.PlayerRating;
import client.datatypes.player.Connection;
import client.datatypes.player.Connections;
import client.datatypes.player.GameStats;
import client.datatypes.player.KindStats;
import client.datatypes.player.MainRating;
import client.datatypes.player.PlayerProfile;
import client.datatypes.player.PlayerRelation;
import client.datatypes.player.PlayerRole;
import client.datatypes.player.PlayerStatus;
import client.datatypes.player.RatingPoint;
import client.datatypes.timecontrol.TimeControlKind;
import net.models.common.mappers.TimeControlKindMapper;

class PlayerMapper
{
    public static function profileToDatatype(dto:PlayerPublic):PlayerProfile
    {
        var role:Null<PlayerRole> = dto.main_role != null ? roleToDatatype(dto.main_role) : null;
        return new PlayerProfile(dto.login, dto.nickname, dto.joined_at.getUnixMs(), role, statusToDatatype(dto.activity.status));
    }

    public static function statusToDatatype(dto:UserStatus):PlayerStatus
    {
        return switch dto {
            case PLAYING: Playing;
            case ONLINE: Online;
            case AWAY: Away;
            case OFFLINE: Offline;
        }
    }

    public static function relationToDatatype(dto:net.models.player.PlayerRelation):PlayerRelation
    {
        var youFollowSince:Null<Float> = dto.you_follow_since != null ? dto.you_follow_since.getUnixMs() : null;
        var followsYouSince:Null<Float> = dto.follows_you_since != null ? dto.follows_you_since.getUnixMs() : null;

        if (youFollowSince != null && followsYouSince != null)
            return Friends(Math.max(youFollowSince, followsYouSince));
        if (youFollowSince != null)
            return YouFollow(youFollowSince);
        if (followsYouSince != null)
            return FollowsYou;
        return Unrelated;
    }

    public static function connectionsToDatatype(dto:PlayerConnections):Connections
    {
        return new Connections(
            dto.friends.map(cardToDatatype),
            dto.following.map(cardToDatatype),
            dto.followers.map(cardToDatatype)
        );
    }

    public static function gameStatsToDatatype(dto:PlayerGameStats):GameStats
    {
        var kinds:Array<KindStats> = [];
        for (kind in TimeControlKind.createAll())
        {
            var kindDto:Null<PlayerGameStatsByTimeControl> = dto.by_time_control.get(TimeControlKindMapper.datatypeToDto(kind));
            if (kindDto == null)
                kinds.push(new KindStats(kind, 0, 0, null));
            else
            {
                var rating:Null<PlayerRating> = kindDto.elo != null ? new PlayerRating(kindDto.elo, kindDto.is_elo_provisional) : null;
                kinds.push(new KindStats(kind, kindDto.all_games_cnt, kindDto.ranked_games_cnt, rating));
            }
        }

        var mainRating:Null<MainRating> = null;
        if (dto.best_ranked != null)
        {
            var best:KindStats = kinds[TimeControlKindMapper.dtoToDatatype(dto.best_ranked).getIndex()];
            if (best.rating != null)
                mainRating = new MainRating(best.kind, best.rating);
        }

        return new GameStats(kinds, mainRating);
    }

    public static function ratingHistoryToDatatype(dtos:Array<EloHistoryEntry>):Array<RatingPoint>
    {
        return [for (dto in dtos) new RatingPoint(dto.ts.getUnixMs(), dto.elo)];
    }

    private static function cardToDatatype(dto:PlayerCard):Connection
    {
        var mainRating:Null<MainRating> = null;
        if (dto.main_rating != null)
            mainRating = new MainRating(TimeControlKindMapper.dtoToDatatype(dto.main_rating.time_control_kind), new PlayerRating(dto.main_rating.elo, dto.main_rating.provisional));
        return new Connection(dto.player.user_ref, dto.player.nickname, statusToDatatype(dto.status), mainRating);
    }

    private static function roleToDatatype(dto:UserRole):PlayerRole
    {
        return switch dto {
            case ADMIN: Admin;
            case ANACONDA_DEVELOPER: AnacondaDeveloper;
        }
    }
}
