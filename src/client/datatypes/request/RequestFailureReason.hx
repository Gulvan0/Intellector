package client.datatypes.request;

enum RequestFailureReason
{
    NoConnection;
    ServerError(httpStatus:Int);
    Unexpected;
    ChallengeUnavailable;
    ChallengeAlreadyExists;
    TooManyActiveChallenges(maxActiveChallenges:Int);
    TooManyDirectChallenges(maxActiveChallenges:Int);
    ServerRestarting;
}
