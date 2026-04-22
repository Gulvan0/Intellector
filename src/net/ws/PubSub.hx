package net.ws;

import lib.pubsub.Subscription;
import lib.pubsub.IChannel;
import lib.pubsub.PubSubEngine;

class PubSub
{
    private static var _engine:PubSubEngine;

    public static function start(
        ?onInitialConnectionFailed:Null<Void->Void> = null,
        ?tokenRetriever:Null<Void->Null<String>> = null,
        ?lastActivityUnixSecsRetriever:Null<Void->Null<Int>> = null
    )
    {
        _engine = new PubSubEngine(Config.getWebsocketUrl(), onInitialConnectionFailed, tokenRetriever, lastActivityUnixSecsRetriever);
        _engine.connect();
    }

    public static function isConnected():Bool
    {
        return _engine.connected;
    }

    public static function sub<T:IChannel>(channel:T):Subscription<T>
    {
        return _engine.sub(channel);
    }
}
