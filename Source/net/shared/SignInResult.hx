package net.shared;

import net.shared.ChallengeData;

enum SignInResult
{
    Success(incomingChallenges:Array<ChallengeData>);
    ReconnectionNeeded(incomingChallenges:Array<ChallengeData>, gameID:Int, timeData:TimeReservesData, currentLog:String);
    Fail;
}