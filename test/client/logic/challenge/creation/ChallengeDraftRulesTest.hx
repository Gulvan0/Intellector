package client.logic.challenge.creation;

import client.datatypes.challenge.creation.CallerColorChoice;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.challenge.creation.ChallengeParams;
import client.datatypes.challenge.creation.ChallengeTarget;
import client.datatypes.challenge.creation.StartingPositionMode;
import client.datatypes.timecontrol.TimeControl;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import testutils.Positions;
import intellectorboard.primitives.piece.PieceColor;
import utest.Assert;
import utest.Test;

class ChallengeDraftRulesTest extends Test
{
    private function testGuestDraftBecomesUnrated():Void
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.rated = true;

        ChallengeDraftRules.normalize(draft, false);
        Assert.isTrue(draft.rated);

        ChallengeDraftRules.normalize(draft, true);
        Assert.isFalse(draft.rated);
    }

    private function testNormalizeDropsUnusableCustomSip():Void
    {
        for (sip in ["garbage", Sip.fromPosition(Position.empty())])
        {
            var draft:ChallengeDraft = new ChallengeDraft();
            draft.customSip = sip;
            ChallengeDraftRules.normalize(draft, false);
            Assert.isNull(draft.customSip, sip);
        }
    }

    private function testNormalizeKeepsValidCustomSip():Void
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.customSip = intellectorsOnlySip();
        ChallengeDraftRules.normalize(draft, false);
        Assert.equals(intellectorsOnlySip(), draft.customSip);
    }

    private function testRatedForcesRandomColourAndKeepsChoice():Void
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.callerColor = WHITE;

        draft.rated = true;
        Assert.equals(CallerColorChoice.RANDOM, ChallengeDraftRules.effectiveCallerColor(draft));
        Assert.equals(CallerColorChoice.WHITE, draft.callerColor);

        draft.rated = false;
        Assert.equals(CallerColorChoice.WHITE, ChallengeDraftRules.effectiveCallerColor(draft));
    }

    private function testRatedForcesDefaultPosition():Void
    {
        var draft:ChallengeDraft = customPositionDraft();

        draft.rated = true;
        Assert.equals(StartingPositionMode.DEFAULT, ChallengeDraftRules.effectivePositionMode(draft));
        Assert.isNull(ChallengeDraftRules.customStartingPosition(draft));
        Assert.isTrue(ChallengeDraftRules.startingPosition(draft).isDefaultStarting());

        draft.rated = false;
        Assert.equals(StartingPositionMode.CUSTOM, ChallengeDraftRules.effectivePositionMode(draft));
        Assert.notNull(ChallengeDraftRules.customStartingPosition(draft));
    }

    private function testCustomModeWithoutUsablePositionStartsFromDefault():Void
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.positionMode = CUSTOM;
        Assert.isNull(ChallengeDraftRules.customStartingPosition(draft));

        draft.customSip = Sip.DEFAULT_STARTING_POSITION_SIP;
        Assert.isNull(ChallengeDraftRules.customStartingPosition(draft));
        Assert.isTrue(ChallengeDraftRules.startingPosition(draft).isDefaultStarting());
    }

    private function testDefaultPiecesWithBlackToMoveAreCustom():Void
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.positionMode = CUSTOM;
        draft.customSip = Sip.fromPosition(Position.defaultStarting().copy(Black));

        var position:Null<Position> = ChallengeDraftRules.customStartingPosition(draft);

        Assert.notNull(position);
        Assert.equals(PieceColor.Black, position.turnColor);
    }

    private function testTargetFollowsType():Void
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.calleeLogin = "alice";

        draft.type = DIRECT;
        Assert.same(ChallengeTarget.Player("alice"), ChallengeDraftRules.target(draft, null));

        draft.calleeKind = GUEST;
        draft.calleeGuestNumber = "5";
        Assert.same(ChallengeTarget.Guest(5), ChallengeDraftRules.target(draft, null));

        draft.type = OPEN;
        Assert.same(ChallengeTarget.Public, ChallengeDraftRules.target(draft, null));

        draft.visibility = LINK_ONLY;
        Assert.same(ChallengeTarget.LinkOnly, ChallengeDraftRules.target(draft, null));

        draft.type = BOT;
        Assert.same(ChallengeTarget.Bot, ChallengeDraftRules.target(draft, null));
    }

    private function testDirectTargetNeedsValidCallee():Void
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        Assert.isNull(ChallengeDraftRules.target(draft, null));

        draft.calleeLogin = "alice";
        Assert.isNull(ChallengeDraftRules.target(draft, "alice"));
        Assert.isNull(ChallengeDraftRules.params(draft, "alice"));
    }

    private function testParamsDescribeDraft():Void
    {
        var draft:ChallengeDraft = customPositionDraft();
        draft.calleeLogin = "alice";
        draft.startSeconds = 180;
        draft.incrementSeconds = 2;
        draft.callerColor = BLACK;

        var params:Null<ChallengeParams> = ChallengeDraftRules.params(draft, "bob");

        Assert.notNull(params);
        Assert.same(ChallengeTarget.Player("alice"), params.target);
        Assert.isFalse(params.rated);
        Assert.equals(PieceColor.Black, params.callerColor);
        Assert.equals(intellectorsOnlySip(), Sip.fromPosition(params.customStartingPosition));
        switch params.timeControl
        {
            case Fischer(instance):
                Assert.equals(180, instance.startSeconds);
                Assert.equals(2, instance.incrementSeconds);
            case None:
                Assert.fail("expected a Fischer time control");
        }
    }

    private function testRatedParamsHaveRandomColourAndDefaultPosition():Void
    {
        var draft:ChallengeDraft = customPositionDraft();
        draft.type = OPEN;
        draft.callerColor = WHITE;
        draft.rated = true;

        var params:Null<ChallengeParams> = ChallengeDraftRules.params(draft, null);

        Assert.notNull(params);
        Assert.isTrue(params.rated);
        Assert.isNull(params.callerColor);
        Assert.isNull(params.customStartingPosition);
    }

    private function testParamsNeedValidTimeControl():Void
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.type = OPEN;
        draft.startSeconds = 0;
        Assert.isNull(ChallengeDraftRules.params(draft, null));

        draft.timed = false;
        Assert.same(TimeControl.None, ChallengeDraftRules.params(draft, null).timeControl);
    }

    private function testParseSip():Void
    {
        Assert.isTrue(ChallengeDraftRules.parseSip(' ${Sip.DEFAULT_STARTING_POSITION_SIP} ').isDefaultStarting());
        Assert.isNull(ChallengeDraftRules.parseSip("garbage"));
        Assert.isNull(ChallengeDraftRules.parseSip(""));
    }

    private function customPositionDraft():ChallengeDraft
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.positionMode = CUSTOM;
        draft.customSip = intellectorsOnlySip();
        return draft;
    }

    // a valid starting position other than the default one: both Intellectors at their default hexes, nothing else
    private function intellectorsOnlySip():String
    {
        var defaultPosition:Position = Position.defaultStarting();
        var white:HexCoords = defaultPosition.intellectorCoords(White);
        var black:HexCoords = defaultPosition.intellectorCoords(Black);

        return Sip.fromPosition(Positions.make(White, [
            {i: white.i, j: white.j, kind: Intellector, color: White},
            {i: black.i, j: black.j, kind: Intellector, color: Black}
        ]));
    }
}
