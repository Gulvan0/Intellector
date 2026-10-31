package net.models.challenge.mappers;

import client.datatypes.challenge.creation.ChallengeParams;
import intellectorboard.mappers.Sip;
import intellectorboard.primitives.piece.PieceColor;
import net.models.common.mappers.TimeControlMapper;
import net.models.game.external.ExternalGameCreatePayload;

class ChallengeParamsMapper
{
    public static function datatypeToDirectDto(params:ChallengeParams, calleeRef:String):ChallengeCreateDirect
    {
        return {
            rated: params.rated,
            acceptor_color: acceptorColor(params.callerColor),
            custom_starting_sip: customStartingSip(params),
            fischer_time_control: TimeControlMapper.datatypeToDto(params.timeControl),
            callee_ref: calleeRef
        };
    }

    public static function datatypeToOpenDto(params:ChallengeParams, linkOnly:Bool):ChallengeCreateOpen
    {
        return {
            rated: params.rated,
            acceptor_color: acceptorColor(params.callerColor),
            custom_starting_sip: customStartingSip(params),
            fischer_time_control: TimeControlMapper.datatypeToDto(params.timeControl),
            link_only: linkOnly
        };
    }

    /** A game of the user `ownUserRef`, playing `userColor`, against the bot `botRef` **/
    public static function datatypeToExternalGameDto(params:ChallengeParams, ownUserRef:String, userColor:PieceColor, botRef:String, botThinkCapSeconds:Null<Int>):ExternalGameCreatePayload
    {
        return {
            white_player_ref: userColor == White ? ownUserRef : botRef,
            black_player_ref: userColor == White ? botRef : ownUserRef,
            custom_starting_sip: customStartingSip(params),
            time_control: TimeControlMapper.datatypeToDto(params.timeControl),
            bot_think_cap_secs: botThinkCapSeconds
        };
    }

    // the server is told the colour of whoever accepts, the opposite of the creator's
    private static function acceptorColor(callerColor:Null<PieceColor>):ChallengeAcceptorColor
    {
        return switch callerColor {
            case White: BLACK;
            case Black: WHITE;
            case null: RANDOM;
        }
    }

    private static function customStartingSip(params:ChallengeParams):Null<String>
    {
        return params.customStartingPosition != null ? Sip.fromPosition(params.customStartingPosition) : null;
    }
}
