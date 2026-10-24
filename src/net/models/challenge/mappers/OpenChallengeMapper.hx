package net.models.challenge.mappers;

import client.datatypes.challenge.OpenChallenge;
import client.datatypes.game.PlayerRating;
import intellectorboard.mappers.Sip;
import net.models.common.mappers.TimeControlKindMapper;
import net.models.common.mappers.TimeControlMapper;

class OpenChallengeMapper
{
    public static function dtoToDatatype(dto:ChallengePublic):OpenChallenge
    {
        return new OpenChallenge(
            dto.id,
            dto.caller.user_ref,
            dto.caller.nickname,
            dto.caller_rating != null ? new PlayerRating(dto.caller_rating.elo, dto.caller_rating.provisional) : null,
            TimeControlMapper.dtoToDatatype(dto.fischer_time_control),
            TimeControlKindMapper.dtoToDatatype(dto.time_control_kind),
            dto.rated,
            IncomingChallengeMapper.acceptorColorToDatatype(dto.acceptor_color),
            dto.custom_starting_sip != null ? new Sip(dto.custom_starting_sip).toPosition() : null
        );
    }
}
