package client.datatypes;

enum RequestFailureReason
{
    NoConnection;
    ServerError(httpStatus:Int);
    Unexpected;
    ChallengeUnavailable;
}
