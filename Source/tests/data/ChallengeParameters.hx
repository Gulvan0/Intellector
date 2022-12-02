package tests.data;

import utils.TimeControl;
import struct.ChallengeParams;

class ChallengeParameters 
{
    public static function incomingDirectBlitzCustomized()
    {
        return new ChallengeParams(TimeControl.normal(3, 2), Direct("gulvan"), Black, Situation.randomPlay(1), false);
    }

    public static function incomingDirectRapidRated()
    {
        return new ChallengeParams(TimeControl.normal(10, 0), Direct("gulvan"), null, null, true);
    }

    public static function incomingDirectCorrespondenceUnrated()
    {
        return new ChallengeParams(TimeControl.correspondence(), Direct("gulvan"), null, null, false);
    }

    public static function incomingDirectHyperbulletWhiteAcceptor()
    {
        return new ChallengeParams(TimeControl.normal(0.5, 0), Direct("gulvan"), White, null, false);
    }

    public static function outgoingDirect()
    {
        return new ChallengeParams(TimeControl.normal(1, 0), Direct("kaz"), null, null, false);
    }

    public static function outgoingPublic()
    {
        return new ChallengeParams(TimeControl.normal(1, 0), Public, null, null, false);
    }

    public static function outgoingByLink()
    {
        return new ChallengeParams(TimeControl.normal(1, 0), ByLink, null, null, false);
    }
}