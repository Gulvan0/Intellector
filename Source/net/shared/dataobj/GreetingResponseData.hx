package net.shared.dataobj;

enum GreetingResponseData
{
    ConnectedAsGuest(token:String, invalidCredentials:Bool, isShuttingDown:Bool);
    Logged(token:String, incomingChallenges:Array<ChallengeData>, ongoingFiniteGame:Null<OngoingGameInfo>, isShuttingDown:Bool);
    Reconnected(missedEvents:Array<ServerEvent>);
    NotReconnected;
    OutdatedClient;
    OutdatedServer;
}