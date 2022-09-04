package net.shared;

enum SignInResult
{
    Success(incomingChallenges:Array<{id:Int, serializedParams:String}>);
    Fail;
}