package client.datatypes.challenge.creation;

/** How a request to create a challenge ended, as far as the form that sent it is concerned **/
enum ChallengeCreationOutcome
{
    Created;

    /** It met an identical challenge going the other way, and a game started at once **/
    GameStarted;

    /** The player or guest it was addressed to doesn't exist **/
    CalleeNotFound;

    /** Any other failure, already reported to the user **/
    Failed;
}
