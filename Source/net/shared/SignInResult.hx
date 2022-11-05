package net.shared;

import net.shared.ChallengeData;

enum SignInResult
{
    Success(incomingChallenges:Array<ChallengeData>);
    ReconnectionNeeded(incomingChallenges:Array<ChallengeData>, gameInfo:OngoingGameInfo);
    Fail;
}