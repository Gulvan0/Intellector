package client.datatypes.challenge;

enum ChallengeStatus
{
    Pending(challenge:ChallengeDetails);
    Accepted(gameId:Int);
    /** Cancelled by its owner or the server, or declined by its callee **/
    Cancelled;
}
