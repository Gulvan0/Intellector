package client.logic.challenge;

import client.datatypes.challenge.ChallengeAcceptorColor;
import client.datatypes.challenge.ChallengeDetails;
import client.datatypes.challenge.ChallengeViewer;

class ChallengeViewers
{
    /** `userRef`: the viewer's, null while unknown **/
    public static function of(challenge:ChallengeDetails, userRef:Null<String>):ChallengeViewer
    {
        if (userRef != null && userRef == challenge.callerRef)
            return Owner;
        else if (!challenge.isDirect() || userRef == challenge.calleeRef)
            return Acceptor;
        else
            return Bystander;
    }

    /** The colour `viewer` plays, or would play, once `challenge` is accepted **/
    public static function colorOf(viewer:ChallengeViewer, challenge:ChallengeDetails):ChallengeAcceptorColor
    {
        return switch viewer {
            case Owner: challenge.acceptorColor.opposite();
            case Acceptor, Bystander: challenge.acceptorColor;
        }
    }
}
