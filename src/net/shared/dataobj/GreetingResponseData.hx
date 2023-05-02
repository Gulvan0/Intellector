package net.shared.dataobj;

import net.shared.dataobj.GameModelData;

enum GreetingResponseData
{
    ConnectedAsGuest(sessionID:Int, token:String, invalidCredentials:Bool, isShuttingDown:Bool);
    Logged(sessionID:Int, token:String, incomingChallenges:Array<ChallengeData>, ongoingFiniteGame:Null<GameModelData>, isShuttingDown:Bool);
    Reconnected(missedEvents:Map<Int, ServerEvent>);
    NotReconnected;
    OutdatedClient;
    OutdatedServer;
}