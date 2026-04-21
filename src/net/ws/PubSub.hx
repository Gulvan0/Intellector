package net.ws;

import net.ws.channel.IChannel;

class PubSub
{
    private static var _engine:PubSubEngine;

    public static function start(
        url:String,
        ?onInitialConnectionFailed:Null<Void->Void> = null,
        ?tokenRetriever:Null<Void->Null<String>> = null,
        ?lastActivityUnixSecsRetriever:Null<Void->Null<Int>> = null
    )
    {
        _engine = new PubSubEngine(url, onInitialConnectionFailed, tokenRetriever, lastActivityUnixSecsRetriever);
        _engine.connect();
    }

    public static function isConnected():Bool
    {
        return _engine.connected;
    }

    public static function sub(channel:IChannel)
    {
        return _engine.sub(channel);  //TODO: Return Subscription<T>
    }
}
