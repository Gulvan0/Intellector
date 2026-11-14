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
    ChatRestricted;
    SearchTimeout;
    InvalidFormula;
    /** A saved filter is gone, or a filter link doesn't hold a readable formula **/
    FilterUnavailable;
}
