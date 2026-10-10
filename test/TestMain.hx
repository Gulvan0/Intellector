import client.datatypes.ChallengeInboxTest;
import client.datatypes.ChallengeQueueTest;
import client.ui.common.notifications.challenges.ChallengeStackLayoutTest;
import utest.UTest;

class TestMain
{
    public static function main():Void
    {
        UTest.run([new ChallengeQueueTest(), new ChallengeInboxTest(), new ChallengeStackLayoutTest()]);
    }
}
