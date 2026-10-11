package client.datatypes.challenge.creation;

enum CalleeInput
{
    Empty;
    Valid(target:ChallengeTarget);
    Invalid(errorSlug:String);
}
