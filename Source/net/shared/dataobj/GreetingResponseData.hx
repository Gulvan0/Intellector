package net.shared.dataobj;

enum GreetingResponseData
{
    ConnectedAsGuest(token:String, invalidCredentials:Bool);
    Logged(token:String, incomingChallenges:Array<ChallengeData>, ongoingFiniteGame:Null<OngoingGameInfo>);
    Reconnected(missedEvents:Array<ServerEvent>);
    NotReconnected;
}