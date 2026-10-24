package client.datatypes.request;

enum RequestFailureReason
{
    NoConnection;
    ServerError(httpStatus:Int);
    Unexpected;
    ChallengeUnavailable;
    GameNotFound;
    ChallengeAlreadyExists;
    TooManyActiveChallenges(maxActiveChallenges:Int);
    TooManyDirectChallenges(maxActiveChallenges:Int);
    ServerRestarting;
}
