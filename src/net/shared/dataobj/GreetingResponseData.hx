package net.shared.dataobj;

enum GreetingResponseData
{
    ConnectedAsGuest(sessionID:Int, token:String, invalidCredentials:Bool, isShuttingDown:Bool);
    Logged(sessionID:Int, token:String, incomingChallenges:Array<ChallengeData>, ongoingFiniteGame:Null<OngoingGameInfo>, isShuttingDown:Bool);
    Reconnected(missedEvents:Map<Int, ServerEvent>);
    NotReconnected;
    OutdatedClient;
    OutdatedServer;
}