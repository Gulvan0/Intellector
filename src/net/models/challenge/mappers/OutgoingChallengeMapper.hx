package net.models.challenge.mappers;

import client.datatypes.ChallengeAcceptorColor as DatatypeChallengeAcceptorColor;
import client.datatypes.OutgoingChallenge;
import intellectorboard.mappers.Sip;
import net.models.common.mappers.TimeControlKindMapper;
import net.models.common.mappers.TimeControlMapper;

class OutgoingChallengeMapper
{
    public static function dtoToDatatype(dto:ChallengePublic):OutgoingChallenge
    {
        return new OutgoingChallenge(
            dto.id,
            dto.callee?.user_ref,
            dto.callee?.nickname,
            TimeControlMapper.dtoToDatatype(dto.fischer_time_control),
            TimeControlKindMapper.dtoToDatatype(dto.time_control_kind),
            dto.rated,
            callerColorToDatatype(dto.acceptor_color),
            dto.custom_starting_sip != null ? new Sip(dto.custom_starting_sip).toPosition() : null
        );
    }

    // `acceptor_color` is the other side's; the caller plays the opposite one
    private static function callerColorToDatatype(dto:ChallengeAcceptorColor):DatatypeChallengeAcceptorColor
    {
        return switch dto {
            case WHITE: Black;
            case BLACK: White;
            case RANDOM: Random;
        }
    }
}
