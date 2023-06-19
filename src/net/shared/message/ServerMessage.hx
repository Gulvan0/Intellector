package net.shared.message;

import net.shared.dataobj.GreetingResponseData;

enum ServerMessage
{
    GreetingResponse(data:GreetingResponseData);
    Event(id:Int, event:ServerEvent);
    RequestResponse(requestID:Int, response:ServerRequestResponse);
}