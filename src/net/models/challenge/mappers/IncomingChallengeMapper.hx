package net.models.challenge.mappers;

import client.datatypes.ChallengeAcceptorColor as DatatypeChallengeAcceptorColor;
import client.datatypes.IncomingChallenge;
import intellectorboard.mappers.Sip;
import net.models.common.mappers.TimeControlKindMapper;
import net.models.common.mappers.TimeControlMapper;

class IncomingChallengeMapper
{
    public static function dtoToDatatype(dto:ChallengePublic):IncomingChallenge
    {
        return new IncomingChallenge(
            dto.id,
            dto.caller.user_ref,
            dto.caller.nickname,
            TimeControlMapper.dtoToDatatype(dto.fischer_time_control),
            TimeControlKindMapper.dtoToDatatype(dto.time_control_kind),
            dto.rated,
            acceptorColorToDatatype(dto.acceptor_color),
            dto.custom_starting_sip != null ? new Sip(dto.custom_starting_sip).toPosition() : null
        );
    }

    // `acceptor_color` is already the recipient's colour (the server assigns it to the acceptor as is)
    private static function acceptorColorToDatatype(dto:ChallengeAcceptorColor):DatatypeChallengeAcceptorColor
    {
        return switch dto {
            case WHITE: White;
            case BLACK: Black;
            case RANDOM: Random;
        }
    }
}
