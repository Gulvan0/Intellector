package net.shared.message;

import net.shared.message.ClientRequest;
import net.shared.message.ClientEvent;
import net.shared.dataobj.Greeting;

enum ClientMessage 
{
    Greet(greeting:Greeting, clientBuild:Int, minServerBuild:Int);
    HeartBeat;
    Event(id:Int, event:ClientEvent);
    Request(id:Int, request:ClientRequest);
}