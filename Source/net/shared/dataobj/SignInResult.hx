package net.shared.dataobj;

import net.shared.dataobj.ChallengeData;

enum SignInResult
{
    Success(incomingChallenges:Array<ChallengeData>);
    ReconnectionNeeded(incomingChallenges:Array<ChallengeData>, gameInfo:OngoingGameInfo);
    Fail;
}