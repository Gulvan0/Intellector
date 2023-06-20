package net.shared.dataobj;

import net.shared.message.ServerRequestResponse;
import net.shared.dataobj.GameModelData;

enum GreetingResponseData
{
    ConnectedAsGuest(sessionID:Int, token:String, invalidCredentials:Bool, isShuttingDown:Bool);
    Logged(sessionID:Int, token:String, incomingChallenges:Array<ChallengeData>, isShuttingDown:Bool);
    Reconnected(missedEvents:Map<Int, ServerEvent>, missedRequestResponses:Map<Int, ServerRequestResponse>, lastReceivedClientEventID:Int);
    NotReconnected;
    OutdatedClient;
    OutdatedServer;
}