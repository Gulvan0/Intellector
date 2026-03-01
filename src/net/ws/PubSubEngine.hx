package net.ws;

import haxe.Json;
import hx.ws.WebSocket;

class PubSubEngine
{
    private static var websocket:WebSocket = new WebSocket(Config.getWebsocketUrl(), false);

    private static var activeSubscriptions:Array<EventChannel> = [];

    public static var token:Null<String> = null;

    public static function connect()
    {
        // TODO: While open, support heartbeat
        // TODO: Upon disconnect, try to reconnect
        // TODO: Process incoming message accordingly
        websocket.open();
    }

    private static function sendEvent(eventSlug:String, body:Null<{}> = null)
    {
        var message:{} = {event: eventSlug};
        if (token != null)
            Reflect.setField(message, "token", token);
        if (body != null)
            Reflect.setField(message, "body", body);
        websocket.send(Json.stringify(message));
    }

    public static function sub(channel:EventChannel)
    {
        if (channel.match(EveryoneEventChannel))
            throw "Cannot sub to everyone channel";

        sendEvent("sub", {channel: channel.serialize()});
    }
}
