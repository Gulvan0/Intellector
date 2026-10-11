package net.models.challenge.mappers;

import client.datatypes.challenge.creation.ChallengeParams;
import client.datatypes.timecontrol.FischerTimeControl;
import client.datatypes.timecontrol.TimeControl;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import utest.Assert;
import utest.Test;

class ChallengeParamsMapperTest extends Test
{
    private function testAcceptorPlaysOppositeOfCaller():Void
    {
        Assert.equals(ChallengeAcceptorColor.BLACK, directDto(White).acceptor_color);
        Assert.equals(ChallengeAcceptorColor.WHITE, directDto(Black).acceptor_color);
        Assert.equals(ChallengeAcceptorColor.RANDOM, directDto(null).acceptor_color);
    }

    private function testOpenDtoCarriesColourToo():Void
    {
        var params:ChallengeParams = new ChallengeParams(Public, None, false, White, null);
        Assert.equals(ChallengeAcceptorColor.BLACK, ChallengeParamsMapper.datatypeToOpenDto(params, false).acceptor_color);
    }

    private function testDirectDtoFields():Void
    {
        var timeControl:TimeControl = Fischer(new FischerTimeControl(180, 2));
        var params:ChallengeParams = new ChallengeParams(Player("alice"), timeControl, true, null, null);

        var dto:ChallengeCreateDirect = ChallengeParamsMapper.datatypeToDirectDto(params, "alice");

        Assert.isTrue(dto.rated);
        Assert.equals("alice", dto.callee_ref);
        Assert.isNull(dto.custom_starting_sip);
        Assert.equals(180, dto.fischer_time_control.start_seconds);
        Assert.equals(2, dto.fischer_time_control.increment_seconds);
    }

    private function testOpenDtoFields():Void
    {
        var position:Position = Position.defaultStarting().copy(Black);
        var params:ChallengeParams = new ChallengeParams(LinkOnly, None, false, null, position);

        var dto:ChallengeCreateOpen = ChallengeParamsMapper.datatypeToOpenDto(params, true);

        Assert.isTrue(dto.link_only);
        Assert.isFalse(dto.rated);
        Assert.isNull(dto.fischer_time_control);
        Assert.equals(Sip.fromPosition(position), dto.custom_starting_sip);
    }

    private function directDto(callerColor:Null<PieceColor>):ChallengeCreateDirect
    {
        var params:ChallengeParams = new ChallengeParams(Guest(3), None, false, callerColor, null);
        return ChallengeParamsMapper.datatypeToDirectDto(params, "_3");
    }
}
