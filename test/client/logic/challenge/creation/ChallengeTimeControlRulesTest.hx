package client.logic.challenge.creation;

import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.timecontrol.TimeControl;
import client.datatypes.timecontrol.TimeControlKind;
import utest.Assert;
import utest.Test;

class ChallengeTimeControlRulesTest extends Test
{
    private function testStartSecondsBounds():Void
    {
        Assert.isFalse(ChallengeTimeControlRules.isValidStartSeconds(0));
        Assert.isTrue(ChallengeTimeControlRules.isValidStartSeconds(1));
        Assert.isTrue(ChallengeTimeControlRules.isValidStartSeconds(ChallengeTimeControlRules.MAX_START_SECONDS));
        Assert.isFalse(ChallengeTimeControlRules.isValidStartSeconds(ChallengeTimeControlRules.MAX_START_SECONDS + 1));
    }

    private function testIncrementSecondsBounds():Void
    {
        Assert.isFalse(ChallengeTimeControlRules.isValidIncrementSeconds(-1));
        Assert.isTrue(ChallengeTimeControlRules.isValidIncrementSeconds(0));
        Assert.isTrue(ChallengeTimeControlRules.isValidIncrementSeconds(ChallengeTimeControlRules.MAX_INCREMENT_SECONDS));
        Assert.isFalse(ChallengeTimeControlRules.isValidIncrementSeconds(ChallengeTimeControlRules.MAX_INCREMENT_SECONDS + 1));
    }

    private function testStepMovesByMinute():Void
    {
        Assert.equals(360, ChallengeTimeControlRules.stepStartSeconds(300, 1));
        Assert.equals(240, ChallengeTimeControlRules.stepStartSeconds(300, -1));
    }

    private function testStepStaysWithinBounds():Void
    {
        Assert.equals(30, ChallengeTimeControlRules.stepStartSeconds(60, -1));
        Assert.equals(30, ChallengeTimeControlRules.stepStartSeconds(30, -1));
        Assert.equals(ChallengeTimeControlRules.MAX_START_SECONDS, ChallengeTimeControlRules.stepStartSeconds(ChallengeTimeControlRules.MAX_START_SECONDS - 10, 1));
    }

    private function testUntimedDraftIsValidWhateverItsValues():Void
    {
        var draft:ChallengeDraft = draftWith(false, 0, -5);
        Assert.isTrue(ChallengeTimeControlRules.isValid(draft));
        Assert.same(TimeControl.None, ChallengeTimeControlRules.timeControl(draft));
        Assert.equals(TimeControlKind.Correspondence, ChallengeTimeControlRules.kind(draft));
    }

    private function testTimedDraftNeedsValuesInBounds():Void
    {
        Assert.isTrue(ChallengeTimeControlRules.isValid(draftWith(true, 300, 0)));
        Assert.isFalse(ChallengeTimeControlRules.isValid(draftWith(true, 0, 0)));
        Assert.isFalse(ChallengeTimeControlRules.isValid(draftWith(true, 300, ChallengeTimeControlRules.MAX_INCREMENT_SECONDS + 1)));
    }

    private function testTimedDraftDescribesFischer():Void
    {
        var draft:ChallengeDraft = draftWith(true, 180, 2);

        switch ChallengeTimeControlRules.timeControl(draft)
        {
            case Fischer(instance):
                Assert.equals(180, instance.startSeconds);
                Assert.equals(2, instance.incrementSeconds);
            case None:
                Assert.fail("expected a Fischer time control");
        }

        Assert.equals(TimeControlKind.Blitz, ChallengeTimeControlRules.kind(draft));
    }

    private function testMatchingPreset():Void
    {
        Assert.equals(2, ChallengeTimeControlRules.matchingPreset(draftWith(true, 180, 2)));
        Assert.isNull(ChallengeTimeControlRules.matchingPreset(draftWith(true, 180, 1)));
        Assert.isNull(ChallengeTimeControlRules.matchingPreset(draftWith(false, 180, 2)));
    }

    private function draftWith(timed:Bool, startSeconds:Int, incrementSeconds:Int):ChallengeDraft
    {
        var draft:ChallengeDraft = new ChallengeDraft();
        draft.timed = timed;
        draft.startSeconds = startSeconds;
        draft.incrementSeconds = incrementSeconds;
        return draft;
    }
}
