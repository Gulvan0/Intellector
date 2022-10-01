package tests.data;

import struct.Situation;
import utils.TimeControl;
import struct.ChallengeParams;

class ChallengeParameters 
{
    public static function incomingDirectBlitzCustomized()
    {
        return new ChallengeParams(TimeControl.normal(3, 2), Direct("gulvan"), "kaz", Black, Situation.randomPlay(1), false);
    }

    public static function incomingDirectRapidRated()
    {
        return new ChallengeParams(TimeControl.normal(10, 0), Direct("gulvan"), "kaz", null, null, true);
    }

    public static function incomingDirectCorrespondenceUnrated()
    {
        return new ChallengeParams(TimeControl.correspondence(), Direct("gulvan"), "kaz", null, null, false);
    }

    public static function incomingDirectHyperbulletWhiteAcceptor()
    {
        return new ChallengeParams(TimeControl.normal(0.5, 0), Direct("gulvan"), "kaz", White, null, false);
    }

    public static function outgoingDirect()
    {
        return new ChallengeParams(TimeControl.normal(1, 0), Direct("kaz"), "gulvan", null, null, false);
    }

    public static function outgoingPublic()
    {
        return new ChallengeParams(TimeControl.normal(1, 0), Public, "gulvan", null, null, false);
    }

    public static function outgoingByLink()
    {
        return new ChallengeParams(TimeControl.normal(1, 0), ByLink, "gulvan", null, null, false);
    }
}