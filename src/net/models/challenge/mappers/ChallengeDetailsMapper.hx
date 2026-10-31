package net.models.challenge.mappers;

import client.datatypes.challenge.ChallengeDetails;
import client.datatypes.challenge.ChallengeStatus;
import client.datatypes.game.PlayerRating;
import intellectorboard.mappers.Sip;
import net.models.common.mappers.TimeControlKindMapper;
import net.models.common.mappers.TimeControlMapper;

class ChallengeDetailsMapper
{
    public static function dtoToStatus(dto:ChallengePublic):ChallengeStatus
    {
        if (dto.active)
            return Pending(dtoToDatatype(dto));
        else if (dto.resulting_game != null)
            return Accepted(dto.resulting_game.id);
        else
            return Cancelled;
    }

    private static function dtoToDatatype(dto:ChallengePublic):ChallengeDetails
    {
        return new ChallengeDetails(
            dto.id,
            dto.caller.user_ref,
            dto.caller.nickname,
            dto.caller_rating != null ? new PlayerRating(dto.caller_rating.elo, dto.caller_rating.provisional) : null,
            dto.callee?.user_ref,
            dto.callee?.nickname,
            TimeControlMapper.dtoToDatatype(dto.fischer_time_control),
            TimeControlKindMapper.dtoToDatatype(dto.time_control_kind),
            dto.rated,
            IncomingChallengeMapper.acceptorColorToDatatype(dto.acceptor_color),
            dto.custom_starting_sip != null ? new Sip(dto.custom_starting_sip).toPosition() : null
        );
    }
}
